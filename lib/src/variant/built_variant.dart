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
  final DropBuilderFunction? dropBuilder;
  final MoveChecker? passChecker;
  final PieceMoveChecker? firstMoveChecker;
  final int epPiece;
  final int castlingPiece;
  final int royalPiece;
  final MaterialConditions<int> materialConditions;
  final Map<String, BuiltRegion> regions;
  final Map<int, List<String>> winRegions;
  final List<Action> actions;
  final Map<ActionEvent, List<Action>> actionsByEvent;
  final StateTransformFunction? stateTransformer;
  final List<MoveGenFunction> moveGenerators;
  final Map<Type, MoveProcessorFunction> moveProcessors;

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
    this.passChecker,
    this.firstMoveChecker,
    required this.epPiece,
    required this.castlingPiece,
    required this.royalPiece,
    required this.materialConditions,
    required this.regions,
    required this.winRegions,
    required this.actions,
    required this.actionsByEvent,
    this.stateTransformer,
    this.moveGenerators = const [],
    this.moveProcessors = const {},
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
    DropBuilderFunction? dropBuilder,
    MoveChecker? passChecker,
    PieceMoveChecker? firstMoveChecker,
    int? epPiece,
    int? castlingPiece,
    int? royalPiece,
    MaterialConditions<int>? materialConditions,
    Map<String, BuiltRegion>? regions,
    Map<int, List<String>>? winRegions,
    List<Action>? actions,
    Map<ActionEvent, List<Action>>? actionsByEvent,
    StateTransformFunction? stateTransformer,
    List<MoveGenFunction>? moveGenerators,
    Map<Type, MoveProcessorFunction>? moveProcessors,
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
        passChecker: passChecker ?? this.passChecker,
        firstMoveChecker: firstMoveChecker ?? this.firstMoveChecker,
        epPiece: epPiece ?? this.epPiece,
        castlingPiece: castlingPiece ?? this.castlingPiece,
        royalPiece: royalPiece ?? this.royalPiece,
        materialConditions: materialConditions ?? this.materialConditions,
        regions: regions ?? this.regions,
        winRegions: winRegions ?? this.winRegions,
        actions: actions ?? this.actions,
        actionsByEvent: actionsByEvent ?? this.actionsByEvent,
        stateTransformer: stateTransformer ?? this.stateTransformer,
        moveGenerators: moveGenerators ?? this.moveGenerators,
        moveProcessors: moveProcessors ?? this.moveProcessors,
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

    BuiltVariant bv = BuiltVariant(
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
      regions: data.regions.map((k, v) => MapEntry(k, v.build(data.boardSize))),
      winRegions: winRegions,
      actions: actions,
      actionsByEvent: actionsByEvent,
    );

    bv = bv.copyWith(
      firstMoveChecker: data.firstMoveOptions.build(bv),
      stateTransformer: data.stateTransformer?.build(bv),
      moveGenerators: data.moveGenerators.map((e) => e.build(bv)).toList(),
      moveProcessors: Map.fromEntries(
          data.moveProcessors.map((e) => MapEntry(e.type, e.build(bv)))),
      promotionBuilder: data.promotionOptions.build(bv),
    );
    // It's like this so the drop builder can depend on the promotion builder.
    bv = bv.copyWith(dropBuilder: data.handOptions.dropBuilder.build(bv));
    bv = bv.copyWith(passChecker: data.passOptions.build(bv));

    return bv;
  }

  factory BuiltVariant.standard() => BuiltVariant.fromData(Variant.standard());

  PieceType pieceType(int piece, [int? square]) {
    // TODO: make this more efficient by building some of these values in advance
    final pd = pieces[piece.type];
    if (square == null ||
        !hasRegions ||
        pd.type.regionEffects.isEmpty ||
        !boardSize.onBoard(square)) {
      return pd.type;
    }
    List<RegionEffect> effects = pd.type.changePieceRegionEffects;
    if (effects.isEmpty) {
      return pd.type;
    }
    List<String> matchedRegions = [];
    for (final region in regions.entries) {
      if (boardSize.inRegion(square, region.value)) {
        matchedRegions.add(region.key);
      }
    }
    for (RegionEffect re in effects) {
      if (matchedRegions.contains(
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
    if (regions.isEmpty || pd.type.regionEffects.isEmpty) {
      return true;
    }
    List<RegionEffect> effects = pd.type.restrictMovementRegionEffects;
    if (effects.isEmpty) {
      return true;
    }
    String? regionId = effects.first.regionForPlayer(piece.colour);
    if (regionId == null) return true;

    final region = regions[regionId];
    if (region == null) return true;
    return region.containsSquare(square);
  }

  /// Determins whether [piece] (including colour) is in one of its win
  /// regions, if it has any.
  bool inWinRegion(int piece, int square) {
    if (!pieceHasWinRegions(piece)) return false;
    for (String r in winRegions[piece]!) {
      final region = regions[r];
      if (region == null) continue;
      if (region.containsSquare(square)) {
        return true;
      }
    }
    return false;
  }

  int pieceIndex(String symbol) => pieces.indexWhere((p) => p.symbol == symbol);
  List<int> pieceIndices(List<String> symbols) =>
      symbols.map((p) => pieceIndex(p)).where((p) => p >= 0).toList();

  String pieceSymbol(int type, [int colour = Bishop.white]) =>
      pieces[type].char(colour);

  int pieceFromSymbol(String symbol) {
    String upper = symbol.toUpperCase();
    int type = pieceIndex(upper);
    int colour = symbol == upper ? Bishop.white : Bishop.black;
    return makePiece(type, colour);
  }

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

  /// Set this to 100 for the 50-move rule in standard chess.
  int? get halfMoveDraw => data.halfMoveDraw;

  /// Set this to 3 for the threefold repeition rule in standard chess.
  int? get repetitionDraw => data.repetitionDraw;

  /// If this is true, it is impossible to make a move that checks anyone.
  bool get forbidChecks => data.forbidChecks;

  /// If this is set, non-capturing moves cannot be played while capturing
  /// moves are available. Examples are Antichess and Draughts.
  ForcedCapture? get forcedCapture => data.forcedCapture;

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

  /// Whether this variant supports castling.
  bool get castling => data.castling;

  /// Whether this variant involves gating.
  bool get gating => data.gating;

  /// Whether this variant has any region definitions.
  bool get hasRegions => regions.isNotEmpty;

  /// Whether this variant has any win regions.
  bool get hasWinRegions => winRegions.isNotEmpty;

  /// [piece] should contain its colour.
  bool pieceHasWinRegions(int piece) => winRegions.containsKey(piece);

  /// Whether this variant has actions for [event].
  bool hasActionsForEvent(ActionEvent event) =>
      actionsByEvent[event]!.isNotEmpty;

  /// Whether this variant has custom move generators.
  bool get hasMoveGenerators => moveGenerators.isNotEmpty;

  Iterable<Move> generateCustomMoves({
    required BishopState state,
    required int player,
    MoveGenParams params = MoveGenParams.normal,
  }) =>
      moveGenerators
          .map((e) => e(state: state, player: player, params: params))
          .expand((e) => e);

  BishopState? makeCustomMove(MoveProcessorParams params) =>
      moveProcessors[params.move.runtimeType]?.call(params);

  /// Generates all actions for [trigger].
  Iterable<Action> actionsForTrigger(
    ActionTrigger trigger, {
    bool checkPrecondition = true,
  }) =>
      checkPrecondition
          ? actionsByEvent[trigger.event]!
              .where((e) => e.precondition?.call(trigger) ?? true)
          : actionsByEvent[trigger.event]!;

  /// Generates all effects for all actions triggered by [trigger].
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

    List<int> promoPieces = checkPromoMap
        ? [...promoMap![pieceIndex] ?? promotionPieces]
        : [...promotionPieces];

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

  /// Generates all possible moves for the [base] move,
  /// given [state] and [pieceType].
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

  /// Generate all drop moves for player [colour] in [state].
  List<Move>? generateDrops({required BishopState state, required int colour}) {
    if (dropBuilder == null) return null;
    final params = MoveParams(colour: colour, state: state, variant: this);
    return dropBuilder!(params);
  }

  /// Determines whether player [colour] can pass their turn in [state].
  bool canPass({required BishopState state, required int colour}) =>
      passChecker
          ?.call(MoveParams(colour: colour, state: state, variant: this)) ??
      false;

  bool canFirstMove({
    required BishopState state,
    required int from,
    required int colour,
    required MoveDefinition moveDefinition,
  }) =>
      firstMoveChecker?.call(
        PieceMoveParams(
          colour: colour,
          state: state,
          variant: this,
          from: from,
          moveDefinition: moveDefinition,
        ),
      ) ??
      false;

  BishopState transformState(BishopState state, [int? player]) =>
      stateTransformer?.call(state, player) ?? state;

  Map<int, int> capturedPieces(
    BishopState state, {
    String? startPos,
    int? seed,
  }) {
    final pieces = pieceMapStrToInt(
      countPiecesInFen(startPos ?? data.getStartPosition(seed: seed)),
      fullPiece: true,
    );
    final currentPieces = state.pieces.asMap();
    for (final p in currentPieces.entries) {
      if (p.value == 0) continue;
      pieces[p.key] = pieces[p.key]! - p.value;
    }
    pieces.removeWhere((k, v) => v < 1);
    return pieces;
  }

  Map<String, int> capturedPiecesStr(
    BishopState state, {
    String? startPos,
    int? seed,
  }) =>
      pieceMapIntToStr(
        capturedPieces(state, startPos: startPos, seed: seed),
        fullPiece: true,
      );

  Map<int, T> pieceMapStrToInt<T>(
    Map<String, T> input, {
    bool fullPiece = false,
  }) =>
      input.map(
        (k, v) => MapEntry<int, T>(
          fullPiece ? pieceFromSymbol(k) : pieceIndex(k.toUpperCase()),
          v,
        ),
      );

  Map<String, T> pieceMapIntToStr<T>(
    Map<int, T> input, {
    bool fullPiece = false,
  }) =>
      input.map(
        (k, v) => MapEntry<String, T>(
          fullPiece ? pieceSymbol(k.type, k.colour) : pieces[k].symbol,
          v,
        ),
      );

  @override
  String toString() => name;
}
