import 'package:bishop/bishop.dart';

void main(List<String> args) async {
  Game game = Game(variant: Variant.mini());
  Engine engine = Engine(game: game);

  String formatResult(EngineResult res) {
    if (!res.hasMove) return 'No Move';
    String san = game.toSan(res.move!);
    return '$san (${res.eval}) [depth ${res.depth}]';
  }

  while (!game.gameOver) {
    String playerName = game.turn == Bishop.white ? 'White' : 'Black';
    print('~~ $playerName is thinking..');
    EngineResult res = await engine.search();
    print('Best Move: ${formatResult(res)}');
    if (res.hasMove) game.makeMove(res.move!);
    print(game.ascii());
    print(game.fen);
  }
}
