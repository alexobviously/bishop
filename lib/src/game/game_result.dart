part of 'game.dart';

abstract class GameResult {
  const GameResult();

  /// A human-readable string describing the result.
  String get readable;

  /// 'Soft' results will not delegalise moves.
  /// This is useful for cases like points-based wins, where if the opponent
  /// is going to win next move no matter what, the current player should still
  /// be able to make a move.
  bool get soft => false;

  @override
  String toString() => 'GameResult';
}

/// A special case to propagate invalidation through to makeMove.
class InvalidMoveResult extends GameResult {
  const InvalidMoveResult();

  @override
  String toString() => 'InvalidMoveResult';

  @override
  String get readable => 'Invalid Move';
}

class WonGame extends GameResult {
  final int winner;
  const WonGame({required this.winner});

  @override
  String toString() => 'WonGame($winner)';

  @override
  String get readable => '${Bishop.playerName[winner]} won';
}

class DrawnGame extends GameResult {
  const DrawnGame();

  @override
  String toString() => 'DrawnGame';

  @override
  String get readable => 'Drawn';
}

class WonGameCheckmate extends WonGame {
  const WonGameCheckmate({required super.winner});

  @override
  String toString() => 'WonGameCheckmate($winner)';

  @override
  String get readable => '${super.readable} by checkmate';
}

class WonGameCheckLimit extends WonGame {
  final int numChecks;
  const WonGameCheckLimit({required super.winner, required this.numChecks});

  @override
  String toString() => 'WonGameCheckLimit($winner, $numChecks)';

  @override
  String get readable => '${super.readable} by checking $numChecks times';
}

class WonGameEnteredRegion extends WonGame {
  final int square;
  const WonGameEnteredRegion({required super.winner, required this.square});

  @override
  String toString() => 'WonGameEnteredRegion($winner, $square)';

  @override
  String get readable => '${super.readable} by entering region';
}

class WonGameExitedRegion extends WonGame {
  final int square;
  const WonGameExitedRegion({required super.winner, required this.square});

  @override
  String toString() => 'WonGameExitedRegion($winner, $square)';

  @override
  String get readable => '${super.readable} by exiting region';
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

  @override
  String get readable => '${super.readable} by elimination';
}

class WonGameStalemate extends WonGame {
  const WonGameStalemate({required super.winner});

  @override
  String toString() => 'WonGameStalemate($winner)';

  @override
  String get readable => '${super.readable} by stalemate';
}

class WonGamePoints extends WonGame {
  final int points;
  const WonGamePoints({required super.winner, required this.points});

  @override
  String toString() => 'WonGamePoints($winner, $points)';

  @override
  String get readable => '${super.readable} on points: $points';

  @override
  bool get soft => true;
}

class DrawnGameStalemate extends DrawnGame {
  const DrawnGameStalemate();

  @override
  String toString() => 'DrawnGameStalemate';

  @override
  String get readable => '${super.readable} by stalemate';
}

class DrawnGameInsufficientMaterial extends DrawnGame {
  const DrawnGameInsufficientMaterial();

  @override
  String toString() => 'DrawnGameInsufficientMaterial';

  @override
  String get readable => '${super.readable} by insufficient material';
}

class DrawnGameRepetition extends DrawnGame {
  final int repeats;
  const DrawnGameRepetition({required this.repeats});

  @override
  String toString() => 'DrawnGameRepetition($repeats)';

  @override
  String get readable => '${super.readable} by repetition';
}

class DrawnGameLength extends DrawnGame {
  final int halfMoves;
  const DrawnGameLength({required this.halfMoves});

  @override
  String toString() => 'DrawnGameLength($halfMoves)';

  @override
  String get readable => '${super.readable} by half move rule';
}

class DrawnGameBothRoyalsDead extends DrawnGame {
  const DrawnGameBothRoyalsDead();

  @override
  String toString() => 'DrawnGameBothRoyalsDead';

  @override
  String get readable => '${super.readable} by mutual destruction';
}

class DrawnGameElimination extends DrawnGame {
  const DrawnGameElimination();

  @override
  String toString() => 'DrawnGameElimination';

  @override
  String get readable => '${super.readable} by elimination';
}

class DrawnGamePoints extends DrawnGame {
  final int points;
  const DrawnGamePoints(this.points);

  @override
  String toString() => 'DrawnGamePoints($points)';

  @override
  String get readable => '${super.readable} on points: $points';
}

class DrawnGameEnteredRegion extends DrawnGame {
  final int player;
  final int square;
  const DrawnGameEnteredRegion({required this.player, required this.square});

  @override
  String toString() => 'DrawnGameEnteredRegion($square)';

  @override
  String get readable =>
      '${super.readable} by ${Bishop.playerName[player]} entering region';
}

class DrawnGameExitedRegion extends DrawnGame {
  final int player;
  final int square;
  const DrawnGameExitedRegion({required this.player, required this.square});

  @override
  String toString() => 'DrawnGameExitedRegion($square)';

  @override
  String get readable =>
      '${super.readable} by ${Bishop.playerName[player]} exiting region';
}
