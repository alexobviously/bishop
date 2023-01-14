import 'dart:math';

import 'package:bishop/bishop.dart';

part 'board_size.dart';
part 'built_variant.dart';
part 'castling_options.dart';
part 'chess_960.dart';
part 'game_end_conditions.dart';
part 'hand_options.dart';
part 'output_options.dart';
part 'promotion_options.dart';
part 'material_conditions.dart';
part 'musketeer.dart';
part 'xiangqi.dart';

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

  final GameEndConditions gameEndConditions;

  final OutputOptions outputOptions;

  /// If the variant has a fixed starting position, specify it here as a full [FEN string](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).
  final String? startPosition;

  /// If this variant can start in a number of different positions, such as Chess960,
  /// provide a function that does this. See [VariantData.chess960()] for an example.
  final FenBuilder? startPosBuilder;

  /// Is en passant allowed in this variant?
  final bool enPassant;

  /// The ranks for [WHITE, BLACK] that a piece with a 'first-only' move can make that
  /// move from. For example, a pawn's double move.
  final List<List<int>> firstMoveRanks;

  /// Set this to 100 for the 50-move rule in standard chess.
  final int? halfMoveDraw;

  /// Set this to 3 for the threefold repeition rule in standard chess.
  final int? repetitionDraw;

  /// Are hands enabled in this variant? For example, Crazyhouse.
  final HandOptions handOptions;

  /// What type of gating, if any, is used in this variant?
  final GatingMode gatingMode;

  /// The relative values of pieces. These are usually already set in the [PieceType]
  /// definitions, so only use this if you want to override those.
  /// For example, you have a variant where a pawn is worth 200 instead of 100,
  /// but you still want to use the normal pawn definition.
  final Map<String, int>? pieceValues;

  /// The flying generals rule from Xiangqi, i.e. royal pieces (kings/generals)
  /// are not allowed to face each other if this is true.
  /// CURRENTLY NOT WORKING.
  final bool flyingGenerals;

  /// A map of region definitions for the board, for use with `RegionEffects`
  /// in piece definitions. The keys used here are used to reference the regions
  /// in effects.
  final Map<String, BoardRegion> regions;

  final List<Action> actions;

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
    this.gameEndConditions = GameEndConditions.standard,
    this.outputOptions = OutputOptions.standard,
    this.startPosition,
    this.startPosBuilder,
    this.enPassant = false,
    this.firstMoveRanks = const [[], []],
    this.halfMoveDraw,
    this.repetitionDraw,
    this.handOptions = HandOptions.disabled,
    this.gatingMode = GatingMode.none,
    this.pieceValues,
    this.flyingGenerals = false,
    this.regions = const {},
    this.actions = const [],
  }) : assert(
          startPosition != null || startPosBuilder != null,
          'Variant needs either a startPosition or startPosBuilder',
        );

  Variant copyWith({
    String? name,
    String? description,
    BoardSize? boardSize,
    Map<String, PieceType>? pieceTypes,
    CastlingOptions? castlingOptions,
    PromotionOptions? promotionOptions,
    MaterialConditions<String>? materialConditions,
    GameEndConditions? gameEndConditions,
    OutputOptions? outputOptions,
    String? startPosition,
    FenBuilder? startPosBuilder,
    bool? enPassant,
    List<List<int>>? firstMoveRanks,
    int? halfMoveDraw,
    int? repetitionDraw,
    HandOptions? handOptions,
    GatingMode? gatingMode,
    Map<String, int>? pieceValues,
    bool? flyingGenerals,
    Map<String, BoardRegion>? regions,
    List<Action>? actions,
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
      handOptions: handOptions ?? this.handOptions,
      gatingMode: gatingMode ?? this.gatingMode,
      pieceValues: pieceValues ?? this.pieceValues,
      flyingGenerals: flyingGenerals ?? this.flyingGenerals,
      regions: regions ?? this.regions,
      actions: actions ?? this.actions,
    );
  }

  Variant normalise() => copyWith(
        pieceTypes:
            pieceTypes.map((k, v) => MapEntry(k, v.normalise(boardSize))),
      );

  factory Variant.standard() {
    return Variant(
      name: 'Chess',
      boardSize: BoardSize.standard,
      startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      castlingOptions: CastlingOptions.standard,
      materialConditions: MaterialConditions.standard,
      outputOptions: OutputOptions.standard,
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

  factory Variant.chess960() {
    return Variant.standard().copyWith(
      name: 'Chess960',
      startPosBuilder: build960Position,
      castlingOptions: CastlingOptions.chess960,
      outputOptions: OutputOptions.chess960,
    );
  }

  factory Variant.crazyhouse() {
    return Variant.standard().copyWith(
      name: 'Crazyhouse',
      handOptions: HandOptions.captures,
    );
  }

  factory Variant.capablanca() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Capablanca Chess',
      boardSize: BoardSize(10, 8),
      startPosition:
          'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1',
      castlingOptions: CastlingOptions.capablanca,
      pieceTypes: {
        ...standard.pieceTypes,
        'A': PieceType.archbishop(),
        'C': PieceType.chancellor(),
      },
    );
  }

  factory Variant.grand() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Grand Chess',
      boardSize: BoardSize(10, 10),
      startPosition:
          'r8r/1nbqkcabn1/pppppppppp/10/10/10/10/PPPPPPPPPP/1NBQKCABN1/R8R w - - 0 1',
      castlingOptions: CastlingOptions.none,
      promotionOptions: PromotionOptions.optional(
        ranks: [Bishop.rank8, Bishop.rank3],
        pieceLimits: {
          'Q': 1, 'A': 1, 'C': 1, //
          'R': 2, 'N': 2, 'B': 2, //
        },
      ),
      firstMoveRanks: [
        [Bishop.rank3],
        [Bishop.rank8],
      ],
      pieceTypes: {
        ...standard.pieceTypes,
        'C': PieceType.chancellor(), // marshal
        'A': PieceType.archbishop(), // cardinal
      },
    );
  }

  factory Variant.mini() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Mini Chess',
      boardSize: BoardSize.mini,
      startPosition: 'rbnkbr/pppppp/6/6/PPPPPP/RBNKBR w KQkq - 0 1',
      pieceTypes: standard.pieceTypes..['P'] = PieceType.simplePawn(),
      castlingOptions: CastlingOptions.mini,
      enPassant: false,
    );
  }

  factory Variant.miniRandom() {
    Variant mini = Variant.mini();
    return mini.copyWith(
      name: 'Mini Random',
      startPosBuilder: () => buildRandomPosition(size: BoardSize.mini),
      castlingOptions: CastlingOptions.miniRandom,
      outputOptions: OutputOptions.chess960,
    );
  }

  factory Variant.micro() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Micro Chess',
      boardSize: BoardSize(5, 5),
      startPosition: 'rnbqk/ppppp/5/PPPPP/RNBQK w Qq - 0 1',
      castlingOptions: CastlingOptions.micro,
      firstMoveRanks: [
        [Bishop.rank2],
        [Bishop.rank4],
      ],
    );
  }

  factory Variant.nano() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Nano Chess',
      boardSize: BoardSize(4, 5),
      startPosition: 'knbr/p3/4/3P/RBNK w Qk - 0 1',
      castlingOptions: CastlingOptions.nano,
      firstMoveRanks: [
        [Bishop.rank2],
        [Bishop.rank4],
      ],
    );
  }

  factory Variant.seirawan() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Seirawan Chess',
      startPosition:
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[HEhe] w KQkqABCDEFGHabcdefgh - 0 1',
      gatingMode: GatingMode.flex,
      outputOptions: OutputOptions.seirawan,
      pieceTypes: {
        ...standard.pieceTypes,
        'H': PieceType.archbishop(), // hawk
        'E': PieceType.chancellor(), // elephant
      },
    );
  }

  factory Variant.threeCheck() => Variant.standard().copyWith(
        name: 'Three Check',
        gameEndConditions: GameEndConditions.threeCheck,
      );

  factory Variant.kingOfTheHill() {
    final standard = Variant.standard();
    Map<String, PieceType> pieceTypes = {...standard.pieceTypes};
    pieceTypes['K'] = PieceType.fromBetza(
      'K',
      royal: true,
      promoOptions: PiecePromoOptions.none,
      regionEffects: [RegionEffect.winGame(white: 'hill', black: 'hill')],
    );
    return standard.copyWith(
      name: 'King of the Hill',
      pieceTypes: pieceTypes,
      regions: {
        'hill': BoardRegion(
          startFile: Bishop.fileD,
          endFile: Bishop.fileE,
          startRank: Bishop.rank4,
          endRank: Bishop.rank5,
        ),
      },
    );
  }

  factory Variant.atomic() {
    final standard = Variant.standard();
    return standard.copyWith(
      name: 'Atomic Chess',
      actions: [
        Action.explodeOnCapture(Area.radius(1)),
        Action.checkRoyalsAlive(),
      ],
    );
  }

  factory Variant.spawn() {
    final standard = Variant.standard();
    final pieceTypes = standard.pieceTypes;
    pieceTypes['K'] = PieceType.king().copyWith(
      actions: [
        Action(
          event: ActionEvent.afterMove,
          action: ActionDefinitions.addToHand('P'),
        ),
      ],
    );
    return standard.copyWith(
      name: 'Spawn Chess',
      description: 'Moving the exposed king adds a pawn to the player\'s hand.',
      startPosition: 'rnbnkbnr/8/8/8/8/8/8/RNBNKBNR w KQkq - 0 1',
      handOptions: HandOptions.enabledOnly,
      pieceTypes: pieceTypes,
    );
  }
}
