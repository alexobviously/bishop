part of 'variant.dart';

class GameEndConditionSet {
  final GameEndConditions white;
  final GameEndConditions black;

  const GameEndConditionSet(this.white, this.black);

  factory GameEndConditionSet.symmetric(GameEndConditions conditions) =>
      GameEndConditionSet(conditions, conditions);

  static const standard = GameEndConditionSet(
    GameEndConditions.standard,
    GameEndConditions.standard,
  );

  static const threeCheck = GameEndConditionSet(
    GameEndConditions.threeCheck,
    GameEndConditions.threeCheck,
  );

  static const horde = GameEndConditionSet(
    GameEndConditions.standard,
    GameEndConditions(elimination: true),
  );

  bool get hasCheckLimit =>
      white.checkLimit != null || black.checkLimit != null;

  GameEndConditions operator [](int index) {
    if (index == Bishop.white) return white;
    if (index == Bishop.black) return black;
    throw RangeError('index can only be 0 or 1');
  }
}

class GameEndConditions {
  /// If true, when this player has no legal moves the game will be stalemate.
  /// If false, it will be a loss for them.
  final bool stalemate;

  /// If true, this player loses when they have no pieces on the board.
  final bool elimination;

  /// If not null, this player can lose by being checked this many times.
  final int? checkLimit;

  const GameEndConditions({
    this.stalemate = true,
    this.elimination = true,
    this.checkLimit,
  });

  static const GameEndConditions standard = GameEndConditions();
  static const GameEndConditions threeCheck = GameEndConditions(checkLimit: 3);

  @override
  String toString() => 'GameEndConditions(checkLimit: $checkLimit)';
}

// TODO: make it possible for white and black to have separate conditions.
// TODO: implement 'total elimination' condition, for horde chess.