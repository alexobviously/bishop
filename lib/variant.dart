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

  late List<PieceDefinition> pieces;

  Variant({
    required this.name,
    required this.boardSize,
    required this.pieceTypes,
    this.castling = false,
    this.castleTarget,
    this.startPosition,
    this.startPosBuilder,
    this.promotion = false,
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
  }

  void normalisePieces() {
    pieceTypes.forEach((_, p) => p.normalise(boardSize));
  }

  void buildPieceDefinitions() {
    pieces = [];
    pieceTypes.forEach((s, p) => pieces.add(PieceDefinition(type: p, symbol: s)));
  }

  factory Variant.standard() {
    return Variant(
      name: 'Chess',
      boardSize: BoardSize.standard(),
      castling: true,
      castleTarget: 'R',
      //startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      promotion: true,
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
}

class BoardSize {
  final int h;
  final int v;
  int get numSquares => h * v;
  const BoardSize(this.h, this.v);
  factory BoardSize.standard() => BoardSize(8, 8);
}
