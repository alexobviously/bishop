part of '../variant.dart';

abstract class const FirstMoveOptions() {
  PieceMoveChecker? build(BuiltVariant variant);

  factory pair(
    FirstMoveOptions? white,
    FirstMoveOptions? black,
  ) => FirstMoveOptionsPair(white, black);

  factory set(Map<String, FirstMoveOptions> set) => FirstMoveOptionsSet(set);

  factory ranks(List<int> white, List<int> black) => FirstMoveOptionsPair(
    RanksFirstMoveOptions(white),
    RanksFirstMoveOptions(black),
  );

  static const standard = InitialStateFirstMoveOptions();
}

class const FirstMoveOptionsPair(
  final FirstMoveOptions? white,
  final FirstMoveOptions? black,
) implements FirstMoveOptions {
  @override
  PieceMoveChecker? build(BuiltVariant variant) {
    final List<PieceMoveChecker?> built = [
      white?.build(variant),
      black?.build(variant),
    ];
    return (params) => built[params.colour]?.call(params) ?? false;
  }
}

class const FirstMoveOptionsSet(final Map<String, FirstMoveOptions> set)
    implements FirstMoveOptions {
  @override
  PieceMoveChecker build(BuiltVariant variant) {
    final Map<int, PieceMoveChecker?> builtSet = set.map(
      (k, v) => MapEntry(variant.pieceIndex(k), v.build(variant)),
    );
    return (params) => builtSet[params.piece.type]?.call(params) ?? false;
  }
}

class const RanksFirstMoveOptions(final List<int> ranks)
    implements FirstMoveOptions {
  @override
  PieceMoveChecker build(BuiltVariant variant) =>
      (params) => ranks.contains(params.size.rank(params.from));
}

class const InitialStateFirstMoveOptions() implements FirstMoveOptions {
  @override
  PieceMoveChecker build(BuiltVariant variant) =>
      (params) => params.piece.inInitialState;
}
