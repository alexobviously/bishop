part of 'state.dart';

class StateMeta {
  final BuiltVariant variant;
  final MoveMeta? moveMeta;
  final List<Iterable<int>>? checks;

  const StateMeta({
    required this.variant,
    this.moveMeta,
    this.checks,
  });

  String? get algebraic => moveMeta?.algebraic;
  String? get prettyName => moveMeta?.formatted;
  List<bool?> get inCheck =>
      checks?.map((e) => e.isNotEmpty).toList() ?? [null, null];
}
