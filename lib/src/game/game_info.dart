// A convenience class for use with other packages (e.g. Squares)
part of 'game.dart';

class GameInfo {
  final Move? lastMove;
  final String? lastFrom;
  final String? lastTo;
  final String? checkSq;

  const GameInfo({
    this.lastMove,
    this.lastFrom,
    this.lastTo,
    this.checkSq,
  });
}
