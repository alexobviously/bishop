part of 'move.dart';

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
