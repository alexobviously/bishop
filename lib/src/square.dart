import 'constants.dart';
import 'variant/variant.dart';

// Square anatomy
// [00-01]    2 bit:    colour    (0: white, 1: black)
// [02-09]    8 bits:   piece type
// [10-17]    8 bits:   internal piece type
// [18-31]    14 bits:  flags     in reality probably 46 bits

typedef Square = int;

@Deprecated('Use Bishop.empty')
const Square empty = 0;

extension SquareLogic on int {
  int get colour => this & 3; // colour only
  int get type => (this >> 2) & 255; // piece type only
  int get internalType => (this >> 10) & 255; // internal type only
  int get piece => this & 1023; // colour & type
  int get flags => this >> 18; // flags only
  bool get isEmpty => type == 0;
  bool get isNotEmpty => type != 0;
  bool get hasInternalType => internalType != 0;
  int setFlag(int flag) => this | (1 << (18 + flag));
  int unsetFlag(int flag) => this & ~(1 << (18 + flag));
  int toggleFlag(int flag) => this ^ (1 << (18 + flag));
  bool hasFlag(int flag) => (this & (flag << 18)) != 0;
  int setInternalType(int type) =>
      makePiece(piece, colour, internalType: type, flags: flags);
  int get flipColour => this ^ 1;
}

int makePiece(
  int piece,
  int colour, {
  int internalType = 0,
  int flags = 0,
}) =>
    (flags << 18) + (internalType << 10) + (piece << 2) + colour;

@Deprecated('Use BoardSize.squareName or Bishop.squareName')
String squareName(int square, [BoardSize size = const BoardSize(8, 8)]) =>
    size.squareName(square);

@Deprecated('Use BoardSize.squareNumber or Bishop.squareNumber')
int squareNumber(String name, [BoardSize size = const BoardSize(8, 8)]) =>
    size.squareNumber(name);

String fileSymbol(int file) => String.fromCharCode(Bishop.asciiA + file);
int fileFromSymbol(String symbol) =>
    symbol.toLowerCase().codeUnits[0] - Bishop.asciiA;

@Deprecated('Use BoardSize.onBoard or Bishop.onBoard')
bool onBoard(int square, [BoardSize boardSize = const BoardSize(8, 8)]) =>
    boardSize.onBoard(square);
