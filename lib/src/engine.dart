import 'dart:math';

import 'package:bishop/bishop.dart';

/// The bound type for an entry in the [TranspositionTable].
enum TTBound {
  /// The minimax evaluation is exact (alpha < eval < beta).
  exact,

  /// A beta-cutoff occurred; the true score is at least this value (eval >= beta).
  lowerBound,

  /// A fail-low occurred; the true score is at most this value (eval <= alpha).
  upperBound,
}

/// An entry in the [TranspositionTable].
class const TTEntry({
  required final int hash,
  required final int depth,
  required final int value,
  required final TTBound bound,
  final Move? bestMove,
  final int age = 0,
});

/// A fixed-size transposition table using Zobrist hashing to cache evaluations,
/// avoid re-searching identical subtrees, and order best moves first.
class TranspositionTable {
  static const int defaultSize =
      1 << 20; // 1,048,576 entries (~64 MB when saturated)

  final int size;
  final int mask;
  final List<TTEntry?> _table;
  int age = 0;

  TranspositionTable({int size = defaultSize})
    : size = _nextPowerOf2(size),
      mask = _nextPowerOf2(size) - 1,
      _table = List<TTEntry?>.filled(_nextPowerOf2(size), null);

  static int _nextPowerOf2(int n) {
    if (n <= 1) return 1;
    int p = 1;
    while (p < n) {
      p <<= 1;
    }
    return p;
  }

  /// Increments search age for the new search iteration, allowing older entries
  /// to be safely replaced.
  void newSearch() {
    age++;
  }

  /// Clears all entries in the table and resets the age counter.
  void clear() {
    _table.fillRange(0, _table.length, null);
    age = 0;
  }

  /// Looks up a cached entry matching [hash].
  TTEntry? get(int hash) {
    final entry = _table[hash & mask];
    if (entry != null && entry.hash == hash) {
      return entry;
    }
    return null;
  }

  /// Inserts or updates an entry in the table using a depth-preferred with aging scheme.
  void set({
    required int hash,
    required int depth,
    required int value,
    required TTBound bound,
    Move? bestMove,
  }) {
    final idx = hash & mask;
    final existing = _table[idx];
    if (existing == null || existing.age != age || depth >= existing.depth) {
      _table[idx] = TTEntry(
        hash: hash,
        depth: depth,
        value: value,
        bound: bound,
        bestMove: bestMove ?? existing?.bestMove,
        age: age,
      );
    } else if (bestMove != null && existing.bestMove == null) {
      _table[idx] = TTEntry(
        hash: existing.hash,
        depth: existing.depth,
        value: existing.value,
        bound: existing.bound,
        bestMove: bestMove,
        age: existing.age,
      );
    }
  }
}

class Engine({
  required var Game game,
  TranspositionTable? tt,
}) {
  final TranspositionTable tt = tt ?? TranspositionTable();

  /// Maximum search ply supported for heuristics like killer moves.
  static const int maxPly = 64;

  /// Killer moves table: stores up to two quiet moves per ply that caused a beta cutoff.
  final List<List<Move?>> _killers = List.generate(maxPly, (_) => [null, null]);

  /// Returns the killer moves stored for [ply].
  List<Move?> killersFor(int ply) => ply >= 0 && ply < maxPly
      ? List.unmodifiable(_killers[ply])
      : const [null, null];

  /// Clears all entries in the killer moves table.
  void clearKillers() {
    for (int i = 0; i < maxPly; i++) {
      _killers[i][0] = null;
      _killers[i][1] = null;
    }
  }

  /// Records [move] as a killer move at [ply].
  void storeKiller(int ply, Move move) {
    if (ply < 0 || ply >= maxPly) return;
    if (_killers[ply][0] != move) {
      _killers[ply][1] = _killers[ply][0];
      _killers[ply][0] = move;
    }
  }

  Future<EngineResult> search({
    int maxDepth = 50,
    int timeLimit = 5000,
    int timeBuffer = 2000,
    int debug = 0,
    int printBest = 0,
    bool clearTable = false,
  }) async {
    if (game.gameOver) {
      print(game.drawn ? 'Draw' : 'Checkmate');
      return const EngineResult();
    }
    if (clearTable) tt.clear();
    clearKillers();
    tt.newSearch();

    int endTime = DateTime.now().millisecondsSinceEpoch + timeLimit;
    int endBuffer = endTime + timeBuffer;
    int depthSearched = 0;

    final rootHash = game.state.hash;
    final rootEntry = tt.get(rootHash);
    List<Move> moves = orderMoves(
      game.generateLegalMoves(),
      rootEntry?.bestMove,
    );

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
          1,
          debug,
        );
        game.undo();
        evals[m] = eval;
        int now = DateTime.now().millisecondsSinceEpoch;
        if (now >= endBuffer) break;
      }
      moves.sort((a, b) => evals[b]!.compareTo(evals[a]!));
      depthSearched = depth;

      // Store root position in TT
      tt.set(
        hash: rootHash,
        depth: depth,
        value: evals[moves.first]!,
        bound: .exact,
        bestMove: moves.first,
      );

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

  int negamax(
    int depth,
    int alpha,
    int beta,
    Colour player, [
    int ply = 0,
    int debug = 0,
  ]) {
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

    final hash = game.state.hash;
    final ttEntry = tt.get(hash);

    // 1. TT Cutoff
    if (ttEntry != null && ttEntry.depth >= depth) {
      final isCutoff = switch (ttEntry.bound) {
        .exact => true,
        .lowerBound => ttEntry.value >= beta,
        .upperBound => ttEntry.value <= alpha,
      };
      if (isCutoff) return ttEntry.value;
    }

    if (depth == 0) return quiescence(alpha, beta, player);

    // 2. Move Ordering using TT bestMove and Killer Moves
    final hashMove = ttEntry?.bestMove;
    moves = orderMoves(moves, hashMove, ply);

    int value = -Bishop.mateUpper;
    int a = alpha;
    Move? bestMove;

    for (Move m in moves) {
      game.makeMove(m, false);
      int v = -negamax(
        depth - 1,
        -beta,
        -a,
        player.opponent,
        ply + 1,
        debug - 1,
      );
      game.undo();

      if (v > value) {
        value = v;
        bestMove = m;
      }
      a = max(a, value);
      if (a >= beta) {
        // Beta cutoff occurred: record quiet killer move
        if (!m.capture && ply < maxPly) {
          storeKiller(ply, m);
        }
        break;
      }
    }

    // 3. Store in TT
    final TTBound bound = switch (value) {
      _ when value >= beta => .lowerBound,
      _ when value <= alpha => .upperBound,
      _ => .exact,
    };

    tt.set(
      hash: hash,
      depth: depth,
      value: value,
      bound: bound,
      bestMove: bestMove,
    );

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
  /// The transposition table move [hashMove] is prioritized above all others,
  /// followed by MVV-LVA captures, killer moves, promotions, and castling.
  int scoreMove(Move move, [Move? hashMove, int ply = 0]) {
    if (hashMove != null && move == hashMove) {
      return 100000;
    }

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
    } else if (ply < maxPly) {
      if (move == _killers[ply][0]) {
        score += 9000;
      } else if (move == _killers[ply][1]) {
        score += 8000;
      }
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
  List<Move> orderMoves(List<Move> moves, [Move? hashMove, int ply = 0]) {
    if (moves.length <= 1) return moves;
    final scored = [for (final m in moves) (m, scoreMove(m, hashMove, ply))];
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored) s.$1];
  }
}

class const EngineResult({
  final Move? move,
  final int? eval,
  final int? depth,
}) {
  bool get hasMove => move != null;
}
