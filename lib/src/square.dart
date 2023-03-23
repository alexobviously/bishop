import 'constants.dart';

// Square anatomy
// [00-01]    2 bit:    colour    (0: white, 1: black)
// [02-09]    8 bits:   piece type
// [10-17]    8 bits:   internal piece type
// [18]       1 bit:    initial state flag
// [19-31]    13 bits:  flags     in reality probably 45 bits

typedef Square = int;

/// Contains methods for dealing with the internal anatomy of the
/// square representation.
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
  int get flags => this >> Bishop.flagsStartBit;

  /// Whether there is a piece.
  bool get isEmpty => type == 0;

  /// Whether there isn't a piece.
  bool get isNotEmpty => type != 0;

  /// Whether there is an internal type.
  bool get hasInternalType => internalType != 0;
  bool get inInitialState => hasBit(Bishop.initialStateBit);
  int setBit(int bit) => this | (1 << bit);
  int unsetBit(int bit) => this & ~(1 << bit);
  int toggleBit(int bit) => this ^ (1 << bit);
  bool hasBit(int bit) => (this & (1 << bit)) != 0;
  int setFlag(int flag) => setBit(Bishop.flagsStartBit + flag);
  int unsetFlag(int flag) => unsetBit(Bishop.flagsStartBit + flag);
  int toggleFlag(int flag) => toggleBit(Bishop.flagsStartBit + flag);
  bool hasFlag(int flag) => hasBit(Bishop.flagsStartBit + flag);
  int setInternalType(int type) => makePiece(
        this.type,
        colour,
        internalType: type,
        initialState: inInitialState,
        flags: flags,
      );
  int setInitialState(bool initial) => initial
      ? setBit(Bishop.initialStateBit)
      : unsetBit(Bishop.initialStateBit);
  int flipColour() => this ^ 1;
}

int makeFlags(List<int> flags) => flags.fold<int>(0, (p, e) => p + (1 << e));

int makePiece(
  int piece,
  int colour, {
  int internalType = 0,
  bool initialState = false,
  int flags = 0,
}) =>
    (flags << Bishop.flagsStartBit) +
    (initialState ? 1 << Bishop.initialStateBit : 0) +
    (internalType << 10) +
    (piece << 2) +
    colour;

String fileSymbol(int file) => String.fromCharCode(Bishop.asciiA + file);
int fileFromSymbol(String symbol) =>
    symbol.toLowerCase().codeUnits[0] - Bishop.asciiA;
