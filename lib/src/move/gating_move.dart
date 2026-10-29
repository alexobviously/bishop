part of 'move.dart';

/// A move that involves a piece being moved out of the player's gate, and
/// onto the player's first rank.
class const GatingMove({
  required super.child,
  @override required final int dropPiece,

  /// For gating drops that are also castling moves - should we gate on square
  /// that the king came from (false) or the rook (true).
  final bool dropOnRookSquare = false,
}) extends WrapperMove {

  @override
  bool get gate => true;
}
