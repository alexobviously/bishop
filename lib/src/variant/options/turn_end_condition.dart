part of '../variant.dart';

typedef TurnEndFunction = bool Function(
  BishopState state,
  int move,
  int part,
  int player,
);

abstract class TurnEndCondition {
  const TurnEndCondition();

  TurnEndFunction build(BuiltVariant variant);

  static const doubleMove = TurnEndMoveCount(2);
  static const marseillais = TurnEndMoveCount(2, firstMoveCount: 1);
  static const progressive = TurnEndIncrementingMoveCount();
  static const check = TurnEndCheck();
}

class TurnEndAnd extends TurnEndCondition {
  final List<TurnEndCondition> conditions;

  const TurnEndAnd(this.conditions);

  @override
  TurnEndFunction build(BuiltVariant variant) {
    final functions = conditions.map((c) => c.build(variant)).toList();
    return (state, move, part, player) =>
        functions.every((f) => f(state, move, part, player));
  }
}

class TurnEndOr extends TurnEndCondition {
  final List<TurnEndCondition> conditions;

  const TurnEndOr(this.conditions);

  @override
  TurnEndFunction build(BuiltVariant variant) {
    final functions = conditions.map((c) => c.build(variant)).toList();
    return (state, move, part, player) =>
        functions.any((f) => f(state, move, part, player));
  }
}

class TurnEndMoveCount extends TurnEndCondition {
  final int count;
  final int? firstMoveCount;

  const TurnEndMoveCount(this.count, {this.firstMoveCount});

  @override
  TurnEndFunction build(BuiltVariant variant) => switch (firstMoveCount) {
        int first => (_, move, part, __) =>
            part >= (move == 0 ? (first - 1) : (count - 1)),
        null => (_, __, part, ___) => part >= count - 1,
      };
}

class TurnEndIncrementingMoveCount extends TurnEndCondition {
  final int initial;
  final int increment;

  const TurnEndIncrementingMoveCount({this.initial = 1, this.increment = 1});

  @override
  TurnEndFunction build(BuiltVariant variant) =>
      (_, move, part, __) => part >= (initial + increment * move);
}

class TurnEndCheck extends TurnEndCondition {
  const TurnEndCheck();

  @override
  TurnEndFunction build(BuiltVariant variant) =>
      (state, _, __, player) => state.meta?.inCheck[1 - player] ?? false;
}
