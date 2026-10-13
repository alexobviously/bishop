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
    List<Move> moves = orderMoves(game.generateLegalMoves());
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
    if (depth == 0) return quiescence(alpha, beta, player);
    moves = orderMoves(moves);
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

  /// Quiescence search evaluates only tactical moves (captures, check evasions)
  /// beyond the horizon depth to avoid the "horizon effect".
  int quiescence(
    int alpha,
    int beta,
    Colour player, [
    int maxQDepth = 6,
  ]) {
    if (game.drawn) return 0;
    final result = game.result;
    if (result is WonGame) {
      return result.winner == player ? -Bishop.mateUpper : Bishop.mateUpper;
    }

    final inCheck = game.inCheck;
    int a = alpha;

    // Standing pat is allowed only when not in check:
    if (!inCheck) {
      final standPat = -game.evaluate(player);
      if (standPat >= beta) return beta;
      if (standPat > a) a = standPat;
    }

    if (maxQDepth <= 0) return a;

    // Search all evasions if in check; otherwise only captures:
    List<Move> moves = inCheck
        ? game.generateLegalMoves()
        : game.generatePlayerMoves(game.turn, MoveGenParams.onlyCaptures);

    if (moves.isEmpty) {
      if (inCheck) {
        return game.turn == player ? Bishop.mateUpper : -Bishop.mateUpper;
      }
      return a;
    }

    moves = orderMoves(moves);

    for (Move m in moves) {
      game.makeMove(m, false);
      int score = -quiescence(-beta, -a, player.opponent, maxQDepth - 1);
      game.undo();

      if (score >= beta) return beta;
      if (score > a) a = score;
    }

    return a;
  }

  /// Assigns a heuristic score to [move] for move ordering.
  /// Captures are prioritized using MVV-LVA (Most Valuable Victim - Least Valuable Attacker),
  /// followed by promotions and castling.
  int scoreMove(Move move) {
    int score = 0;
    if (move.capture) {
      final victimValue = switch (move) {
        Move(:final capturedPiece?)
            when capturedPiece.type < game.variant.pieces.length =>
          game.variant.pieces[capturedPiece.type].value,
        Move(enPassant: true) => 100,
        _ => Bishop.defaultPieceValue,
      };

      final attackerValue = switch (move) {
        Move(:final from)
            when from >= Bishop.boardStart &&
                from < game.board.length &&
                game.board[from].type < game.variant.pieces.length =>
          game.variant.pieces[game.board[from].type].value,
        _ => Bishop.defaultPieceValue,
      };

      // MVV-LVA: Most Valuable Victim - Least Valuable Attacker
      score += 10000 + (victimValue * 10) - (attackerValue ~/ 10);
    }

    if (move.promotion) {
      int promoValue = 800;
      if (move.promoPiece != null &&
          move.promoPiece! < game.variant.pieces.length) {
        promoValue = game.variant.pieces[move.promoPiece!].value;
      }
      score += 8000 + promoValue;
    }

    if (move.castling) {
      score += 500;
    }

    return score;
  }

  /// Orders [moves] using [scoreMove] to improve alpha-beta pruning efficiency.
  List<Move> orderMoves(List<Move> moves) {
    if (moves.length <= 1) return moves;
    final scored = [for (final m in moves) (m, scoreMove(m))];
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored) s.$1];
  }
}

class EngineResult {
  final Move? move;
  final int? eval;
  final int? depth;

  bool get hasMove => move != null;

  const EngineResult({this.move, this.eval, this.depth});
}
