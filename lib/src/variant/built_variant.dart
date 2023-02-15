part of 'variant.dart';

class BuiltVariant {
  final Variant data;

  final List<PieceDefinition> pieces;
  final Map<String, PieceDefinition> pieceLookup;
  final Map<String, int> pieceIndexLookup;
  final List<int> promotionPieces;
  final List<int> promotablePieces;
  final Map<int, int>? promoLimits;
  final Map<int, List<int>>? promoMap;
  final PromotionBuilder? promotionBuilder;
  final MoveBuilderFunction? dropBuilder;
  final List<MoveBuilderFunction> customMoveBuilders;
  final MoveChecker? passChecker;
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
    this.promoLimits,
    this.promoMap,
    this.promotionBuilder,
    this.dropBuilder,
    this.customMoveBuilders = const [],
    this.passChecker,
    required this.epPiece,
    required this.castlingPiece,
    required this.royalPiece,
    required this.materialConditions,
    required this.winRegions,
    required this.actions,
    required this.actionsByEvent,
  });

  BuiltVariant copyWith({
    Variant? data,
    List<PieceDefinition>? pieces,
    Map<String, PieceDefinition>? pieceLookup,
    Map<String, int>? pieceIndexLookup,
    List<int>? promotionPieces,
    List<int>? promotablePieces,
    Map<int, int>? promoLimits,
    Map<int, List<int>>? promoMap,
    PromotionBuilder? promotionBuilder,
    MoveBuilderFunction? dropBuilder,
    List<MoveBuilderFunction>? customMoveBuilders,
    MoveChecker? passChecker,
    int? epPiece,
    int? castlingPiece,
    int? royalPiece,
    MaterialConditions<int>? materialConditions,
    Map<int, List<String>>? winRegions,
    List<Action>? actions,
    Map<ActionEvent, List<Action>>? actionsByEvent,
  }) =>
      BuiltVariant(
        data: data ?? this.data,
        pieces: pieces ?? this.pieces,
        pieceLookup: pieceLookup ?? this.pieceLookup,
        pieceIndexLookup: pieceIndexLookup ?? this.pieceIndexLookup,
        promotionPieces: promotionPieces ?? this.promotionPieces,
        promotablePieces: promotablePieces ?? this.promotablePieces,
        promoLimits: promoLimits ?? this.promoLimits,
        promoMap: promoMap ?? this.promoMap,
        promotionBuilder: promotionBuilder ?? this.promotionBuilder,
        dropBuilder: dropBuilder ?? this.dropBuilder,
        customMoveBuilders: customMoveBuilders ?? this.customMoveBuilders,
        passChecker: passChecker ?? this.passChecker,
        epPiece: epPiece ?? this.epPiece,
        castlingPiece: castlingPiece ?? this.castlingPiece,
        royalPiece: royalPiece ?? this.royalPiece,
        materialConditions: materialConditions ?? this.materialConditions,
        winRegions: winRegions ?? this.winRegions,
        actions: actions ?? this.actions,
        actionsByEvent: actionsByEvent ?? this.actionsByEvent,
      );

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

    Map<int, List<int>>? promoMap = {};
    for (final p in pieces.asMap().entries) {
      final promotesTo = p.value.type.promoOptions.promotesTo;
      if (promotesTo == null) continue;
      promoMap[p.key] = promotesTo.map((e) => pieceIndexLookup[e]!).toList();
    }
    if (promoMap.isEmpty) promoMap = null;

    final bv = BuiltVariant(
      data: data,
      pieces: pieces,
      pieceLookup: pieceLookup,
      pieceIndexLookup: pieceIndexLookup,
      promotionPieces: pieces
          .asMap()
          .entries
          .where((e) => e.value.type.promoOptions.canPromoteTo)
          .map((e) => e.key)
          .toList(),
      promotablePieces: pieces
          .asMap()
          .entries
          .where((e) => e.value.type.promoOptions.canPromote)
          .map((e) => e.key)
          .toList(),
      promoLimits: data.promotionOptions.pieceLimits
          ?.map((k, v) => MapEntry(pieceIndexLookup[k]!, v)),
      promoMap: promoMap,
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

    return bv
        .copyWith(promotionBuilder: data.promotionOptions.build(bv))
        .copyWith(dropBuilder: data.handOptions.dropBuilder.build(bv))
        .copyWith(
          customMoveBuilders:
              data.customMoveBuilders.map((e) => e.build(bv)).toList(),
        )
        .copyWith(passChecker: data.passOptions.build(bv));
  }

  PieceType pieceType(int piece, [int? square]) {
    // TODO: make this more efficient by building some of these values in advance
    final pd = pieces[piece.type];
    if (square == null ||
        data.regions.isEmpty ||
        pd.type.regionEffects.isEmpty ||
        !boardSize.onBoard(square)) {
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

  /// The first piece type in the piece map that's promotable.
  int get defaultPromotablePiece => promotablePieces.first;

  /// The castling rules for this VariantData.
  CastlingOptions get castlingOptions => data.castlingOptions;

  GameEndConditionSet get gameEndConditions => data.gameEndConditions;
  OutputOptions get outputOptions => data.outputOptions;

  /// A full starting position, specified as a
  /// [FEN string](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).
  String? get startPosition => data.startPosition;

  /// A builder function for variants with variable start positions, such as Chess 960.
  StartPositionBuilder? get startPosBuilder => data.startPosBuilder;

  /// Is promotion enabled?
  bool get promotion => promotionBuilder != null;

  /// Is en passant allowed in this variant?
  bool get enPassant => data.enPassant;

  /// The ranks for [WHITE, BLACK] that a piece with a 'first-only' move can make that
  /// move from. For example, a pawn's double move.
  List<List<int>> get firstMoveRanks => data.firstMoveRanks;

  /// Set this to 100 for the 50-move rule in standard chess.
  int? get halfMoveDraw => data.halfMoveDraw;

  /// Set this to 3 for the threefold repeition rule in standard chess.
  int? get repetitionDraw => data.repetitionDraw;

  /// If this is true, it is impossible to make a move that checks anyone.
  bool get forbidChecks => data.forbidChecks;

  /// Are hands enabled in this variant? For example, Crazyhouse.
  bool get handsEnabled => data.handOptions.enableHands;

  bool get addCapturesToHand => data.handOptions.addCapturesToHand;

  /// What type of gating, if any, is used in this variant?
  GatingMode get gatingMode => data.gatingMode;

  /// Whether this variant has pass moves.
  bool get hasPass => passChecker != null;

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

  List<int> getPromoPieces({
    BishopState? state,
    PieceType? pieceType,
    int? pieceIndex,
  }) {
    bool checkPromoMap =
        promoMap != null && pieceType != null && pieceIndex != null;
    bool checkLimits = promoLimits != null && state != null;
    if (!checkPromoMap && !checkLimits) return promotionPieces;

    List<int> promoPieces =
        checkPromoMap ? [...promoMap![pieceIndex]!] : [...promotionPieces];

    if (checkLimits) {
      for (int p in promoLimits!.keys) {
        if (promoPieces.contains(p)) {
          int remaining =
              promoLimits![p]! - state.pieces[makePiece(p, state.turn)];
          if (remaining < 1) {
            promoPieces.remove(p);
          }
        }
      }
    }

    return promoPieces;
  }

  List<StandardMove>? generatePromotionMoves({
    required StandardMove base,
    required BishopState state,
    PieceType? pieceType,
  }) {
    if (promotionBuilder == null) return null;
    int piece = state.board[base.from].type;
    pieceType ??= this.pieceType(piece, base.from);
    if (!pieceType.promoOptions.canPromote) return null;
    final params = PromotionParams(
      move: base,
      state: state,
      variant: this,
      pieceType: pieceType,
      promoPieces: getPromoPieces(
        state: state,
        pieceType: pieceType,
        pieceIndex: piece,
      ),
    );
    List<StandardMove>? moves = promotionBuilder!(params);
    return moves;
  }

  List<Move>? generateDrops({
    required BishopState state,
    required int colour,
    required MoveGenParams params,
  }) {
    if (dropBuilder == null) return null;
    final p = MoveParams(
      colour: colour,
      state: state,
      variant: this,
      genParams: params,
    );
    return dropBuilder!(p);
  }

  bool get hasCustomMoves => customMoveBuilders.isNotEmpty;

  List<Move>? generateCustomMoves({
    required BishopState state,
    required int colour,
    required MoveGenParams params,
  }) {
    if (customMoveBuilders.isEmpty) return null;
    final p = MoveParams(
      colour: colour,
      state: state,
      variant: this,
      genParams: params,
    );
    return customMoveBuilders.map((e) => e(p)).expand((e) => e).toList();
  }

  bool canPass({
    required BishopState state,
    required int colour,
    required MoveGenParams params,
  }) =>
      passChecker?.call(
        MoveParams(
          colour: colour,
          state: state,
          variant: this,
          genParams: params,
        ),
      ) ??
      false;

  @override
  String toString() => name;
}
