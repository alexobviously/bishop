import 'constants.dart';
import 'variant/variant.dart';

// Square anatomy
// [00-01]    2 bit:    colour    (0: white, 1: black)
// [02-09]    8 bits:   piece type
// [10-17]    8 bits:   internal piece type
// [18-31]    14 bits:  flags     in reality probably 46 bits

typedef Square = int;

extension SquareLogic on int {
  /// Colour only.
  int get colour => this & 3;

  /// Piece type only.
  int get type => (this >> 2) & 255;

  /// Internal type only.
  int get internalType => (this >> 10) & 255;

  /// Colour and piece type.
  int get piece => this & 1023;

  /// Flags only.
  int get flags => this >> 18;

  /// Whether there is a piece.
  bool get isEmpty => type == 0;

  /// Whether there isn't a piece.
  bool get isNotEmpty => type != 0;

  /// Whether there is an internal type.
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

String fileSymbol(int file) => String.fromCharCode(Bishop.asciiA + file);
int fileFromSymbol(String symbol) =>
    symbol.toLowerCase().codeUnits[0] - Bishop.asciiA;
