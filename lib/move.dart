import 'castling_rights.dart';
import 'square.dart';
import 'variant.dart';

class Move {
  final int to;
  final int from;
  final int? capturedPiece;
  final int? promoPiece;
  final CastlingRights? castlingDir;
  final bool ep;

  bool get capture => capturedPiece != null;
  bool get promotion => promoPiece != null;
  bool get castling => castlingDir != null;

  Move({
    required this.to,
    required this.from,
    this.capturedPiece,
    this.promoPiece,
    this.castlingDir,
    this.ep = false,
  });

  String algebraic([BoardSize boardSize = const BoardSize(8, 8)]) {
    String _to = squareName(to, boardSize);
    String _from = squareName(from, boardSize);
    return '$_to$_from';
  }
}
