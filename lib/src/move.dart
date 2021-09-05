import 'package:bishop/bishop.dart';

import 'castling_rights.dart';
import 'square.dart';
import 'variant/variant.dart';

/// A representation of a single move.
/// This is a move that is made in a game, not a definition of a type of move
/// that can be made by a piece. For that, see `MoveDefinition`.
class Move {
  /// The board location this move starts at.
  final int from;

  /// The board location this move ends at.
  final int to;

  /// The piece (including colour and flags) that is being captured, if one is.
  final int? capturedPiece;

  /// The piece that exists before the promotion.
  final int? promoSource; // the piece type that got promoted
  /// The piece (type only) that is being promoted to.
  final int? promoPiece; // this piece type that was promoted to
  /// If this is a castling move, in which direction is castling happening?
  final CastlingRights? castlingDir;

  /// The square where the castling piece (e.g. a rook), is located.
  final int? castlingPieceSquare;

  /// If this move is en passant.
  final bool enPassant;

  /// If this move sets the en passant flag.
  final bool setEnPassant;

  /// The piece (type only) that is being dropped, if one is.
  final int? dropPiece;

  /// Whether a piece is captured as a result of this move.
  bool get capture => capturedPiece != null;

  /// Whether the moved piece is promoted.
  bool get promotion => promoPiece != null;

  /// Whether this is a castling move.
  bool get castling => castlingDir != null;

  /// Whether this is a drop move (any type, including gating).
  bool get drop => dropPiece != null;

  /// Whether this was a drop move where the piece came from the hand to an empty
  /// square, e.g. the drops in Crazyhouse.
  bool get handDrop => drop && from == HAND;

  /// Whether this was a gated drop, e.g. the drops in Seirawan chess.
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
