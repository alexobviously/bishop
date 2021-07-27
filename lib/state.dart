import 'castling_rights.dart';
import 'constants.dart';
import 'move.dart';

class State {
  final Move? move;
  final Colour turn;
  final int halfMoves;
  final int fullMoves;
  final CastlingRights castling;
  final int? epSquare;

  State({
    this.move,
    required this.turn,
    required this.halfMoves,
    required this.fullMoves,
    required this.castling,
    this.epSquare,
  });
}
