import 'dart:math';

import 'package:bishop/bishop.dart';

part 'board_size.dart';
part 'built_variant.dart';
part 'options/castling_options.dart';
part 'options/game_end_conditions.dart';
part 'options/hand_options.dart';
part 'options/output_options.dart';
part 'options/pass_options.dart';
part 'options/promotion_options.dart';
part 'options/material_conditions.dart';
part 'variants/asymmetric.dart';
part 'variants/common.dart';
part 'variants/large.dart';
part 'variants/misc.dart';
part 'variants/musketeer.dart';
part 'variants/shogi.dart';
part 'variants/small.dart';
part 'variants/xiangqi.dart';

/// Specifies the rules and pieces to be used, size of the board,
/// information on how FENs are outputted, and so on and so on.
class Variant {
  /// A human-friendly name.
  final String name;

  /// An optional description of the variant.
  final String description;

  /// The size of the board.
  final BoardSize boardSize;

  /// The pieces to be used in this variant, in the form symbol: pieceType.
  /// Symbols are single uppercase letters, such as 'P' (pawn) or 'N' (knight).
  final Map<String, PieceType> pieceTypes;

  /// The castling rules for this VariantData.
  final CastlingOptions castlingOptions;

  /// Defines the promotion behaviour in the game.
  final PromotionOptions promotionOptions;

  /// Material conditions that define how insufficient material draws should be decided.
  final MaterialConditions<String> materialConditions;

  final GameEndConditionSet gameEndConditions;

  final OutputOptions outputOptions;

  /// If the variant has a fixed starting position, specify it here as a full [FEN string](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).
  final String? startPosition;

  /// If this variant can start in a number of different positions, such as Chess960,
  /// provide a function that does this. See [VariantData.chess960()] for an example.
  final StartPositionBuilder? startPosBuilder;

  /// Is en passant allowed in this variant?
  final bool enPassant;

  /// The ranks for [WHITE, BLACK] that a piece with a 'first-only' move can make that
  /// move from. For example, a pawn's double move.
  final List<List<int>> firstMoveRanks;

  /// Set this to 100 for the 50-move rule in standard chess.
  final int? halfMoveDraw;

  /// Set this to 3 for the threefold repeition rule in standard chess.
  final int? repetitionDraw;

  /// If this is true, it is impossible to make a move that checks anyone.
  final bool forbidChecks;

  /// Are hands enabled in this variant? For example, Crazyhouse.
  final HandOptions handOptions;

  /// What type of gating, if any, is used in this variant?
  final GatingMode gatingMode;

  final PassOptions passOptions;

  /// The relative values of pieces. These are usually already set in the [PieceType]
  /// definitions, so only use this if you want to override those.
  /// For example, you have a variant where a pawn is worth 200 instead of 100,
  /// but you still want to use the normal pawn definition.
  final Map<String, int>? pieceValues;

  /// A map of region definitions for the board, for use with `RegionEffects`
  /// in piece definitions. The keys used here are used to reference the regions
  /// in effects.
  final Map<String, BoardRegion> regions;

  final List<Action> actions;

  final List<BishopTypeAdapter> adapters;

  /// Whether this variant involves castling.
  bool get castling => castlingOptions.enabled;

  /// Whether this variant involves gating.
  bool get gating => gatingMode > GatingMode.none;

  /// All piece symbols in use by this variant.
  List<String> get pieceSymbols => pieceTypes.keys.toList();

  /// All piece symbols, except for royal pieces (i.e. kings).
  List<String> get commonPieceSymbols => pieceTypes.entries
      .where((e) => !e.value.royal)
      .map((e) => e.key)
      .toList();

  @override
  String toString() => name;

  const Variant({
    required this.name,
    this.description = '',
    this.boardSize = BoardSize.standard,
    required this.pieceTypes,
    this.castlingOptions = CastlingOptions.standard,
    this.promotionOptions = PromotionOptions.standard,
    this.materialConditions = MaterialConditions.none,
    this.gameEndConditions = GameEndConditionSet.standard,
    this.outputOptions = OutputOptions.standard,
    this.startPosition,
    this.startPosBuilder,
    this.enPassant = false,
    this.firstMoveRanks = const [[], []],
    this.halfMoveDraw,
    this.repetitionDraw,
    this.forbidChecks = false,
    this.handOptions = HandOptions.disabled,
    this.gatingMode = GatingMode.none,
    this.pieceValues,
    this.passOptions = PassOptions.none,
    this.regions = const {},
    this.actions = const [],
    this.adapters = const [],
  }) : assert(
          startPosition != null || startPosBuilder != null,
          'Variant needs either a startPosition or startPosBuilder',
        );

  factory Variant.fromJson(
    Map<String, dynamic> json, {
    List<BishopTypeAdapter> adapters = const [],
  }) {
    return Variant(
      name: json['name'],
      description: json['description'],
      boardSize: BoardSize.fromString(json['boardSize']),
      pieceTypes: json['pieceTypes'].map<String, PieceType>(
        (k, v) =>
            MapEntry(k as String, PieceType.fromJson(v, adapters: adapters)),
      ),
      castlingOptions: CastlingOptions.fromJson(json['castlingOptions']),
      promotionOptions: (json.containsKey('promotionOptions')
              ? BishopSerialisation.build<PromotionOptions>(
                  json['promotionOptions'],
                  adapters: adapters,
                )
              : null) ??
          PromotionOptions.standard,
      materialConditions: json.containsKey('materialConditions')
          ? MaterialConditions.fromJson(json['materialConditions'])
          : MaterialConditions.none,
      gameEndConditions: json.containsKey('gameEndConditions')
          ? GameEndConditionSet.fromJson(json['gameEndConditions'])
          : GameEndConditionSet.standard,
      outputOptions: json.containsKey('outputOptions')
          ? OutputOptions.fromJson(json['outputOptions'])
          : OutputOptions.standard,
      startPosition: json['startPosition'],
      startPosBuilder: json.containsKey('startPosBuilder')
          ? BishopSerialisation.build<StartPositionBuilder>(
              json['startPosBuilder'],
              adapters: adapters,
            )
          : null,
      enPassant: json['enPassant'],
      firstMoveRanks: (json['firstMoveRanks'] as List<dynamic>?)
              ?.map((e) => (e as List<dynamic>).map((e) => e as int).toList())
              .toList() ??
          const [[], []],
      halfMoveDraw: json['halfMoveDraw'],
      repetitionDraw: json['repetitionDraw'],
      forbidChecks: json['forbidChecks'] ?? false,
      handOptions: json.containsKey('handOptions')
          ? HandOptions.fromJson(json['handOptions'])
          : HandOptions.disabled,
      gatingMode: GatingMode.values
          .firstWhere((e) => e.name == (json['gatingMode'] ?? 'none')),
      pieceValues: (json['pieceValues'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as int),
      ),
      passOptions: (json.containsKey('passOptions')
              ? BishopSerialisation.build<PassOptions>(
                  json['passOptions'],
                  adapters: adapters,
                )
              : null) ??
          PassOptions.none,
      regions: (json['regions'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, BoardRegion.fromJson(v))) ??
          const {},
      actions: json.containsKey('actions')
          ? BishopSerialisation.buildMany<Action>(
              json['actions'],
              adapters: adapters,
            )
          : const [],
      adapters: adapters,
    );
  }

  Map<String, dynamic> toJson({
    bool verbose = false,
    List<BishopTypeAdapter> adapters = const [],
  }) {
    final allAdapters = [...adapters, ...this.adapters];
    return {
      'name': name,
      'description': description,
      'bishopVersion': Bishop.version,
      'boardSize': boardSize.simpleString,
      'pieceTypes': pieceTypes.map(
        (k, v) => MapEntry(
          k,
          v.toJson(verbose: verbose, adapters: allAdapters),
        ),
      ),
      'castlingOptions': castlingOptions.toJson(),
      'promotionOptions': BishopSerialisation.export<PromotionOptions>(
        promotionOptions,
        adapters: allAdapters,
      ),
      'materialConditions': materialConditions.toJson(),
      if (verbose || gameEndConditions != GameEndConditionSet.standard)
        'gameEndConditions': gameEndConditions.toJson(),
      if (verbose || outputOptions != OutputOptions.standard)
        'outputOptions': outputOptions.toJson(),
      'startPosition': startPosition,
      if (startPosBuilder != null)
        'startPosBuilder': BishopSerialisation.export<StartPositionBuilder>(
          startPosBuilder!,
          adapters: allAdapters,
        ),
      'enPassant': enPassant,
      if (verbose || firstMoveRanks.expand((e) => e).isNotEmpty)
        'firstMoveRanks': firstMoveRanks,
      if (halfMoveDraw != null) 'halfMoveDraw': halfMoveDraw,
      if (repetitionDraw != null) 'repetitionDraw': repetitionDraw,
      if (verbose || forbidChecks) 'forbidChecks': forbidChecks,
      if (verbose || handOptions.enableHands)
        'handOptions': handOptions.toJson(
          verbose: verbose,
          adapters: allAdapters,
        ),
      if (verbose || gatingMode != GatingMode.none)
        'gatingMode': gatingMode.name,
      if (pieceValues != null) 'pieceValues': pieceValues,
      if (verbose || passOptions is! NoPass)
        'passOptions': BishopSerialisation.export<PassOptions>(
          passOptions,
          adapters: allAdapters,
        ),
      if (verbose || regions.isNotEmpty)
        'regions': regions.map((k, v) => MapEntry(k, v.toJson())),
      if (verbose || actions.isNotEmpty)
        'actions': BishopSerialisation.exportMany<Action>(
          actions,
          strict: false,
          adapters: allAdapters,
        ),
    };
  }

  Variant copyWith({
    String? name,
    String? description,
    BoardSize? boardSize,
    Map<String, PieceType>? pieceTypes,
    CastlingOptions? castlingOptions,
    PromotionOptions? promotionOptions,
    MaterialConditions<String>? materialConditions,
    GameEndConditionSet? gameEndConditions,
    OutputOptions? outputOptions,
    String? startPosition,
    StartPositionBuilder? startPosBuilder,
    bool? enPassant,
    List<List<int>>? firstMoveRanks,
    int? halfMoveDraw,
    int? repetitionDraw,
    bool? forbidChecks,
    HandOptions? handOptions,
    GatingMode? gatingMode,
    PassOptions? passOptions,
    Map<String, int>? pieceValues,
    Map<String, BoardRegion>? regions,
    List<Action>? actions,
    List<BishopTypeAdapter>? adapters,
  }) {
    return Variant(
      name: name ?? this.name,
      description: description ?? this.description,
      boardSize: boardSize ?? this.boardSize,
      pieceTypes: pieceTypes ?? this.pieceTypes,
      castlingOptions: castlingOptions ?? this.castlingOptions,
      promotionOptions: promotionOptions ?? this.promotionOptions,
      materialConditions: materialConditions ?? this.materialConditions,
      gameEndConditions: gameEndConditions ?? this.gameEndConditions,
      outputOptions: outputOptions ?? this.outputOptions,
      startPosition: startPosition ?? this.startPosition,
      startPosBuilder: startPosBuilder ?? this.startPosBuilder,
      enPassant: enPassant ?? this.enPassant,
      firstMoveRanks: firstMoveRanks ?? this.firstMoveRanks,
      halfMoveDraw: halfMoveDraw ?? this.halfMoveDraw,
      repetitionDraw: repetitionDraw ?? this.repetitionDraw,
      forbidChecks: forbidChecks ?? this.forbidChecks,
      handOptions: handOptions ?? this.handOptions,
      gatingMode: gatingMode ?? this.gatingMode,
      passOptions: passOptions ?? this.passOptions,
      pieceValues: pieceValues ?? this.pieceValues,
      regions: regions ?? this.regions,
      actions: actions ?? this.actions,
      adapters: adapters ?? this.adapters,
    );
  }

  Variant normalise() => copyWith(
        pieceTypes:
            pieceTypes.map((k, v) => MapEntry(k, v.normalise(boardSize))),
      );

  /// Copies the variant with [pieceTypes], including piece types already in
  /// the variant and overwriting them if necessary.
  Variant withPieces(Map<String, PieceType> pieceTypes) =>
      copyWith(pieceTypes: {...this.pieceTypes, ...pieceTypes});

  /// Copies the variant with [pieces] removed.
  Variant withPiecesRemoved(List<String> pieces) => copyWith(
        pieceTypes: {...pieceTypes}..removeWhere((k, _) => pieces.contains(k)),
      );

  /// Copies the variant with the 'campmate' end condition:
  /// When a royal piece enters the opposite rank, that player wins the game.
  /// Setting [whiteRank] or [blackRank] to a negative number will count in
  /// reverse from the top of the board.
  Variant withCampMate({
    String whiteRegionName = 'whiteCamp',
    String blackRegionName = 'blackCamp',
    int? whiteRank,
    int? blackRank,
  }) {
    if (whiteRank != null && whiteRank < 0) {
      whiteRank = boardSize.maxRank + 1 + whiteRank;
    }
    if (blackRank != null && blackRank < 0) {
      blackRank = boardSize.maxRank + 1 + blackRank;
    }
    final effect =
        RegionEffect.winGame(white: blackRegionName, black: whiteRegionName);
    final pieces = pieceTypes.map(
      (k, v) => MapEntry(
        k,
        v.royal ? v.copyWith(regionEffects: [...v.regionEffects, effect]) : v,
      ),
    );
    return copyWith(
      pieceTypes: pieces,
      regions: {
        ...regions,
        whiteRegionName: BoardRegion.rank(whiteRank ?? Bishop.rank1),
        if (whiteRegionName != blackRegionName)
          blackRegionName: BoardRegion.rank(blackRank ?? boardSize.maxRank),
      },
    );
  }

  factory Variant.standard() {
    return Variant(
      name: 'Chess',
      boardSize: BoardSize.standard,
      startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      castlingOptions: CastlingOptions.standard,
      materialConditions: MaterialConditions.standard,
      outputOptions: OutputOptions.standard,
      promotionOptions: PromotionOptions.standard,
      enPassant: true,
      halfMoveDraw: 100,
      repetitionDraw: 3,
      firstMoveRanks: [
        [Bishop.rank2], // white
        [Bishop.rank7], // black
      ],
      pieceTypes: {
        'P': PieceType.pawn(),
        'N': PieceType.knight(),
        'B': PieceType.bishop(),
        'R': PieceType.rook(),
        'Q': PieceType.queen(),
        'K': PieceType.king(),
      },
    );
  }

  // These constructors may eventually be removed -
  // prefer using the things they redirect to.
  factory Variant.chess960() => CommonVariants.chess960();
  factory Variant.crazyhouse() => CommonVariants.crazyhouse();
  factory Variant.seirawan() => CommonVariants.seirawan();
  factory Variant.threeCheck() => CommonVariants.threeCheck();
  factory Variant.kingOfTheHill() => CommonVariants.kingOfTheHill();
  factory Variant.atomic({bool allowExplosionDraw = false}) =>
      CommonVariants.atomic(allowExplosionDraw: allowExplosionDraw);
  factory Variant.horde() => CommonVariants.horde();
  factory Variant.capablanca() => LargeVariants.capablanca();
  factory Variant.grand() => LargeVariants.grand();
  factory Variant.mini() => SmallVariants.mini();
  factory Variant.miniRandom() => SmallVariants.miniRandom();
  factory Variant.micro() => SmallVariants.micro();
  factory Variant.nano() => SmallVariants.nano();
}
