part of 'state.dart';

class const StateMeta({
  required final BuiltVariant variant,
  final MoveMeta? moveMeta,
  final List<Iterable<int>>? checks,
}) {
  String? get algebraic => moveMeta?.algebraic;
  String? get prettyName => moveMeta?.formatted;
  List<bool?> get inCheck =>
      checks?.map((e) => e.isNotEmpty).toList() ?? [null, null];
}
