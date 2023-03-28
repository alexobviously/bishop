part of 'move.dart';

/// A move that involves a piece being moved out of the player's gate, and
/// onto the player's first rank.
class GatingMove extends WrapperMove {
  @override
  final int dropPiece;

  /// For gating drops that are also castling moves - should we gate on square
  /// that the king came from (false) or the rook (true).
  final bool dropOnRookSquare;

  const GatingMove({
    required super.child,
    required this.dropPiece,
    this.dropOnRookSquare = false,
  });

  @override
  bool get gate => true;
}
