part of 'move.dart';

/// A move that consists of multiple steps.
/// Not yet fully implemented.
class MultiMove extends Move {
  final List<Move> moves;
  const MultiMove({required this.moves});

  @override
  int get from => moves.first.from;

  @override
  int get to => moves.last.to;
}
