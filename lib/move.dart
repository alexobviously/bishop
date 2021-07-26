import 'castling_rights.dart';

class Move {
  final int start;
  final int end;
  final int? capturedPiece;
  final int? promoPiece;
  final CastlingRights? castlingDir;
  final bool ep;

  bool get capture => capturedPiece != null;
  bool get promotion => promoPiece != null;
  bool get castling => castlingDir != null;

  Move({
    required this.start,
    required this.end,
    this.capturedPiece,
    this.promoPiece,
    this.castlingDir,
    this.ep = false,
  });
}
