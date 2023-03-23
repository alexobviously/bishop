part of '../variant.dart';

abstract class FirstMoveOptions {
  const FirstMoveOptions();

  PieceMoveChecker? build(BuiltVariant variant);

  factory FirstMoveOptions.pair(
    FirstMoveOptions? white,
    FirstMoveOptions? black,
  ) =>
      FirstMoveOptionsPair(white, black);

  factory FirstMoveOptions.set(Map<String, FirstMoveOptions> set) =>
      FirstMoveOptionsSet(set);

  factory FirstMoveOptions.ranks(List<int> white, List<int> black) =>
      FirstMoveOptionsPair(
        RanksFirstMoveOptions(white),
        RanksFirstMoveOptions(black),
      );
}

class NoFirstMoveOptions implements FirstMoveOptions {
  const NoFirstMoveOptions();

  @override
  PieceMoveChecker? build(BuiltVariant variant) => null;
}

class FirstMoveOptionsPair implements FirstMoveOptions {
  final FirstMoveOptions? white;
  final FirstMoveOptions? black;

  const FirstMoveOptionsPair(this.white, this.black);

  @override
  PieceMoveChecker? build(BuiltVariant variant) {
    final List<PieceMoveChecker?> built = [
      white?.build(variant),
      black?.build(variant),
    ];
    return (params) => built[params.colour]?.call(params) ?? false;
  }
}

class FirstMoveOptionsSet implements FirstMoveOptions {
  final Map<String, FirstMoveOptions> set;
  const FirstMoveOptionsSet(this.set);

  @override
  PieceMoveChecker build(BuiltVariant variant) {
    final Map<int, PieceMoveChecker?> builtSet =
        set.map((k, v) => MapEntry(variant.pieceIndex(k), v.build(variant)));
    return (params) => builtSet[params.piece.type]?.call(params) ?? false;
  }
}

class RanksFirstMoveOptions implements FirstMoveOptions {
  final List<int> ranks;
  const RanksFirstMoveOptions(this.ranks);

  @override
  PieceMoveChecker build(BuiltVariant variant) =>
      (params) => ranks.contains(params.size.rank(params.from));
}

class InitialStateFirstMoveOptions implements FirstMoveOptions {
  @override
  PieceMoveChecker build(BuiltVariant variant) =>
      (params) => params.piece.inInitialState;
}
