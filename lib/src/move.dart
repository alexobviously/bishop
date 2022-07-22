import 'package:bishop/bishop.dart';

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

  /// For gating drops that are also castling moves - should we gate on square
  /// that the king came from (false) or the rook (true).
  final bool dropOnRookSquare;

  /// Whether a piece is captured as a result of this move.
  bool get capture => capturedPiece != null;

  /// Whether the moved piece is promoted.
  bool get promotion => promoPiece != null;

  /// Whether this is a castling move.
  bool get castling => castlingDir != null;

  /// Whether this is a drop move (any type, including gating).
  bool get drop => dropPiece != null;

  /// Whether this is a drop move where the piece came from the hand to an empty
  /// square, e.g. the drops in Crazyhouse.
  bool get handDrop => drop && from == Bishop.hand;

  /// Whether this is a gated drop, e.g. the drops in Seirawan chess.
  bool get gate => drop && from >= Bishop.boardStart;

  @override
  String toString() {
    List<String> params = ['from: $from', 'to: $to'];
    if (promotion) params.add('promo: $promoPiece');
    if (castling) params.add('castling: $castlingDir');
    if (drop) params.add('drop: $dropPiece');
    if (enPassant) params.add('enPassant');
    if (setEnPassant) params.add('setEnPassant');
    return 'Move(${params.join(', ')})';
  }

  const Move({
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
    this.dropOnRookSquare = false,
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
    bool? dropOnRookSquare,
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
      dropOnRookSquare: dropOnRookSquare ?? this.dropOnRookSquare,
    );
  }

  factory Move.drop({required int to, required int dropPiece}) =>
      Move(from: Bishop.hand, to: to, dropPiece: dropPiece);

  /// Provides the most basic algebraic form of the move.
  /// This is not entirely descriptive, and doesn't provide information on promo
  /// or gated pieces, for example.
  /// Use `Game.toAlgebraic` in almost every situation.
  String algebraic({
    BoardSize size = BoardSize.standard,
    bool useRookForCastling = false,
  }) {
    String fromStr = from == Bishop.hand ? '@' : squareName(from, size);
    String toStr = squareName((castling && useRookForCastling) ? castlingPieceSquare! : to, size);
    return '$fromStr$toStr';
  }
}
