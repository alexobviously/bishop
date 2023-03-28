part of 'move.dart';

/// A type of move that wraps another move and extends its functionality.
/// Currently [child] is limited to StandardMoves only.
class WrapperMove implements Move {
  final StandardMove child;
  const WrapperMove({required this.child});

  @override
  bool get capture => child.capture;

  @override
  int? get capturedPiece => child.capturedPiece;

  @override
  bool get castling => child.castling;

  @override
  int? get dropPiece => child.dropPiece;

  @override
  bool get enPassant => child.enPassant;

  @override
  int get from => child.from;

  @override
  bool get gate => child.gate;

  @override
  bool get handDrop => child.handDrop;

  @override
  int? get promoPiece => child.promoPiece;

  @override
  bool get promotion => child.promotion;

  @override
  bool get setEnPassant => child.setEnPassant;

  @override
  int get to => child.to;
}
