import 'dart:math';

import 'package:bishop/bishop.dart';

part 'board_size.dart';
part 'built_variant.dart';
part 'castling_options.dart';
part 'chess_960.dart';
part 'game_end_conditions.dart';
part 'output_options.dart';
part 'material_conditions.dart';
part 'musketeer.dart';
part 'xiangqi.dart';

/// Specifies the rules and pieces to be used, size of the board,
/// information on how FENs are outputted, and so on and so on.
class Variant {
  /// A human-friendly name.
  final String name;

  /// The size of the board.
  final BoardSize boardSize;

  /// The pieces to be used in this variant, in the form symbol: pieceType.
  /// Symbols are single uppercase letters, such as 'P' (pawn) or 'N' (knight).
  final Map<String, PieceType> pieceTypes;

  /// The castling rules for this VariantData.
  final CastlingOptions castlingOptions;

  /// Material conditions that define how insufficient material draws should be decided.
  final MaterialConditions<String> materialConditions;

  final GameEndConditions gameEndConditions;

  final OutputOptions outputOptions;

  /// If the variant has a fixed starting position, specify it here as a full [FEN string](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).
  final String? startPosition;

  /// If this variant can start in a number of different positions, such as Chess960,
  /// provide a function that does this. See [VariantData.chess960()] for an example.
  final FenBuilder? startPosBuilder;

  /// Is promotion enabled?
  final bool promotion;

  /// The first ranks for [WHITE, BLACK] that pieces can be promoted on.
  /// If the rank specified is not the final rank the piece can reach, then promotion
  /// will be optional on every rank up until the final rank, when it becomes mandatory.
  final List<int> promotionRanks;

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
  final bool hands;

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

  /// A list of region definitions for the board, for use with `RegionEffects`
  /// in piece definitions.
  final List<BoardRegion> regions;

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
    this.boardSize = BoardSize.standard,
    required this.pieceTypes,
    this.castlingOptions = CastlingOptions.standard,
    this.materialConditions = MaterialConditions.none,
    this.gameEndConditions = GameEndConditions.standard,
    this.outputOptions = OutputOptions.standard,
    this.startPosition,
    this.startPosBuilder,
    this.promotion = false,
    this.promotionRanks = const [-1, -1],
    this.enPassant = false,
    this.firstMoveRanks = const [[], []],
    this.halfMoveDraw,
    this.repetitionDraw,
    this.hands = false,
    this.gatingMode = GatingMode.none,
    this.pieceValues,
    this.flyingGenerals = false,
    this.regions = const [],
  }) : assert(
          startPosition != null || startPosBuilder != null,
          'Variant needs either a startPosition or startPosBuilder',
        );

  Variant copyWith({
    String? name,
    BoardSize? boardSize,
    Map<String, PieceType>? pieceTypes,
    CastlingOptions? castlingOptions,
    MaterialConditions<String>? materialConditions,
    GameEndConditions? gameEndConditions,
    OutputOptions? outputOptions,
    String? startPosition,
    FenBuilder? startPosBuilder,
    bool? promotion,
    List<int>? promotionRanks,
    bool? enPassant,
    List<List<int>>? firstMoveRanks,
    int? halfMoveDraw,
    int? repetitionDraw,
    bool? hands,
    GatingMode? gatingMode,
    Map<String, int>? pieceValues,
    bool? flyingGenerals,
    List<BoardRegion>? regions,
  }) {
    return Variant(
      name: name ?? this.name,
      boardSize: boardSize ?? this.boardSize,
      pieceTypes: pieceTypes ?? this.pieceTypes,
      castlingOptions: castlingOptions ?? this.castlingOptions,
      materialConditions: materialConditions ?? this.materialConditions,
      gameEndConditions: gameEndConditions ?? this.gameEndConditions,
      outputOptions: outputOptions ?? this.outputOptions,
      startPosition: startPosition ?? this.startPosition,
      startPosBuilder: startPosBuilder ?? this.startPosBuilder,
      promotion: promotion ?? this.promotion,
      promotionRanks: promotionRanks ?? this.promotionRanks,
      enPassant: enPassant ?? this.enPassant,
      firstMoveRanks: firstMoveRanks ?? this.firstMoveRanks,
      halfMoveDraw: halfMoveDraw ?? this.halfMoveDraw,
      repetitionDraw: repetitionDraw ?? this.repetitionDraw,
      hands: hands ?? this.hands,
      gatingMode: gatingMode ?? this.gatingMode,
      pieceValues: pieceValues ?? this.pieceValues,
      flyingGenerals: flyingGenerals ?? this.flyingGenerals,
      regions: regions ?? this.regions,
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
      promotion: true,
      promotionRanks: [Bishop.rank1, Bishop.rank8],
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
      hands: true,
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
      promotionRanks: [Bishop.rank3, Bishop.rank8],
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
      promotionRanks: [Bishop.rank1, Bishop.rank6],
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
      promotionRanks: [Bishop.rank1, Bishop.rank5],
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
      promotionRanks: [Bishop.rank1, Bishop.rank5],
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
}
