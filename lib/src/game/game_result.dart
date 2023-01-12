part of 'game.dart';

abstract class GameResult {
  const GameResult();
}

class WonGame extends GameResult {
  final int winner;
  const WonGame({required this.winner});
}

class DrawnGame extends GameResult {
  const DrawnGame();
}

class WonGameCheckmate extends WonGame {
  const WonGameCheckmate({required super.winner});
}

class WonGameCheckLimit extends WonGame {
  final int numChecks;
  const WonGameCheckLimit({required super.winner, required this.numChecks});
}

class WonGameEnteredRegion extends WonGame {
  final int square;
  const WonGameEnteredRegion({required super.winner, required this.square});
}

class DrawnGameStalemate extends DrawnGame {
  const DrawnGameStalemate();
}

class DrawnGameInsufficientMaterial extends DrawnGame {
  const DrawnGameInsufficientMaterial();
}

class DrawnGameRepetition extends DrawnGame {
  final int repeats;
  const DrawnGameRepetition({required this.repeats});
}

class DrawnGameLength extends DrawnGame {
  final int halfMoves;
  const DrawnGameLength({required this.halfMoves});
}
