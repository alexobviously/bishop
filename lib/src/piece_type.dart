import 'package:bishop/bishop.dart';

/// Specifies a piece type, with all of its moves and attributes.
class PieceType {
  /// A Betza notation string that defines the piece.
  /// See: https://www.gnu.org/software/xboard/Betza.html
  final String? betza;

  /// All of the different move groups this piece can make.
  final List<MoveDefinition> moves;

  /// Royal pieces can be checkmated, and can castle.
  final bool royal;

  /// Defines the promotion behaviour of this piece type.
  final PiecePromoOptions promoOptions;

  /// Whether this piece can set the en passant flag.
  final bool enPassantable;

  /// If true, the piece symbol will be omitted in SAN representations of moves.
  /// For example, pawn moves should be like 'b4', rather than 'Pb4'.
  final bool noSanSymbol;

  /// The value of the piece, in centipawns (a pawn is 100).
  /// Can be overridden in a `Variant`.
  final int value;

  /// Regions in which the behaviour of the piece is altered.
  final List<RegionEffect> regionEffects;

  final List<Action> actions;

  /// Contains precomputed flags that help move generation run faster.
  /// You don't need to set this yourself, it is generated during `normalise()`.
  final PieceOptimisationData? optimisationData;

  /// Region effects that change the piece type.
  List<RegionEffect> get changePieceRegionEffects =>
      regionEffects.where((e) => e.pieceType != null).toList();

  /// Region effects that restrict movement.
  List<RegionEffect> get restrictMovementRegionEffects =>
      regionEffects.where((e) => e.restrictMovement).toList();

  /// Region effects that win the game.
  List<RegionEffect> get winRegionEffects =>
      regionEffects.where((e) => e.winGame).toList();

  const PieceType({
    this.betza,
    required this.moves,
    this.royal = false,
    this.promoOptions = PiecePromoOptions.promoPiece,
    this.enPassantable = false,
    this.noSanSymbol = false,
    this.value = Bishop.defaultPieceValue,
    this.regionEffects = const [],
    this.actions = const [],
    this.optimisationData,
  });

  factory PieceType.fromJson(
    Map<String, dynamic> json, {
    List<BishopTypeAdapter> adapters = const [],
  }) {
    if (json.containsKey('betza')) {
      return PieceType.fromBetza(
        json['betza'],
        royal: json['royal'] ?? false,
        promoOptions: json.containsKey('promoOptions')
            ? PiecePromoOptions.fromJson(json['promoOptions'])
            : PiecePromoOptions.promoPiece,
        enPassantable: json['enPassantable'] ?? false,
        noSanSymbol: json['noSanSymbol'] ?? false,
        value: json['value'] ?? Bishop.defaultPieceValue,
        regionEffects: (json['regionEffects'] as List<dynamic>?)
                ?.map((e) => RegionEffect.fromJson(e))
                .toList() ??
            [],
        actions: json.containsKey('actions')
            ? BishopSerialisation.buildMany<Action>(
                json['actions'],
                adapters: adapters,
              )
            : const [],
      );
    }
    throw UnimplementedError('Non-betza pieces in json are not supported yet');
  }

  Map<String, dynamic> toJson({
    bool verbose = false,
    List<BishopTypeAdapter> adapters = const [],
  }) {
    // todo: support non-betza import/export
    return {
      'betza': betza,
      if (verbose || royal) 'royal': royal,
      if (verbose || promoOptions != PiecePromoOptions.promoPiece)
        'promoOptions': promoOptions.toJson(),
      if (verbose || enPassantable) 'enPassantable': enPassantable,
      if (verbose || noSanSymbol) 'noSanSymbol': true,
      if (verbose || value != Bishop.defaultPieceValue) 'value': value,
      if (verbose || regionEffects.isNotEmpty)
        'regionEffects':
            regionEffects.map((e) => e.toJson(verbose: verbose)).toList(),
      if (verbose || actions.isNotEmpty)
        'actions': BishopSerialisation.exportMany<Action>(
          actions,
          strict: false,
          adapters: adapters,
        ),
    };
  }

  /// Returns a copy of this piece type with some properties changed.
  PieceType copyWith({
    String? betza,
    List<MoveDefinition>? moves,
    bool? royal,
    PiecePromoOptions? promoOptions,
    bool? enPassantable,
    bool? noSanSymbol,
    int? value,
    List<RegionEffect>? regionEffects,
    List<Action>? actions,
    PieceOptimisationData? optimisationData,
  }) =>
      PieceType(
        betza: betza ?? this.betza,
        moves: moves ?? this.moves,
        royal: royal ?? this.royal,
        promoOptions: promoOptions ?? this.promoOptions,
        enPassantable: enPassantable ?? this.enPassantable,
        noSanSymbol: noSanSymbol ?? this.noSanSymbol,
        value: value ?? this.value,
        regionEffects: regionEffects ?? this.regionEffects,
        actions: actions ?? this.actions,
        optimisationData: optimisationData ?? this.optimisationData,
      );

  PieceType normalise(BoardSize size) => copyWith(
        moves: moves.map((e) => e.normalise(size)).toList(),
        regionEffects: regionEffects.map((e) => e.normalise(size)).toList(),
        optimisationData: _optimisationData,
      );

  PieceOptimisationData? get _optimisationData {
    if (moves.firstWhereOrNull((e) => e is! StandardMoveDefinition) != null) {
      return null;
    }
    final sMoves =
        moves.map<StandardMoveDefinition>((e) => e as StandardMoveDefinition);
    return PieceOptimisationData(
      hasOrthogonal: sMoves.hasOrthogonal,
      hasDiagonal: sMoves.hasDiagonal,
      hasOblique: sMoves.hasOblique,
    );
  }

  /// Returns a copy of the piece type with `PiecePromoOptions.none`.
  PieceType withNoPromotion() => copyWith(promoOptions: PiecePromoOptions.none);

  /// Returns a copy of the piece type with `PiecePromoOptions.promotable`.
  PieceType promotable() =>
      copyWith(promoOptions: PiecePromoOptions.promotable);

  /// Returns a copy of the piece type with [value].
  PieceType withValue(int value) => copyWith(value: value);

  /// Returns a copy of the piece type with [effect] added.
  PieceType withRegionEffect(RegionEffect effect) =>
      copyWith(regionEffects: [...regionEffects, effect]);

  /// Returns a copy of the piece type with [action] added.
  /// If [first] is true, it will be added to the start of the list.
  PieceType withAction(Action action, {bool first = false}) =>
      copyWith(actions: first ? [action, ...actions] : [...actions, action]);

  /// Returns a copy of the piece type with immortality.
  PieceType withImmortality() => withAction(ActionImmortality());

  factory PieceType.empty() => PieceType(
        moves: [],
        promoOptions: PiecePromoOptions.none,
      );

  /// Generate a piece type with all of its moves from [Betza notation](https://www.gnu.org/software/xboard/Betza.html).
  factory PieceType.fromBetza(
    String betza, {
    bool royal = false,
    PiecePromoOptions promoOptions = PiecePromoOptions.promoPiece,
    bool enPassantable = false,
    bool noSanSymbol = false,
    int value = Bishop.defaultPieceValue,
    List<RegionEffect> regionEffects = const [],
    List<Action> actions = const [],
  }) {
    List<Atom> atoms = Betza.parse(betza);
    List<MoveDefinition> moves =
        atoms.map((e) => e.moveDefinitions).expand((e) => e).toList();

    return PieceType(
      betza: betza,
      moves: moves,
      royal: royal,
      promoOptions: promoOptions,
      enPassantable: enPassantable,
      noSanSymbol: noSanSymbol,
      value: value,
      regionEffects: regionEffects,
      actions: actions,
    );
  }

  factory PieceType.knight() => PieceType.fromBetza('N', value: 300);
  factory PieceType.bishop() => PieceType.fromBetza('B', value: 300);
  factory PieceType.rook() => PieceType.fromBetza('R', value: 500);
  factory PieceType.queen() => PieceType.fromBetza('Q', value: 900);
  factory PieceType.king() => PieceType.fromBetza(
        'K',
        royal: true,
        promoOptions: PiecePromoOptions.none,
      );

  /// A king that cannot move.
  factory PieceType.staticKing() => PieceType.fromBetza(
        '',
        royal: true,
        promoOptions: PiecePromoOptions.none,
      );

  factory PieceType.pawn() => PieceType.fromBetza(
        'fmW' // moves forward one square
        'fceF' // captures diagonally forward one square
        'ifmnD', // on the first move, moves forward two squares
        promoOptions: PiecePromoOptions.promotable,
        enPassantable: true,
        noSanSymbol: true,
        value: 100,
      );

  /// An 'inverted' pawn that moves diagonally and captures fowards.
  factory PieceType.berolinaPawn() => PieceType.fromBetza(
        'fmFfceWifmnA',
        promoOptions: PiecePromoOptions.promotable,
        enPassantable: true,
        noSanSymbol: true,
        value: 125, // idk exactly but seems better than a normal pawn
      );

  // It works but you get a first move forward one square too,
  // which isn't ever picked as long as the firstmove part is specified
  // before the normal move part in the betza string. (todo: fix)
  factory PieceType.longMovePawn(int moveLength) => PieceType.fromBetza(
        'fmWfceFifmW$moveLength',
        promoOptions: PiecePromoOptions.promotable,
        enPassantable: true,
        noSanSymbol: true,
        value: 100,
      );

  /// A pawn with no double move and no en passant.
  factory PieceType.simplePawn() => PieceType.fromBetza(
        'fmWfcF',
        promoOptions: PiecePromoOptions.promotable,
        noSanSymbol: true,
        value: 100,
      );

  // Values are pretty approximate and based on wikipedia/things Betza says.

  /// Moves like a knight, captures like a bishop.
  factory PieceType.knibis() => PieceType.fromBetza('mNcB', value: 400);

  /// Moves like a bishop, captures like a knight.
  factory PieceType.biskni() => PieceType.fromBetza('mBcN');

  /// Moves like a knight, captures like a rook.
  factory PieceType.kniroo() => PieceType.fromBetza('mNcR', value: 400);

  /// Moves like a rook, captures like a knight.
  factory PieceType.rookni() => PieceType.fromBetza('mRcN');

  /// Moves like a bishop, captures like a rook.
  factory PieceType.bisroo() => PieceType.fromBetza('mBcR');

  /// Moves like a rook, captures like a bishop.
  factory PieceType.roobis() => PieceType.fromBetza('mRcB');

  /// Moves and captures like a bishop or a knight.
  factory PieceType.archbishop() => PieceType.fromBetza('BN', value: 900);

  /// Moves and captures like a rook or a knight.
  factory PieceType.chancellor() => PieceType.fromBetza('RN', value: 900);

  /// Moves and captures like a queen or a knight.
  factory PieceType.amazon() => PieceType.fromBetza('QN', value: 1200);

  /// Moves and captures like a queen, but *must* jump over exactly one piece,
  /// and land on the square directly after it.
  factory PieceType.grasshopper() => PieceType.fromBetza('gQ', value: 180);

  /// Moves one square orthogonally in any direction.
  factory PieceType.wazir() => PieceType.fromBetza('W', value: 120);

  /// Moves one square diagonally in any direction.
  factory PieceType.ferz() => PieceType.fromBetza('F', value: 140);

  /// Jumps two squares diagonally in any direction.
  factory PieceType.alfil() => PieceType.fromBetza('A', value: 120);

  /// Jumps two squares orthogonally in any direction.
  factory PieceType.dabbaba() => PieceType.fromBetza('D', value: 130);

  /// Jumps 3 squares in one direction, 1 in the other. Like a long knight.
  factory PieceType.camel() => PieceType.fromBetza('C', value: 200);

  /// Jumps 3 squares in one direction, 2 in the other.
  factory PieceType.zebra() => PieceType.fromBetza('Z', value: 180);

  /// Jumps 4 squares in one direction, 1 in the other.
  factory PieceType.giraffe() => PieceType.fromBetza('(4,1)', value: 180);

  /// A piece that does nothing but blocks. Can optionally be [immortal].
  factory PieceType.blocker({bool immortal = true}) => PieceType.fromBetza(
        '',
        value: 0,
        actions: immortal ? [ActionImmortality()] : [],
        promoOptions: PiecePromoOptions.none,
      );

  /// Can move to any empty square on the board.
  factory PieceType.duck() =>
      PieceType.fromBetza('m*').withNoPromotion().withImmortality();
}

/// A definition of a `PieceType`, specific to a `Variant`.
/// You don't ever need to build these, they are generated in variant initialisation.
class PieceDefinition {
  final PieceType type;
  final String symbol;
  final int value;

  @override
  String toString() => 'PieceDefinition($symbol)';

  const PieceDefinition({
    required this.type,
    required this.symbol,
    required this.value,
  });

  factory PieceDefinition.empty() =>
      PieceDefinition(type: PieceType.empty(), symbol: '.', value: 0);

  /// The symbol of this piece definition, respecting its [colour].
  String char(Colour colour) =>
      colour == Bishop.white ? symbol.toUpperCase() : symbol.toLowerCase();
}

/// Contains precomputed flags that help move generation run faster.
class PieceOptimisationData {
  final bool hasOrthogonal;
  final bool hasDiagonal;
  final bool hasOblique;

  const PieceOptimisationData({
    required this.hasOrthogonal,
    required this.hasDiagonal,
    required this.hasOblique,
  });

  /// Determines whether this piece should be excluded from move generation.
  bool excludePiece(int from, int to, BoardSize size) {
    final dirType = size.directionTypeBetween(from, to);
    switch (dirType) {
      case DirectionType.orthogonal:
        if (!hasOrthogonal) return true;
        break;
      case DirectionType.diagonal:
        if (!hasDiagonal) return true;
        break;
      case DirectionType.oblique:
        if (!hasOblique) return true;
        break;
    }
    return false;
  }

  @override
  String toString() =>
      'PieceOptimisationData($hasOrthogonal, $hasDiagonal, $hasOblique)';
}
