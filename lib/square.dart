import 'constants.dart';

typedef Square = int;

extension SquareLogic on Square {
  Colour get colour => this & 1;
  int get piece => (this >> 1) & 127;
  int get flags => (this >> 8) & 15;
}

Square square(int piece, Colour colour, [int flags = 0]) {
  assert(colour <= BLACK);
  return (flags << 8) + (piece << 1) + colour;
}
