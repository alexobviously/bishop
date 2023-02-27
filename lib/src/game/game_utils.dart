part of 'game.dart';

extension GameUtils on Game {
  /// Performs a [divide perft test](https://www.chessprogramming.org/Perft#Divide), to [depth].
  Map<String, int> divide(int depth) {
    List<Move> moves = generateLegalMoves();
    Map<String, int> perfts = {};
    for (Move m in moves) {
      makeMove(m, false);
      perfts[toAlgebraic(m)] = perft(depth - 1);
      undo();
    }
    return perfts;
  }

  /// Returns a naive material evaluation of the current position, from the perspective of [player].
  /// Return value is in [centipawns](https://www.chessprogramming.org/Centipawns).
  /// For example, if white has captured a rook from black with no compensation, this will return +500.
  int evaluate(Colour player) {
    int eval = 0;
    for (int i = 0; i < size.numIndices; i++) {
      if (!size.onBoard(i)) continue;
      Square square = board[i];
      if (square.isNotEmpty) {
        Colour colour = square.colour;
        int type = square.type;
        int value = variant.pieces[type].value;
        if (colour == player) {
          eval += value;
        } else {
          eval -= value;
        }
      }
    }
    return eval;
  }
}
