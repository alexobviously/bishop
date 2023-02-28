part of 'move.dart';

/// Contains move names.
class MoveMeta {
  /// Simple algebraic form, e.g. b1c3, e7e8q.
  final String algebraic;

  /// A formatted string representation of a move, specific to the variant's
  /// move formatting scheme. In most chess-related cases, this will likely
  /// be SAN, e.g. e5, Nxc7, b8=Q.
  final String formatted;

  const MoveMeta({
    required this.algebraic,
    required this.formatted,
  });
}
