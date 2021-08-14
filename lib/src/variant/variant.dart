import 'dart:math';

import 'package:bishop/src/variant/material_conditions.dart';

import '../constants.dart';
import '../piece_type.dart';

part '960.dart';
part 'board_size.dart';
part 'castling_options.dart';
part 'output_options.dart';

class Variant {
  final String name;
  final BoardSize boardSize;
  final Map<String, PieceType> pieceTypes;
  final CastlingOptions castlingOptions;
  final MaterialConditions materialConditions;
  final OutputOptions outputOptions;
  final String? startPosition;
  final Function()? startPosBuilder;
  final bool promotion;
  final List<int> promotionRanks;
  final bool enPassant;
  final List<List<int>> firstMoveRanks; // e.g. where pawns can double move from
  final int? halfMoveDraw; // e.g. set this to 100 for the standard 50-move rule
  final int? repetitionDraw; // e.g. set this to 3 for standard threefold repetition
  final bool hands; // allow hands, like in crazyhouse
  final Map<String, int>? pieceValues;

  late List<PieceDefinition> pieces;
  late Map<String, PieceDefinition> pieceLookup;
  late List<int> promotionPieces;
  late int epPiece;
  late int castlingPiece;
  late int royalPiece;

  bool get castling => castlingOptions.enabled;

  Variant({
    required this.name,
    required this.boardSize,
    required this.pieceTypes,
    required this.castlingOptions,
    required this.materialConditions,
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
    MaterialConditions? materialConditions,
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
      pieceValues: pieceValues ?? this.pieceValues,
    );
  }

  void init() {
    initPieces();
    buildPieceDefinitions();
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

  factory Variant.standard() {
    return Variant(
      name: 'Chess',
      boardSize: BoardSize.standard(),
      startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      castlingOptions: CastlingOptions.standard(),
      materialConditions: MaterialConditions.standard(),
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
      boardSize: BoardSize(5, 5),
      startPosition: 'rnbqk/ppppp/5/PPPPP/RNBQK w Qq - 0 1',
      promotionRanks: [RANK_1, RANK_5],
      castlingOptions: CastlingOptions.mini(),
      firstMoveRanks: [
        [RANK_2],
        [RANK_4],
      ],
    );
  }

  factory Variant.micro() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Micro Chess',
      boardSize: BoardSize(4, 5),
      startPosition: 'knbr/p3/4/3P/RBNK w Qk - 0 1',
      promotionRanks: [RANK_1, RANK_5],
      castlingOptions: CastlingOptions.micro(),
      firstMoveRanks: [
        [RANK_2],
        [RANK_4],
      ],
    );
  }
}
