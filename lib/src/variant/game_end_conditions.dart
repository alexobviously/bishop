part of 'variant.dart';

class GameEndConditions {
  final int? checkLimit;

  const GameEndConditions({this.checkLimit});

  static const GameEndConditions standard = GameEndConditions();
  static const GameEndConditions threeCheck = GameEndConditions(checkLimit: 3);

  @override
  String toString() => 'GameEndConditions(checkLimit: $checkLimit)';
}

// TODO: make it possible for white and black to have separate conditions.
// TODO: implement 'total elimination' condition, for horde chess.