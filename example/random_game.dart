import 'package:bishop/bishop.dart';

main(List<String> args) {
  Game game = Game(variant: Variant.standard());

  while (!game.gameOver) {
    game.makeRandomMove();
  }
  print(game.ascii());
  print(game.pgn());
}
