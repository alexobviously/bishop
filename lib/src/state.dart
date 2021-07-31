import 'castling_rights.dart';
import 'constants.dart';
import 'move.dart';

class State {
  final Move? move;
  final Colour turn;
  final int halfMoves;
  final int fullMoves;
  final CastlingRights castlingRights;
  final int? epSquare;
  final List<int> royalSquares;
  int hash; // Needs to be set after construction for the first hash

  State({
    this.move,
    required this.turn,
    required this.halfMoves,
    required this.fullMoves,
    required this.castlingRights,
    this.epSquare,
    required this.royalSquares,
    this.hash = 0,
  });
}
