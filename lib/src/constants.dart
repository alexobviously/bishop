// ignore_for_file: constant_identifier_names

import 'package:bishop/bishop.dart';

typedef Colour = int;

extension Opponent on Colour {
  Colour get opponent => 1 - this;
}

typedef Hand = List<int>;
typedef FenBuilder = String Function();

class Bishop {
  static const Colour white = 0;
  static const Colour black = 1;

  static const int boardStart = 0;
  static const int invalid = -1;
  static const int hand = -2;

  static const List<int> playerDirection = [-1, 1];
  static const List<String> playerName = ['White', 'Black'];

  static const int asciiA = 97;
  static const int mateLower = 90000;
  static const int mateUpper = 100000;
  static const int defaultPieceValue = 200;

  // Just shorthands for building variants
  static const int fileA = 0;
  static const int fileB = 1;
  static const int fileC = 2;
  static const int fileD = 3;
  static const int fileE = 4;
  static const int fileF = 5;
  static const int fileG = 6;
  static const int fileH = 7;
  static const int fileI = 8;
  static const int fileJ = 9;
  static const int fileK = 10;
  static const int fileL = 11;
  static const int fileM = 12;
  static const int fileN = 13;
  static const int fileO = 14;
  static const int fileP = 15;

  static const int rank1 = 0;
  static const int rank2 = 1;
  static const int rank3 = 2;
  static const int rank4 = 3;
  static const int rank5 = 4;
  static const int rank6 = 5;
  static const int rank7 = 6;
  static const int rank8 = 7;
  static const int rank9 = 8;
  static const int rank10 = 9;
  static const int rank11 = 10;
  static const int rank12 = 11;
  static const int rank13 = 12;
  static const int rank14 = 13;
  static const int rank15 = 14;
  static const int rank16 = 15;

  static const Map<String, String> unicodePieces = {
    'R': '♜',
    'N': '♞',
    'B': '♝',
    'Q': '♛',
    'K': '♚',
    'P': '♟',
    'r': '♖',
    'n': '♘',
    'b': '♗',
    'q': '♕',
    'k': '♔',
    'p': '♙',
    '.': '·'
  };
}

@Deprecated('Use Bishop.white')
const Colour WHITE = Bishop.white;
@Deprecated('Use Bishop.black')
const Colour BLACK = Bishop.black;

@Deprecated('Use Bishop.boardStart')
const int BOARD_START = Bishop.boardStart;
@Deprecated('Use Bishop.invalid')
const int INVALID = Bishop.invalid;
@Deprecated('Use Bishop.hand')
const int HAND = Bishop.hand;

enum Modality {
  quiet,
  capture,
  both;
}

enum GatingMode {
  none,
  flex,
  fixed;

  bool operator >(GatingMode other) => index > other.index;
  bool operator <(GatingMode other) => index < other.index;
  bool operator >=(GatingMode other) => index >= other.index;
  bool operator <=(GatingMode other) => index <= other.index;
}

const defaultSeed = 7363661891;

/// All built in variants.
enum Variants {
  standard(Variant.standard),
  chess960(Variant.chess960),
  crazyhouse(Variant.crazyhouse),
  capablanca(Variant.capablanca),
  grand(Variant.grand),
  mini(Variant.mini),
  miniRandom(Variant.miniRandom),
  micro(Variant.micro),
  nano(Variant.nano),
  seirawan(Variant.seirawan),
  threeCheck(Variant.threeCheck),
  musketeer(Musketeer.variant);

  final Variant Function() builder;
  const Variants(this.builder);

  /// Builds a `Variant` for use with `Game`.
  Variant build() => builder();
}
