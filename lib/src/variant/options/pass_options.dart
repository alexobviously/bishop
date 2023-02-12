part of '../variant.dart';

abstract class PassOptions {
  const PassOptions();

  MoveChecker? build(BuiltVariant variant);

  static const PassOptions none = NoPass();
  static const PassOptions standard = StandardPass();
}

/// Never generates a pass move.
class NoPass implements PassOptions {
  const NoPass();
  @override
  MoveChecker? build(BuiltVariant variant) => null;
}

/// Always generates a pass move.
class StandardPass implements PassOptions {
  const StandardPass();
  @override
  MoveChecker build(BuiltVariant variant) => (_) => true;
}
