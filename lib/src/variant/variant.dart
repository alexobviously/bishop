import 'dart:math';

import 'package:bishop/bishop.dart';
import 'package:bishop/src/castling_rights.dart';
import 'package:bishop/src/variant/material_conditions.dart';

import '../constants.dart';
import '../piece_type.dart';

part '960.dart';
part 'board_size.dart';
part 'castling_options.dart';
part 'output_options.dart';

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

  /// The castling rules for this variant.
  final CastlingOptions castlingOptions;

  /// Material conditions that define how insufficient material draws should be decided.
  final MaterialConditions<String> materialConditions;
  final OutputOptions outputOptions;

  /// If the variant has a fixed starting position, specify it here as a full [FEN string](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).
  final String? startPosition;

  /// If this variant can start in a number of different positions, such as Chess960,
  /// provide a function that does this. See [Variant.chess960()] for an example.
  final Function()? startPosBuilder;

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
  final int gatingMode;

  /// The relative values of pieces. These are usually already set in the [PieceType]
  /// definitions, so only use this if you want to override those.
  /// For example, you have a variant where a pawn is worth 200 instead of 100,
  /// but you still want to use the normal pawn definition.
  final Map<String, int>? pieceValues;

  late List<PieceDefinition> pieces;
  late Map<String, PieceDefinition> pieceLookup;
  late List<int> promotionPieces;
  late int epPiece;
  late int castlingPiece;
  late int royalPiece;
  late MaterialConditions<int> materialConditionsInt;

  bool get castling => castlingOptions.enabled;
  bool get gating => gatingMode > GatingMode.NONE;

  @override
  String toString() => name;

  Variant({
    required this.name,
    required this.boardSize,
    required this.pieceTypes,
    required this.castlingOptions,
    this.materialConditions = MaterialConditions.NONE,
    required this.outputOptions,
    this.startPosition,
    this.startPosBuilder,
    this.promotion = false,
    this.promotionRanks = const [-1, -1],
    this.enPassant = false,
    this.firstMoveRanks = const [[], []],
    this.halfMoveDraw,
    this.repetitionDraw,
    this.hands = false,
    this.gatingMode = GatingMode.NONE,
    this.pieceValues,
  }) {
    assert(startPosition != null || startPosBuilder != null, 'Variant needs either a startPosition or startPosBuilder');
    init();
  }

  Variant copyWith({
    String? name,
    BoardSize? boardSize,
    Map<String, PieceType>? pieceTypes,
    CastlingOptions? castlingOptions,
    MaterialConditions<String>? materialConditions,
    OutputOptions? outputOptions,
    String? startPosition,
    Function()? startPosBuilder,
    bool? promotion,
    List<int>? promotionRanks,
    bool? enPassant,
    List<List<int>>? firstMoveRanks,
    int? halfMoveDraw,
    int? repetitionDraw,
    bool? hands,
    int? gatingMode,
    Map<String, int>? pieceValues,
  }) {
    return Variant(
      name: name ?? this.name,
      boardSize: boardSize ?? this.boardSize,
      pieceTypes: pieceTypes ?? this.pieceTypes,
      castlingOptions: castlingOptions ?? this.castlingOptions,
      materialConditions: materialConditions ?? this.materialConditions,
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
    );
  }

  void init() {
    initPieces();
    buildPieceDefinitions();
    convertMaterialConditions();
    royalPiece = pieces.indexWhere((p) => p.type.royal);
    if (enPassant)
      epPiece = pieces.indexWhere((p) => p.type.enPassantable);
    else
      epPiece = INVALID;
    if (castling)
      castlingPiece = pieces.indexWhere((p) => p.symbol == castlingOptions.rookPiece);
    else
      castlingPiece = INVALID;
  }

  int pieceIndex(String symbol) => pieces.indexWhere((p) => p.symbol == symbol);

  void initPieces() {
    pieceTypes.forEach((_, p) => p.init(boardSize));
  }

  void buildPieceDefinitions() {
    pieces = [PieceDefinition.empty()];
    pieceLookup = {};
    pieceTypes.forEach((s, p) {
      int value = p.royal ? MATE_UPPER : p.value;
      if (pieceValues?.containsKey(s) ?? false) value = pieceValues![s]!;
      PieceDefinition _piece = PieceDefinition(type: p, symbol: s, value: value);
      pieces.add(_piece);
      pieceLookup[s] = _piece;
    });
    promotionPieces = [];
    for (int i = 0; i < pieces.length; i++) {
      // && !pieces[i].type.royal) ?
      if (pieces[i].type.canPromoteTo) promotionPieces.add(i);
    }
  }

  void convertMaterialConditions() {
    if (!materialConditions.enabled)
      materialConditionsInt = MaterialConditions(enabled: false);
    else {
      materialConditionsInt = MaterialConditions(
        enabled: true,
        soloMaters: materialConditions.soloMaters.map((e) => pieceIndex(e)).toList(),
        pairMaters: materialConditions.pairMaters.map((e) => pieceIndex(e)).toList(),
        specialCases: materialConditions.specialCases.map((e) => e.map((p) => pieceIndex(p)).toList()).toList(),
      );
    }
  }

  factory Variant.standard() {
    return Variant(
      name: 'Chess',
      boardSize: BoardSize.STANDARD,
      startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      castlingOptions: CastlingOptions.standard(),
      materialConditions: MaterialConditions.STANDARD,
      outputOptions: OutputOptions.standard(),
      promotion: true,
      promotionRanks: [RANK_1, RANK_8],
      enPassant: true,
      halfMoveDraw: 100,
      repetitionDraw: 3,
      firstMoveRanks: [
        [RANK_2], // white
        [RANK_7], // black
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
      castlingOptions: CastlingOptions.chess960(),
      outputOptions: OutputOptions.chess960(),
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
      startPosition: 'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1',
      castlingOptions: CastlingOptions.capablanca(),
      pieceTypes: standard.pieceTypes
        ..addAll({
          'A': PieceType.archbishop(),
          'C': PieceType.chancellor(),
        }),
    );
  }

  factory Variant.grand() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Grand Chess',
      boardSize: BoardSize(10, 10),
      startPosition: 'r8r/1nbqkcabn1/pppppppppp/10/10/10/10/PPPPPPPPPP/1NBQKCABN1/R8R w - - 0 1',
      castlingOptions: CastlingOptions.none(),
      promotionRanks: [RANK_3, RANK_8],
      firstMoveRanks: [
        [RANK_3],
        [RANK_8],
      ],
      pieceTypes: standard.pieceTypes
        ..addAll({
          'C': PieceType.chancellor(), // marshal
          'A': PieceType.archbishop(), // cardinal
        }),
    );
  }

  factory Variant.mini() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Mini Chess',
      boardSize: BoardSize.MINI,
      startPosition: 'rbnkbr/pppppp/6/6/PPPPPP/RBNKBR w KQkq - 0 1',
      pieceTypes: standard.pieceTypes..['P'] = PieceType.simplePawn(),
      castlingOptions: CastlingOptions.mini(),
      enPassant: false,
      promotionRanks: [RANK_1, RANK_6],
    );
  }

  factory Variant.miniRandom() {
    Variant mini = Variant.mini();
    return mini.copyWith(
      name: 'Mini Random',
      startPosBuilder: () => buildRandomPosition(size: BoardSize.MINI),
      castlingOptions: CastlingOptions.miniRandom(),
      outputOptions: OutputOptions.chess960(),
    );
  }

  factory Variant.micro() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Micro Chess',
      boardSize: BoardSize(5, 5),
      startPosition: 'rnbqk/ppppp/5/PPPPP/RNBQK w Qq - 0 1',
      promotionRanks: [RANK_1, RANK_5],
      castlingOptions: CastlingOptions.micro(),
      firstMoveRanks: [
        [RANK_2],
        [RANK_4],
      ],
    );
  }

  factory Variant.nano() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Nano Chess',
      boardSize: BoardSize(4, 5),
      startPosition: 'knbr/p3/4/3P/RBNK w Qk - 0 1',
      promotionRanks: [RANK_1, RANK_5],
      castlingOptions: CastlingOptions.nano(),
      firstMoveRanks: [
        [RANK_2],
        [RANK_4],
      ],
    );
  }

  factory Variant.seirawan() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Seirawan Chess',
      startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[HEhe] w KQkqABCDEFGHabcdefgh - 0 1',
      gatingMode: GatingMode.FLEX,
      outputOptions: OutputOptions.seirawan(),
      pieceTypes: standard.pieceTypes
        ..addAll({
          'H': PieceType.archbishop(),
          'E': PieceType.chancellor(),
        }),
    );
  }
}
