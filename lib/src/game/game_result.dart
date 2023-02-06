part of 'game.dart';

abstract class GameResult {
  const GameResult();

  @override
  String toString() => 'GameResult';
}

/// A special case to propagate invalidation through to makeMove.
class InvalidMoveResult extends GameResult {
  const InvalidMoveResult();

  @override
  String toString() => 'InvalidMoveResult';
}

class WonGame extends GameResult {
  final int winner;
  const WonGame({required this.winner});

  @override
  String toString() => 'WonGame($winner)';
}

class DrawnGame extends GameResult {
  const DrawnGame();

  @override
  String toString() => 'DrawnGame';
}

class WonGameCheckmate extends WonGame {
  const WonGameCheckmate({required super.winner});

  @override
  String toString() => 'WonGameCheckmate($winner)';
}

class WonGameCheckLimit extends WonGame {
  final int numChecks;
  const WonGameCheckLimit({required super.winner, required this.numChecks});

  @override
  String toString() => 'WonGameCheckLimit($winner, $numChecks)';
}

class WonGameEnteredRegion extends WonGame {
  final int square;
  const WonGameEnteredRegion({required super.winner, required this.square});

  @override
  String toString() => 'WonGameEnteredRegion($winner, $square)';
}

class WonGameRoyalDead extends WonGame {
  const WonGameRoyalDead({required super.winner});

  @override
  String toString() => 'WonGameRoyalDead($winner)';
}

class WonGameElimination extends WonGame {
  const WonGameElimination({required super.winner});

  @override
  String toString() => 'WonGameElimination($winner)';
}

class WonGameStalemate extends WonGame {
  const WonGameStalemate({required super.winner});

  @override
  String toString() => 'WonGameStalemate($winner)';
}

class DrawnGameStalemate extends DrawnGame {
  const DrawnGameStalemate();

  @override
  String toString() => 'DrawnGameStalemate';
}

class DrawnGameInsufficientMaterial extends DrawnGame {
  const DrawnGameInsufficientMaterial();

  @override
  String toString() => 'DrawnGameInsufficientMaterial';
}

class DrawnGameRepetition extends DrawnGame {
  final int repeats;
  const DrawnGameRepetition({required this.repeats});

  @override
  String toString() => 'DrawnGameRepetition($repeats)';
}

class DrawnGameLength extends DrawnGame {
  final int halfMoves;
  const DrawnGameLength({required this.halfMoves});

  @override
  String toString() => 'DrawnGameLength($halfMoves)';
}

class DrawnGameBothRoyalsDead extends DrawnGame {
  const DrawnGameBothRoyalsDead();

  @override
  String toString() => 'DrawnGameBothRoyalsDead';
}

class DrawnGameElimination extends DrawnGame {
  const DrawnGameElimination();

  @override
  String toString() => 'DrawnGameElimination';
}
