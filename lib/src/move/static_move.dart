part of 'move.dart';

/// A move that starts and ends on the same square.
/// This doesn't have any default implementation in the engine; it is intended
/// for use in games that have a special move that doesn't move a piece, with
/// its own move processor.
class StaticMove extends Move {
  final int square;

  @override
  int get from => square;

  @override
  int get to => square;

  const StaticMove(this.square);

  String algebraic({BoardSize size = BoardSize.standard}) {
    String fromStr = size.squareName(from);
    String toStr = size.squareName(to);
    return '$fromStr$toStr';
  }
}
