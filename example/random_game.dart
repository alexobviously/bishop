import 'package:bishop/bishop.dart';

main(List<String> args) {
  Bishop game = Bishop(variant: Variant.standard());

  while (!game.gameOver) {
    game.makeRandomMove();
  }
  print(game.ascii());
  print(game.pgn());
}
