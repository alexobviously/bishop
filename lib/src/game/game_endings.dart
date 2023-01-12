part of 'game.dart';

extension GameEndings on Game {
  /// Is the current player's king in check?
  bool get inCheck => kingAttacked(state.turn);

  /// Is this checkmate?
  bool get checkmate => inCheck && generateLegalMoves().isEmpty;

  bool get checkLimitMet =>
      variant.gameEndConditions.checkLimit != null &&
      state.checks[state.turn.opponent] >=
          variant.gameEndConditions.checkLimit!;

  GameResult? get result {
    if (state.result != null) return state.result;
    if (checkmate) return WonGameCheckmate(winner: state.turn.opponent);
    if (checkLimitMet) {
      return WonGameCheckLimit(
        winner: state.turn.opponent,
        numChecks: state.checks[state.turn.opponent],
      );
    }
    if (stalemate) return DrawnGameStalemate();
    if (insufficientMaterial) return DrawnGameInsufficientMaterial();
    if (repetition) return DrawnGameRepetition(repeats: hashHits);
    if (halfMoveRule) return DrawnGameLength(halfMoves: state.halfMoves);
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

  /// True if the game has ended in any way. See `result` for how it ended.
  bool get gameOver => result != null;
}
