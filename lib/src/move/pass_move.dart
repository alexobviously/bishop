part of 'move.dart';

/// A move that simply passes the turn for the active player.
class PassMove extends Move {
  @override
  int get from => Bishop.invalid;
  @override
  int get to => Bishop.invalid;

  const PassMove();

  String algebraic() => 'pass';
}
