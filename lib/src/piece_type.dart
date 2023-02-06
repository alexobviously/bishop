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
      );

  PieceType normalise(BoardSize size) => copyWith(
        moves: moves.map((e) => e.normalise(size)).toList(),
        regionEffects: regionEffects.map((e) => e.normalise(size)).toList(),
      );

  /// Returns a copy of the piece type with `PiecePromoOptions.none`.
  PieceType withNoPromotion() => copyWith(promoOptions: PiecePromoOptions.none);

  /// Returns a copy of the piece type with [value].
  PieceType withValue(int value) => copyWith(value: value);

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
  factory PieceType.staticKing() => PieceType.fromBetza(
        '',
        royal: true,
        promoOptions: PiecePromoOptions.none,
      );
  factory PieceType.pawn() => PieceType.fromBetza(
        'fmWfceFifmnD',
        promoOptions: PiecePromoOptions.promotable,
        enPassantable: true,
        noSanSymbol: true,
        value: 100,
      ); // seriously

  /// A pawn with no double move and no en passant.
  factory PieceType.simplePawn() => PieceType.fromBetza(
        'fmWfcF',
        promoOptions: PiecePromoOptions.promotable,
        noSanSymbol: true,
        value: 100,
      );
  factory PieceType.knibis() => PieceType.fromBetza('mNcB', value: 400);
  factory PieceType.biskni() => PieceType.fromBetza('mBcN');
  factory PieceType.kniroo() => PieceType.fromBetza('mNcR', value: 400);
  factory PieceType.rookni() => PieceType.fromBetza('mRcN');
  factory PieceType.bisroo() => PieceType.fromBetza('mBcR');
  factory PieceType.roobis() => PieceType.fromBetza('mRcB');
  factory PieceType.archbishop() => PieceType.fromBetza('BN', value: 900);
  factory PieceType.chancellor() => PieceType.fromBetza('RN', value: 900);
  factory PieceType.amazon() => PieceType.fromBetza('QN', value: 1200);
  factory PieceType.grasshopper() => PieceType.fromBetza('gQ');
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

  String char(Colour colour) =>
      colour == Bishop.white ? symbol.toUpperCase() : symbol.toLowerCase();
}
