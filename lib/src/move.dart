import 'package:bishop/bishop.dart';

import 'castling_rights.dart';
import 'square.dart';
import 'variant/variant.dart';

class Move {
  final int from;
  final int to;
  final int? capturedPiece;
  final int? promoSource; // the piece type that got promoted
  final int? promoPiece; // this piece type that was promoted to
  final CastlingRights? castlingDir;
  final int? castlingPieceSquare;
  final bool enPassant;
  final bool setEnPassant;
  final int? dropPiece;

  bool get capture => capturedPiece != null;
  bool get promotion => promoPiece != null;
  bool get castling => castlingDir != null;
  bool get drop => dropPiece != null;
  bool get handDrop => drop && from == HAND;
  bool get gate => drop && from >= BOARD_START;

  Move({
    required this.from,
    required this.to,
    this.capturedPiece,
    this.promoSource,
    this.promoPiece,
    this.castlingDir,
    this.castlingPieceSquare,
    this.enPassant = false,
    this.setEnPassant = false,
    this.dropPiece,
  });

  Move copyWith({
    int? from,
    int? to,
    int? capturedPiece,
    int? promoSource,
    int? promoPiece,
    CastlingRights? castlingDir,
    int? castlingPieceSquare,
    bool? enPassant,
    bool? setEnPassant,
    int? dropPiece,
  }) {
    return Move(
      from: from ?? this.from,
      to: to ?? this.to,
      capturedPiece: capturedPiece ?? this.capturedPiece,
      promoSource: promoSource ?? this.promoSource,
      promoPiece: promoPiece ?? this.promoPiece,
      castlingDir: castlingDir ?? this.castlingDir,
      castlingPieceSquare: castlingPieceSquare ?? this.castlingPieceSquare,
      enPassant: enPassant ?? this.enPassant,
      setEnPassant: setEnPassant ?? this.setEnPassant,
      dropPiece: dropPiece ?? this.dropPiece,
    );
  }

  factory Move.drop({required int to, required int dropPiece}) => Move(from: HAND, to: to, dropPiece: dropPiece);

  /// Provides the most basic algebraic form of the move.
  /// This is not entirely descriptive, and doesn't provide information on promo
  /// or gated pieces, for example.
  /// Use `Game.toAlgebraic` in almost every situation.
  String algebraic({BoardSize size = const BoardSize(8, 8), bool useRookForCastling = false}) {
    String _from = from == HAND ? '@' : squareName(from, size);
    String _to = squareName((castling && useRookForCastling) ? castlingPieceSquare! : to, size);
    return '$_from$_to';
  }
}
