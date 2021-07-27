import 'dart:math';

String build960Position() {
  const KNIGHT = 'N';
  const BISHOP = 'B';
  const ROOK = 'R';
  const QUEEN = 'Q';
  const KING = 'K';
  List<int> squares = Iterable<int>.generate(8).toList();
  List<String> pieces = List.filled(8, '');
  Random r = Random();

  void placePiece(int sq, String pt) {
    pieces[sq] = pt;
    squares.remove(sq);
  }

  int randomSquare() => squares[r.nextInt(squares.length)];

  // Place bishops
  List<int> bishops = [r.nextInt(4) * 2, r.nextInt(4) * 2 + 1];
  for (int x in bishops) placePiece(x, BISHOP);

  // Place queen
  placePiece(randomSquare(), QUEEN);

  // Place knights
  for (int _ in [0, 0]) placePiece(randomSquare(), KNIGHT);

  // Place rooks and king
  placePiece(squares.first, ROOK);
  placePiece(squares.first, KING);
  placePiece(squares.first, ROOK);
  String blackPieces = pieces.map((p) => p.toLowerCase()).join('');
  String whitePieces = pieces.map((p) => p.toUpperCase()).join('');
  String pawns = 'p' * 8;
  String pos = '$blackPieces/$pawns/8/8/8/8/${pawns.toUpperCase()}/$whitePieces w KQkq - 0 1';
  return pos;
}
