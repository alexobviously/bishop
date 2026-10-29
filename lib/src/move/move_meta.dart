part of 'move.dart';

/// Contains move names.
class const MoveMeta({
  /// Simple algebraic form, e.g. b1c3, e7e8q.
  required final String algebraic,

  /// A formatted string representation of a move, specific to the variant's
  /// move formatting scheme. In most chess-related cases, this will likely
  /// be SAN, e.g. e5, Nxc7, b8=Q.
  required final String formatted,
});
