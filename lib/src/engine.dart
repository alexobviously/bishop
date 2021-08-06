import 'dart:math';

import 'package:bishop/bishop.dart';

class Engine {
  final Game game;

  Engine({required this.game});

  Future<EngineResult> search(
      {int maxDepth = 50, int timeLimit = 5000, int timeBuffer = 2000, int debug = 0, int printBest = 0}) async {
    if (game.gameOver) {
      print(game.inDraw ? 'Draw' : 'Checkmate');
      return EngineResult();
    }
    int now = DateTime.now().millisecondsSinceEpoch;
    int endTime = now + timeLimit;
    int endBuffer = endTime + timeBuffer;
    int depthSearched = 0;
    List<Move> moves = game.generateLegalMoves();
    Map<Move, int> evals = {};
    moves.forEach((m) => evals[m] = 0);
    for (int depth = 1; depth < maxDepth; depth++) {
      if (debug > 0) print('----- DEPTH $depth -----');
      for (Move m in moves) {
        game.makeMove(m);
        int eval = -negamax(
          depth,
          -MATE_UPPER,
          MATE_UPPER,
          game.turn.opponent,
          debug,
        );
        game.undo();
        evals[m] = eval;
        int _now = DateTime.now().millisecondsSinceEpoch;
        if (_now >= endBuffer) break;
      }
      moves.sort((a, b) => evals[b]!.compareTo(evals[a]!));
      depthSearched = depth;
      int _now = DateTime.now().millisecondsSinceEpoch;
      if (_now >= endTime) break;
    }
    if (printBest > 0) {
      print('-- Best Moves --');
      for (Move m in moves.take(printBest)) {
        print('${game.toSan(m)}: ${evals[m]}');
      }
    }

    return EngineResult(move: moves.first, eval: evals[moves.first], depth: depthSearched);
  }

  int negamax(int depth, int alpha, int beta, Colour player, [int debug = 0]) {
    int value = -MATE_UPPER;
    List<Move> moves = game.generateLegalMoves();
    if (moves.isEmpty) {
      if (game.inDraw) {
        return 0;
      } else if (game.turn == player) {
        return -MATE_UPPER;
      } else {
        return MATE_UPPER;
      }
    }
    // -evaluate because we are currently looking at this asthe other player
    if (depth == 0) return -game.evaluate(player);
    if (moves.isNotEmpty) {
      int a = alpha;
      for (Move m in moves) {
        int _debug = debug - 1;
        game.makeMove(m);
        int v = -negamax(depth - 1, -beta, -a, player.opponent, _debug);
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

  EngineResult({this.move, this.eval, this.depth});
}
