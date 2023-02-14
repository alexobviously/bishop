import 'dart:math';

import 'package:bishop/bishop.dart';

typedef FenBuilder = String Function({int? seed});

abstract class StartPositionBuilder {
  String build({int? seed});
}

class Chess960StartPosBuilder implements StartPositionBuilder {
  @override
  String build({int? seed}) {
    const knight = 'N';
    const bishop = 'B';
    const rook = 'R';
    const queen = 'Q';
    const king = 'K';
    List<int> squares = Iterable<int>.generate(8).toList();
    List<String> pieces = List.filled(8, '');
    Random r = Random(seed);

    void placePiece(int sq, String pt) {
      pieces[sq] = pt;
      squares.remove(sq);
    }

    int randomSquare() => squares[r.nextInt(squares.length)];

    // Place bishops
    List<int> bishops = [r.nextInt(4) * 2, r.nextInt(4) * 2 + 1];
    for (int x in bishops) {
      placePiece(x, bishop);
    }

    // Place queen
    placePiece(randomSquare(), queen);

    // Place knights
    placePiece(randomSquare(), knight);
    placePiece(randomSquare(), knight);

    // Place rooks and king
    placePiece(squares.first, rook);
    placePiece(squares.first, king);
    placePiece(squares.first, rook);
    String blackPieces = pieces.map((p) => p.toLowerCase()).join('');
    String whitePieces = pieces.map((p) => p.toUpperCase()).join('');
    String pawns = 'p' * 8;
    String pos =
        '$blackPieces/$pawns/8/8/8/8/${pawns.toUpperCase()}/$whitePieces w KQkq - 0 1';
    return pos;
  }
}

class Chess960StartPosAdapter extends BasicAdapter<Chess960StartPosBuilder> {
  Chess960StartPosAdapter()
      : super('bishop.start.chess960', Chess960StartPosBuilder.new);
}

class RandomChessStartPosBuilder implements StartPositionBuilder {
  final BoardSize size;
  final int? numRooks;

  const RandomChessStartPosBuilder({required this.size, this.numRooks});

  @override
  String build({int? seed}) {
    const knight = 'N';
    const bishop = 'B';
    const rook = 'R';
    const queen = 'Q';
    const king = 'K';
    const normalPieces = [knight, bishop, queen];
    int h = size.h;
    int v = size.v;
    List<int> squares = Iterable<int>.generate(h).toList();
    List<String> pieces = List.filled(h, '');
    Random r = Random(seed);

    void placePiece(int sq, String pt) {
      pieces[sq] = pt;
      squares.remove(sq);
    }

    int randomSquare() => squares[r.nextInt(squares.length)];

    int numRooks = this.numRooks ?? r.nextInt(3);
    bool qsFirst = r.nextBool();
    bool hasQueen = false;

    // Place normal pieces (knights/bishops/queens)
    for (int i = 0; i < (h - 1 - numRooks); i++) {
      String piece = normalPieces[r.nextInt(3)];
      if (piece == queen && hasQueen) piece = normalPieces[i % 2];
      if (piece == queen) hasQueen = true;
      placePiece(randomSquare(), piece);
    }

    // Place rooks and king
    CastlingRights castlingRights = 0;
    if (numRooks == 0) placePiece(squares.first, king);
    if (numRooks == 1) {
      castlingRights = qsFirst ? Castling.bothQ : Castling.bothK;
      placePiece(squares.first, qsFirst ? rook : king);
      placePiece(squares.first, qsFirst ? king : rook);
    }
    if (numRooks == 2) {
      castlingRights = Castling.mask;
      placePiece(squares.first, rook);
      placePiece(squares.first, king);
      placePiece(squares.first, rook);
    }

    String blackPieces = pieces.map((p) => p.toLowerCase()).join('');
    String whitePieces = pieces.map((p) => p.toUpperCase()).join('');
    String pawns = 'p' * h;
    String blankLines = List.filled(v - 4, '$h').join('/');

    String pos =
        '$blackPieces/$pawns/$blankLines/${pawns.toUpperCase()}/$whitePieces w ${castlingRights.formatted} - 0 1';
    return pos;
  }
}

class RandomChessStartPosAdapter
    extends BishopTypeAdapter<RandomChessStartPosBuilder> {
  @override
  String get id => 'bishop.start.randomChess';

  @override
  RandomChessStartPosBuilder build(Map<String, dynamic>? params) =>
      RandomChessStartPosBuilder(
        size: BoardSize.fromString(params?['size'] ?? '8x8'),
        numRooks: params?['numRooks'],
      );

  @override
  Map<String, dynamic>? export(RandomChessStartPosBuilder e) => {
        if (e.size != BoardSize.standard) 'size': e.size.simpleString,
        if (e.numRooks != null) 'numRooks': e.numRooks,
      };
}
