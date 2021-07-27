typedef Colour = int;

extension Opponent on Colour {
  Colour get opponent => 1 - this;
}

const Colour WHITE = 0;
const Colour BLACK = 1;

const List<int> PLAYER_DIRECTION = [-1, 1];

const ASCII_a = 97;

const Map<String, String> UNICODE_PIECES = {
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

class Modality {
  static const int QUIET = 0;
  static const int CAPTURE = 1;
  static const int BOTH = 2;

  static const List<int> ALL = [QUIET, CAPTURE, BOTH];
}

// Just shorthands for building variants
class File {
  static const int A = 0;
  static const int B = 1;
  static const int C = 2;
  static const int D = 3;
  static const int E = 4;
  static const int F = 5;
  static const int G = 6;
  static const int H = 7;
  static const int I = 8;
  static const int J = 9;
  static const int K = 10;
  static const int L = 11;
  static const int M = 12;
}
