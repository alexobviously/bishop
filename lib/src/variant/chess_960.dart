part of 'variant.dart';

/// Generates a valid Chess960 FEN string.
String build960Position() {
  const knight = 'N';
  const bishop = 'B';
  const rook = 'R';
  const queen = 'Q';
  const king = 'K';
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

/// Builds an arbitrary random position. Currently of limited use, but will
/// be generalised more at some point.
String buildRandomPosition({required BoardSize size, int? numRooks}) {
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
  Random r = Random();

  void placePiece(int sq, String pt) {
    pieces[sq] = pt;
    squares.remove(sq);
  }

  int randomSquare() => squares[r.nextInt(squares.length)];

  numRooks ??= r.nextInt(3);
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
