part of 'variant.dart';

class BuiltVariant {
  final Variant data;

  final List<PieceDefinition> pieces;
  final Map<String, PieceDefinition> pieceLookup;
  final Map<String, int> pieceIndexLookup;
  final List<int> promotionPieces;
  final List<int> promotablePieces;
  final int epPiece;
  final int castlingPiece;
  final int royalPiece;
  final MaterialConditions<int> materialConditions;
  final Map<int, List<String>> winRegions;
  final List<Action> actions;
  final Map<ActionEvent, List<Action>> actionsByEvent;

  const BuiltVariant({
    required this.data,
    required this.pieces,
    required this.pieceLookup,
    required this.pieceIndexLookup,
    required this.promotionPieces,
    required this.promotablePieces,
    required this.epPiece,
    required this.castlingPiece,
    required this.royalPiece,
    required this.materialConditions,
    required this.winRegions,
    required this.actions,
    required this.actionsByEvent,
  });

  factory BuiltVariant.fromData(Variant data) {
    data = data.normalise();

    Map<int, List<String>> winRegions = {};
    List<PieceDefinition> pieces = [PieceDefinition.empty()];
    Map<String, PieceDefinition> pieceLookup = {};
    Map<String, int> pieceIndexLookup = {};
    List<Action> actions = [...data.actions];
    data.pieceTypes.forEach((s, p) {
      int value = p.royal ? Bishop.mateUpper : p.value;
      if (data.pieceValues?.containsKey(s) ?? false) {
        value = data.pieceValues![s]!;
      }
      PieceDefinition piece = PieceDefinition(type: p, symbol: s, value: value);
      pieces.add(piece);
      pieceLookup[s] = piece;
      int pieceId = pieces.length - 1;
      pieceIndexLookup[s] = pieceId;
      if (p.winRegionEffects.isNotEmpty) {
        List<String> whiteWinRegions = p.winRegionEffects
            .where((e) => e.whiteRegion != null)
            .map((e) => e.whiteRegion!)
            .toList();
        List<String> blackWinRegions = p.winRegionEffects
            .where((e) => e.blackRegion != null)
            .map((e) => e.blackRegion!)
            .toList();
        if (whiteWinRegions.isNotEmpty) {
          winRegions[makePiece(pieceId, Bishop.white)] = whiteWinRegions;
        }
        if (blackWinRegions.isNotEmpty) {
          winRegions[makePiece(pieceId, Bishop.black)] = blackWinRegions;
        }
      }
      actions.addAll(p.actions.map((e) => e.forPieceType(pieceId)));
    });

    Map<ActionEvent, List<Action>> actionsByEvent = {
      for (final e in ActionEvent.values)
        e: actions.where((a) => a.event == e).toList(),
    };

    return BuiltVariant(
      data: data,
      pieces: pieces,
      pieceLookup: pieceLookup,
      pieceIndexLookup: pieceIndexLookup,
      promotionPieces: pieces
          .asMap()
          .entries
          .where((e) => e.value.type.canPromoteTo)
          .map((e) => e.key)
          .toList(),
      promotablePieces: pieces
          .asMap()
          .entries
          .where((e) => e.value.type.promotable)
          .map((e) => e.key)
          .toList(),
      epPiece: data.enPassant
          ? pieces.indexWhere((p) => p.type.enPassantable)
          : Bishop.invalid,
      castlingPiece: data.castling
          ? pieces.indexWhere((p) => p.symbol == data.castlingOptions.rookPiece)
          : Bishop.invalid,
      royalPiece: pieces.indexWhere((p) => p.type.royal),
      materialConditions: data.materialConditions.convert(pieces),
      winRegions: winRegions,
      actions: actions,
      actionsByEvent: actionsByEvent,
    );
  }

  PieceType pieceType(int piece, int square) {
    // TODO: make this more efficient by building some of these values in advance
    final pd = pieces[piece.type];
    if (data.regions.isEmpty || pd.type.regionEffects.isEmpty) {
      return pd.type;
    }
    List<RegionEffect> effects = pd.type.changePieceRegionEffects;
    if (effects.isEmpty) {
      return pd.type;
    }
    List<String> regions = [];
    for (final region in data.regions.entries) {
      if (boardSize.inRegion(square, region.value)) {
        regions.add(region.key);
      }
    }
    for (RegionEffect re in effects) {
      if (regions.contains(
        piece.colour == Bishop.white ? re.whiteRegion : re.blackRegion,
      )) {
        return re.pieceType!;
      }
    }
    return pd.type;
  }

  /// For use with restricted movement regions - determines whether it is
  /// allowed for [piece] to move to [square].
  bool allowMovement(int piece, int square) {
    final pd = pieces[piece.type];
    if (data.regions.isEmpty || pd.type.regionEffects.isEmpty) {
      return true;
    }
    List<RegionEffect> effects = pd.type.restrictMovementRegionEffects;
    if (effects.isEmpty) {
      return true;
    }
    String? regionId = effects.first.regionForPlayer(piece.colour);
    if (regionId == null) return true;

    BoardRegion? region = data.regions[regionId];
    if (region == null) return true;
    return boardSize.inRegion(square, region);
  }

  /// Determins whether [piece] (including colour) is in one of its win
  /// regions, if it has any.
  bool inWinRegion(int piece, int square) {
    if (!pieceHasWinRegions(piece)) return false;
    for (String r in winRegions[piece]!) {
      BoardRegion? region = data.regions[r];
      if (region == null) continue;
      if (boardSize.inRegion(square, region)) {
        return true;
      }
    }
    return false;
  }

  int pieceIndex(String symbol) => pieces.indexWhere((p) => p.symbol == symbol);
  List<int> pieceIndices(List<String> symbols) =>
      symbols.map((p) => pieceIndex(p)).where((p) => p >= 0).toList();

  /// A human-friendly name.
  String get name => data.name;

  /// The size of the board.
  BoardSize get boardSize => data.boardSize;

  /// The pieces to be used in this variant, in the form symbol: pieceType.
  /// Symbols are single uppercase letters, such as 'P' (pawn) or 'N' (knight).
  Map<String, PieceType> get pieceTypes => data.pieceTypes;

  /// The castling rules for this VariantData.
  CastlingOptions get castlingOptions => data.castlingOptions;

  GameEndConditions get gameEndConditions => data.gameEndConditions;
  OutputOptions get outputOptions => data.outputOptions;

  /// A full starting position, specified as a
  /// [FEN string](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).
  String? get startPosition => data.startPosition;

  /// A builder function for variants with variable start positions, such as Chess 960.
  FenBuilder? get startPosBuilder => data.startPosBuilder;

  /// Is promotion enabled?
  bool get promotion => data.promotion;

  /// The first ranks for [WHITE, BLACK] that pieces can be promoted on.
  /// If the rank specified is not the final rank the piece can reach, then promotion
  /// will be optional on every rank up until the final rank, when it becomes mandatory.
  List<int> get promotionRanks => data.promotionRanks;

  /// Is en passant allowed in this variant?
  bool get enPassant => data.enPassant;

  /// The ranks for [WHITE, BLACK] that a piece with a 'first-only' move can make that
  /// move from. For example, a pawn's double move.
  List<List<int>> get firstMoveRanks => data.firstMoveRanks;

  /// Set this to 100 for the 50-move rule in standard chess.
  int? get halfMoveDraw => data.halfMoveDraw;

  /// Set this to 3 for the threefold repeition rule in standard chess.
  int? get repetitionDraw => data.repetitionDraw;

  /// Are hands enabled in this variant? For example, Crazyhouse.
  bool get handsEnabled => data.handOptions.enableHands;

  bool get addCapturesToHand => data.handOptions.addCapturesToHand;

  /// What type of gating, if any, is used in this variant?
  GatingMode get gatingMode => data.gatingMode;

  /// The relative values of pieces. These are usually already set in the [PieceType]
  /// definitions, so only use this if you want to override those.
  /// For example, you have a variant where a pawn is worth 200 instead of 100,
  /// but you still want to use the normal pawn definition.
  Map<String, int>? get pieceValues => data.pieceValues;

  bool get castling => data.castling;
  bool get gating => data.gating;
  bool get hasRegions => data.regions.isNotEmpty;
  bool get hasWinRegions => winRegions.isNotEmpty;

  /// [piece] should contain its colour.
  bool pieceHasWinRegions(int piece) => winRegions.containsKey(piece);

  bool hasActionsForEvent(ActionEvent event) =>
      actionsByEvent[event]!.isNotEmpty;

  Iterable<Action> actionsForTrigger(
    ActionTrigger trigger, {
    bool checkPrecondition = true,
  }) =>
      checkPrecondition
          ? actionsByEvent[trigger.event]!
              .where((e) => e.precondition?.call(trigger) ?? true)
          : actionsByEvent[trigger.event]!;

  List<ActionEffect> executeActions(ActionTrigger trigger) {
    List<ActionEffect> effects = [];
    for (Action action in actionsByEvent[trigger.event]!) {
      if (action.condition?.call(trigger) ?? true) {
        effects.addAll(action.action(trigger));
      }
    }
    return effects;
  }

  @override
  String toString() => name;
}
