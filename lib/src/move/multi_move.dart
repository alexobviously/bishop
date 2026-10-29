part of 'move.dart';

/// A move that consists of multiple steps.
/// Not yet fully implemented.
class const MultiMove({
  required final List<Move> moves,
}) extends Move {

  @override
  int get from => moves.first.from;

  @override
  int get to => moves.last.to;
}
