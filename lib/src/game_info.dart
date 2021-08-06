// A convenience class for use with other packages (e.g. Squares)
import 'package:bishop/bishop.dart';

class GameInfo {
  final Move? lastMove;
  final String? lastFrom;
  final String? lastTo;
  final String? checkSq;

  GameInfo({
    this.lastMove,
    this.lastFrom,
    this.lastTo,
    this.checkSq,
  });
}
