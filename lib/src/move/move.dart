import 'package:bishop/bishop.dart';

part 'drop_move.dart';
part 'normal_move.dart';
part 'pass_move.dart';

abstract class Move {
  const Move();

  int get from;
  int get to;

  bool get capture => false;
  int? get capturedPiece => null;
  bool get enPassant => false;
  bool get setEnPassant => false;
  int? get promoPiece => null;
  bool get promotion => false;
  bool get castling => false;
  bool get gate => false;
  bool get handDrop => false;
  int? get dropPiece => null;
}
