import 'constants.dart';
import 'variant/variant.dart';

typedef Square = int;

@Deprecated('Use Bishop.empty')
const Square empty = 0;
@Deprecated('Use Bishop.promoFlag')
const int promoFlag = 1;

extension SquareLogic on Square {
  Colour get colour => this & 1; // colour only
  int get type => (this >> 1) & 127; // piece type only
  int get piece => this & 255; // piece with colour
  int get flags => (this >> 8) & 15;
  bool get isEmpty => this == 0;
  bool get isNotEmpty => this != 0;
  bool hasFlag(int flag) => this & (flag << 8) != 0;
  Square get flipColour => this ^ 1;
}

Square makePiece(int piece, Colour colour, [int flags = 0]) {
  assert(colour <= Bishop.black);
  return (flags << 8) + (piece << 1) + colour;
}

String squareName(int square, [BoardSize boardSize = const BoardSize(8, 8)]) {
  int rank = boardSize.v - (square ~/ (boardSize.h * 2));
  int file = square % (boardSize.h * 2);
  String fileName = String.fromCharCode(Bishop.asciiA + file);
  return '$fileName$rank';
}

String fileSymbol(int file) => String.fromCharCode(Bishop.asciiA + file);
int fileFromSymbol(String symbol) =>
    symbol.toLowerCase().codeUnits[0] - Bishop.asciiA;

int squareNumber(String name, [BoardSize boardSize = const BoardSize(8, 8)]) {
  name = name.toLowerCase();
  RegExp rx = RegExp(r'([A-Za-z])([0-9]+)');
  RegExpMatch? match = rx.firstMatch(name);
  assert(match != null, 'Invalid square name: $name');
  assert(match!.groupCount == 2, 'Invalid square name: $name');
  String file = match!.group(1)!;
  String rank = match.group(2)!;
  int fileNum = file.codeUnits[0] - Bishop.asciiA;
  int rankNum = boardSize.v - int.parse(rank);
  int square = rankNum * boardSize.h * 2 + fileNum;
  return square;
}

@Deprecated('Use BoardSize.onBoard or Bishop.onBoard')
bool onBoard(int square, [BoardSize boardSize = const BoardSize(8, 8)]) =>
    boardSize.onBoard(square);
@Deprecated('Use BoardSize.file or Bishop.file')
int file(int square, [BoardSize size = BoardSize.standard]) =>
    size.file(square);
@Deprecated('Use BoardSize.rank or Bishop.rank')
int rank(int square, [BoardSize size = BoardSize.standard]) =>
    size.rank(square);
@Deprecated('Use BoardSize.square or Bishop.square')
int getSquare(int file, int rank, [BoardSize size = BoardSize.standard]) =>
    size.square(file, rank);
