part of 'move.dart';

class PassMove extends Move {
  @override
  int get from => Bishop.invalid;
  @override
  int get to => Bishop.invalid;

  const PassMove();

  String algebraic() => 'pass';
}
