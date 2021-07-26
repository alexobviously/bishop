typedef Colour = int;

extension Opponent on Colour {
  Colour get opponent => 1 - this;
}

const Colour WHITE = 0;
const Colour BLACK = 1;

class Modality {
  static const int QUIET = 0;
  static const int CAPTURE = 1;
  static const int BOTH = 2;

  static const List<int> ALL = [QUIET, CAPTURE, BOTH];
}
