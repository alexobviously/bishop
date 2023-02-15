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

  /// Optionally, specify a colour for the dropped piece.
  /// If this is null, the colour of the player whose turn it is will be used.
  final int? colour;

  /// Set this to true if you are allowing a drop of a piece that isn't in
  /// play before this move.
  /// If not true, the piece count in the game state won't be increased.
  final bool newPiece;

  @override
  int get dropPiece => piece;

  const DropMove({
    required this.to,
    required this.piece,
    this.colour,
    this.newPiece = false,
  });

  String algebraic(BoardSize size) => '@${size.squareName(to)}';
}
