import 'dart:math';

import 'package:bishop/bishop.dart';

class Engine {
  final Game game;

  Engine({required this.game});

  Future<EngineResult> search({
    int maxDepth = 50,
    int timeLimit = 5000,
    int timeBuffer = 2000,
    int debug = 0,
    int printBest = 0,
  }) async {
    if (game.gameOver) {
      print(game.drawn ? 'Draw' : 'Checkmate');
      return const EngineResult();
    }
    int endTime = DateTime.now().millisecondsSinceEpoch + timeLimit;
    int endBuffer = endTime + timeBuffer;
    int depthSearched = 0;
    List<Move> moves = game.generateLegalMoves();
    Map<Move, int> evals = {};
    for (Move m in moves) {
      evals[m] = 0;
    }
    for (int depth = 1; depth < maxDepth; depth++) {
      if (debug > 0) print('----- DEPTH $depth -----');
      for (Move m in moves) {
        game.makeMove(m, false);
        int eval = -negamax(
          depth,
          -Bishop.mateUpper,
          Bishop.mateUpper,
          game.turn.opponent,
          debug,
        );
        game.undo();
        evals[m] = eval;
        int now = DateTime.now().millisecondsSinceEpoch;
        if (now >= endBuffer) break;
      }
      moves.sort((a, b) => evals[b]!.compareTo(evals[a]!));
      depthSearched = depth;
      int now = DateTime.now().millisecondsSinceEpoch;
      if (now >= endTime) break;
    }
    if (printBest > 0) {
      print('-- Best Moves --');
      for (Move m in moves.take(printBest)) {
        print('${game.toSan(m)}: ${evals[m]}');
      }
    }

    return EngineResult(
      move: moves.first,
      eval: evals[moves.first],
      depth: depthSearched,
    );
  }

  int negamax(int depth, int alpha, int beta, Colour player, [int debug = 0]) {
    int value = -Bishop.mateUpper;
    if (game.drawn) return 0;
    final result = game.result;
    if (result is WonGame) {
      return result.winner == player ? -Bishop.mateUpper : Bishop.mateUpper;
    }
    List<Move> moves = game.generateLegalMoves();
    if (moves.isEmpty) {
      if (game.turn == player) {
        return Bishop.mateUpper;
      } else {
        return -Bishop.mateUpper;
      }
    }
    // -evaluate because we are currently looking at this asthe other player
    if (depth == 0) return -game.evaluate(player);
    if (moves.isNotEmpty) {
      int a = alpha;
      for (Move m in moves) {
        game.makeMove(m, false);
        int v = -negamax(depth - 1, -beta, -a, player.opponent, debug - 1);
        game.undo();
        value = max(v, value);
        a = max(a, value);
        if (a >= beta) break;
      }
    }
    return value;
  }
}

class EngineResult {
  final Move? move;
  final int? eval;
  final int? depth;

  bool get hasMove => move != null;

  const EngineResult({this.move, this.eval, this.depth});
}
