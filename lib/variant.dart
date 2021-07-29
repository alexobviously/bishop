import 'dart:math';

import '960.dart';
import 'constants.dart';
import 'piece_type.dart';

class Variant {
  final String name;
  final BoardSize boardSize;
  final Map<String, PieceType> pieceTypes;
  final bool castling;
  final String? castleTarget;
  final int? castlingKingsideFile;
  final int? castlingQueensideFile;
  final String? startPosition;
  final Function()? startPosBuilder;
  final bool promotion;
  final List<int> promotionRanks;
  final bool enPassant;
  final List<List<int>> firstMoveRanks; // e.g. where pawns can double move from
  final int? halfMoveLimit;

  late List<PieceDefinition> pieces;
  late List<int> promotionPieces;
  late int epPiece;
  late int castlingPiece;
  late int royalPiece;

  Variant({
    required this.name,
    required this.boardSize,
    required this.pieceTypes,
    this.castling = false,
    this.castleTarget,
    this.castlingKingsideFile,
    this.castlingQueensideFile,
    this.startPosition,
    this.startPosBuilder,
    this.promotion = false,
    this.promotionRanks = const [-1, -1],
    this.enPassant = false,
    this.firstMoveRanks = const [[], []],
    this.halfMoveLimit,
  }) {
    assert(startPosition != null || startPosBuilder != null, 'Variant needs either a startPosition or startPosBuilder');
    init();
  }

  Variant copyWith({
    String? name,
    BoardSize? boardSize,
    Map<String, PieceType>? pieceTypes,
    bool? castling,
    String? castleTarget,
    int? castlingKingsideFile,
    int? castlingQueensideFile,
    String? startPosition,
    Function()? startPosBuilder,
    bool? promotion,
    List<int>? promotionRanks,
    bool? enPassant,
    List<List<int>>? firstMoveRanks,
    int? halfMoveLimit,
  }) {
    return Variant(
      name: name ?? this.name,
      boardSize: boardSize ?? this.boardSize,
      pieceTypes: pieceTypes ?? this.pieceTypes,
      castling: castling ?? this.castling,
      castleTarget: castleTarget ?? this.castleTarget,
      castlingKingsideFile: castlingKingsideFile ?? this.castlingKingsideFile,
      castlingQueensideFile: castlingQueensideFile ?? this.castlingQueensideFile,
      startPosition: startPosition ?? this.startPosition,
      startPosBuilder: startPosBuilder ?? this.startPosBuilder,
      promotion: promotion ?? this.promotion,
      promotionRanks: promotionRanks ?? this.promotionRanks,
      enPassant: enPassant ?? this.enPassant,
      firstMoveRanks: firstMoveRanks ?? this.firstMoveRanks,
      halfMoveLimit: halfMoveLimit ?? this.halfMoveLimit,
    );
  }

  void init() {
    initPieces();
    buildPieceDefinitions();
    royalPiece = pieces.indexWhere((p) => p.type.royal);
    if (enPassant) epPiece = pieces.indexWhere((p) => p.type.enPassantable);
    if (castling) castlingPiece = pieces.indexWhere((p) => p.symbol == castleTarget);
  }

  void initPieces() {
    pieceTypes.forEach((_, p) => p.init(boardSize));
  }

  void buildPieceDefinitions() {
    pieces = [PieceDefinition.empty()];
    pieceTypes.forEach((s, p) => pieces.add(PieceDefinition(type: p, symbol: s)));
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
      castling: true,
      castleTarget: 'R',
      castlingKingsideFile: FILE_G,
      castlingQueensideFile: FILE_C,
      promotion: true,
      promotionRanks: [RANK_1, RANK_8],
      enPassant: true,
      halfMoveLimit: 100,
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
    );
  }

  factory Variant.capablanca() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Capablanca Chess',
      boardSize: BoardSize(10, 8),
      startPosition: 'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1',
      castlingKingsideFile: FILE_I,
      castlingQueensideFile: FILE_C,
      pieceTypes: standard.pieceTypes
        ..addAll({
          'A': PieceType.archbishop(),
          'C': PieceType.chancellor(),
        }),
    );
  }

  // TODO: flexible promotion rules - https://en.wikipedia.org/wiki/Grand_chess#Rules
  factory Variant.grand() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Grand Chess',
      boardSize: BoardSize(10, 10),
      startPosition: 'r8r/1nbqkcabn1/pppppppppp/10/10/10/10/PPPPPPPPPP/1NBQKCABN1/R8R w - - 0 1',
      castling: false,
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
}

class BoardSize {
  final int h;
  final int v;
  int get numSquares => h * v;
  int get minDim => min(h, v);
  int get maxDim => max(h, v);
  int get maxRank => v - 1;
  int get maxFile => h - 1;
  const BoardSize(this.h, this.v);
  factory BoardSize.standard() => BoardSize(8, 8);
}
