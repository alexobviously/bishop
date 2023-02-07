import 'package:bishop/bishop.dart';

part 'drop_move.dart';
part 'multi_move.dart';
part 'normal_move.dart';
part 'pass_move.dart';

abstract class Move {
  const Move();

  /// The board location this move starts at.
  int get from;

  /// The board location this move ends at.
  int get to;

  /// The piece (including colour and flags) that is being captured, if one is.
  int? get capturedPiece => null;

  /// Whether a piece is captured as a result of this move.
  bool get capture => false;

  /// If this move is en passant.
  bool get enPassant => false;

  /// If this move sets the en passant flag.
  bool get setEnPassant => false;

  /// The piece (type only) that is being promoted to.
  int? get promoPiece => null;

  /// Whether the moved piece is promoted.
  bool get promotion => false;

  /// Whether this is a castling move.
  bool get castling => false;

  /// Whether this is a gated drop, e.g. the drops in Seirawan chess.
  bool get gate => false;

  /// Whether this is a drop move where the piece came from the hand to an empty
  /// square, e.g. the drops in Crazyhouse.
  bool get handDrop => false;

  /// The piece (type only) that is being dropped, if one is.
  int? get dropPiece => null;
}
