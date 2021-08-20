import 'package:bishop/bishop.dart';

main(List<String> args) {
  Game game = Game(variant: Variant.mini());
  while (!game.gameOver) {
    print(game.ascii());
    print(game.fen);
    game.makeRandomMove();
  }
  print(game.ascii());
  print(game.pgn());
}
