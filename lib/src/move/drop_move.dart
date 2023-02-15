part of 'move.dart';

/// A move where a piece is dropped from the player's hand onto the board.
/// This is only for hand drops, not gating moves, which are currently still
/// part of `StandardMove`.
class DropMove extends Move {
  @override
  bool get handDrop => true;
  @override
  int get from => Bishop.hand;
  @override
  final int to;
  final int piece;

  @override
  int get dropPiece => piece;

  const DropMove({required this.to, required this.piece});

  String algebraic(BoardSize size) => '@${size.squareName(to)}';
}
