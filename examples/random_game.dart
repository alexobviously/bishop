import 'package:squares/squares.dart';

main(List<String> args) {
  Squares game = Squares(variant: Variant.standard());

  while (!game.gameOver) {
    game.makeRandomMove();
  }
  print(game.ascii());
  print(game.pgn());
}
