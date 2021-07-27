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
