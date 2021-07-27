import 'dart:math';

import '960.dart';
import 'piece_type.dart';

class Variant {
  final String name;
  final BoardSize boardSize;
  final Map<String, PieceType> pieceTypes;
  final bool castling;
  final String? castleTarget;
  final String? startPosition;
  final Function()? startPosBuilder;
  final bool promotion;
  final bool enPassant;

  late List<PieceDefinition> pieces;
  late int epPiece;

  Variant({
    required this.name,
    required this.boardSize,
    required this.pieceTypes,
    this.castling = false,
    this.castleTarget,
    this.startPosition,
    this.startPosBuilder,
    this.promotion = false,
    this.enPassant = false,
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
    String? startPosition,
    Function()? startPosBuilder,
    bool? promotion,
  }) {
    return Variant(
      name: name ?? this.name,
      boardSize: boardSize ?? this.boardSize,
      pieceTypes: pieceTypes ?? this.pieceTypes,
      castling: castling ?? this.castling,
      castleTarget: castleTarget ?? this.castleTarget,
      startPosition: startPosition ?? this.startPosition,
      startPosBuilder: startPosBuilder ?? this.startPosBuilder,
      promotion: promotion ?? this.promotion,
    );
  }

  void init() {
    normalisePieces();
    buildPieceDefinitions();
    epPiece = pieces.indexWhere((p) => p.type.enPassantable);
  }

  void normalisePieces() {
    pieceTypes.forEach((_, p) => p.normalise(boardSize));
  }

  void buildPieceDefinitions() {
    pieces = [PieceDefinition.empty()];
    pieceTypes.forEach((s, p) => pieces.add(PieceDefinition(type: p, symbol: s)));
  }

  factory Variant.standard() {
    return Variant(
      name: 'Chess',
      boardSize: BoardSize.standard(),
      castling: true,
      castleTarget: 'R',
      startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      promotion: true,
      enPassant: true,
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
      castling: false,
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
  const BoardSize(this.h, this.v);
  factory BoardSize.standard() => BoardSize(8, 8);
}
