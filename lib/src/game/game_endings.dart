part of 'game.dart';

extension GameEndings on Game {
  /// Is the current player's king in check?
  bool get inCheck => kingAttacked(state.turn);

  /// Is this checkmate?
  bool get checkmate => inCheck && generateLegalMoves().isEmpty;

  bool get checkLimitMet =>
      variant.gameEndConditions[state.turn.opponent].checkLimit != null &&
      state.checks[state.turn.opponent] >=
          variant.gameEndConditions[state.turn.opponent].checkLimit!;

  bool get eliminated => state.pieceCount(state.turn) < 1;

  /// The result of the game. If null, the game has not ended yet.
  GameResult? get result {
    if (state.result != null) return state.result;
    if (checkmate) return WonGameCheckmate(winner: state.turn.opponent);
    if (checkLimitMet) {
      return WonGameCheckLimit(
        winner: state.turn.opponent,
        numChecks: state.checks[state.turn.opponent],
      );
    }
    final elimCond = variant.gameEndConditions[state.turn].elimination;
    if (elimCond.isNotNone) {
      if (eliminated) {
        if (elimCond.isDraw) return DrawnGameElimination();
        return WonGameElimination(
          winner: elimCond.isWin ? state.turn : state.turn.opponent,
        );
      }
    }
    final stalemateCond = variant.gameEndConditions[state.turn].stalemate;
    if (stalemateCond.isNotNone && stalemate) {
      return stalemateCond.isDraw
          ? DrawnGameStalemate()
          : WonGameStalemate(
              winner: stalemateCond.isWin ? state.turn : state.turn.opponent,
            );
    }
    if (insufficientMaterial) return DrawnGameInsufficientMaterial();
    if (repetition) return DrawnGameRepetition(repeats: hashHits);
    if (halfMoveRule) return DrawnGameLength(halfMoves: state.halfMoves);
    return null;
  }

  /// Returns the player who won the game, or null if the game is drawn or ongoing.
  int? get winner {
    final r = result;
    if (r is WonGame) return r.winner;
    return null;
  }

  /// Returns true if the royal pieces for each player are on the same file,
  /// e.g. Xiangqi's flying generals rule.
  bool get royalsFacing => size.squaresOnSameFile(
        state.royalSquares[Bishop.white],
        state.royalSquares[Bishop.black],
      );

  /// Is this stalemate?
  bool get stalemate => !inCheck && generateLegalMoves().isEmpty;

  /// Check if there is currently sufficient material on the board for one player
  /// to mate the other.
  /// Returns true if there *isn't* sufficient material (and therefore it's a draw).
  bool get insufficientMaterial {
    if (!variant.materialConditions.enabled) return false;
    if (hasSufficientMaterial(Bishop.white)) return false;
    return !hasSufficientMaterial(Bishop.black);
  }

  /// Determines whether there is sufficient material for [player] to deliver
  /// mate in the board position specified in [state].
  /// [state] defaults to the current board state if unspecified.
  bool hasSufficientMaterial(Colour player, {BishopState? state}) {
    BishopState newState = state ?? this.state;
    for (int p in variant.materialConditions.soloMaters) {
      if (newState.pieces[makePiece(p, player)] > 0) return true;
    }
    // TODO: figure out how to track square colours to check bishop pairs
    for (int p in variant.materialConditions.pairMaters) {
      if (newState.pieces[makePiece(p, player)] > 1) return true;
    }
    for (int p in variant.materialConditions.combinedPairMaters) {
      if (newState.pieces[makePiece(p, player)] +
              newState.pieces[makePiece(p, player.opponent)] >
          1) {
        return true;
      }
    }
    for (List<int> c in variant.materialConditions.specialCases) {
      bool met = true;
      for (int p in c) {
        if (newState.pieces[makePiece(p, player)] < 1) met = false;
      }
      if (met) return true;
    }
    return false;
  }

  /// Check if we have reached the repetition draw limit (threefold repetition
  /// in standard chess).
  /// Configurable in [Variant.repetitionDraw].
  bool get repetition => variant.repetitionDraw != null
      ? hashHits >= variant.repetitionDraw!
      : false;

  /// Check if we have reached the half move rule (aka the 50 move rule in
  /// standard chess).
  /// Configurable in [variant.halfMoveDraw].
  bool get halfMoveRule =>
      variant.halfMoveDraw != null && state.halfMoves >= variant.halfMoveDraw!;

  /// True if the game state is any kind of draw.
  @Deprecated('Use `drawn`')
  bool get inDraw => drawn;

  /// True if the game state is any kind of draw.
  bool get drawn => result is DrawnGame;

  /// True if the game state is any kind of win/loss.
  bool get won => result is WonGame;

  bool wonBy(int colour) =>
      (state.result is WonGame && (state.result as WonGame).winner == colour);

  bool lostBy(int colour) =>
      (state.result is WonGame && (state.result as WonGame).winner != colour);

  /// True if the game has ended in any way. See `result` for how it ended.
  bool get gameOver => result != null;
}
