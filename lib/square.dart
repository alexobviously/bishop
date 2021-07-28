import 'constants.dart';
import 'variant.dart';

typedef Square = int;

Square EMPTY = 0;

extension SquareLogic on Square {
  Colour get colour => this & 1;
  int get piece => (this >> 1) & 127;
  int get flags => (this >> 8) & 15;
  bool get isEmpty => this == 0;
  bool get isNotEmpty => this != 0;
}

Square makePiece(int piece, Colour colour, [int flags = 0]) {
  assert(colour <= BLACK);
  return (flags << 8) + (piece << 1) + colour;
}

String squareName(int square, [BoardSize boardSize = const BoardSize(8, 8)]) {
  int rank = boardSize.v - (square ~/ (boardSize.h * 2));
  int file = square % (boardSize.h * 2);
  String fileName = String.fromCharCode(ASCII_a + file);
  return '$fileName$rank';
}

int squareNumber(String name, [BoardSize boardSize = const BoardSize(8, 8)]) {
  name = name.toLowerCase();
  RegExp rx = RegExp(r'([A-Za-z])([0-9]+)');
  RegExpMatch? match = rx.firstMatch(name);
  assert(match != null, 'Invalid square name: $name');
  assert(match!.groupCount == 2, 'Invalid square name: $name');
  String file = match!.group(1)!;
  String rank = match.group(2)!;
  int _file = file.codeUnits[0] - ASCII_a;
  int _rank = boardSize.v - int.parse(rank);
  int square = _rank * boardSize.h * 2 + _file;
  return square;
}

// TODO: find a clever bitwise way to do this, like 0x88
bool onBoard(int square, [BoardSize boardSize = const BoardSize(8, 8)]) {
  if (square < 0) return false;
  if (square >= boardSize.numSquares * 2) return false;
  int x = square % (boardSize.h * 2);
  return x < boardSize.h;
}

int file(int square, [BoardSize boardSize = const BoardSize(8, 8)]) => square % (boardSize.h * 2);
int rank(int square, [BoardSize boardSize = const BoardSize(8, 8)]) => boardSize.v - (square ~/ (boardSize.h * 2)) - 1;
int getSquare(int file, int rank, [BoardSize boardSize = const BoardSize(8, 8)]) =>
    (boardSize.v - rank - 1) * (boardSize.h * 2) + file;
