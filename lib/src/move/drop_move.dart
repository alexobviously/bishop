part of 'move.dart';

/// A move where a piece is dropped from the player's hand onto the board.
/// This is only for hand drops, not gating moves, which are currently still
/// part of `StandardMove`.
class const DropMove({
  @override required final int to,
  required final int piece,
}) extends Move {
  @override
  bool get handDrop => true;
  @override
  int get from => Bishop.hand;

  @override
  int get dropPiece => piece;

  String algebraic(BoardSize size) => '@${size.squareName(to)}';
}
