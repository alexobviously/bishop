import 'package:bishop/bishop.dart';

typedef PromotionSetup = PromotionBuilder Function(BuiltVariant variant);
typedef PromotionBuilder = List<Move>? Function(PromotionParams request);

class PromotionParams {
  final Move move;
  final BishopState state;
  final BuiltVariant variant;
  final PieceType pieceType;

  const PromotionParams({
    required this.move,
    required this.state,
    required this.variant,
    required this.pieceType,
  });
}

class Promotion {
  /// Generates a move for each piece in [variant.promotionPieces] for the [move] move.
  static PromotionBuilder standard({
    required List<int> ranks,
    bool includeBaseMove = false,
  }) =>
      (PromotionParams params) {
        if (!params.pieceType.promotable) return null;

        Square piece = params.state.board[params.move.from];
        if (piece.isEmpty) return null;
        Colour colour = piece.colour;

        int toRank = params.variant.boardSize.rank(params.move.to);
        bool promo = colour == Bishop.white
            ? toRank >= ranks[Bishop.white]
            : toRank <= ranks[Bishop.black];

        if (!promo) return null;

        List<Move> moves = [];
        for (int p in params.variant.promotionPieces) {
          Move m = params.move.copyWith(
            promoSource: params.state.board[params.move.from].type,
            promoPiece: p,
          );
          moves.add(m);
        }
        if (includeBaseMove) moves.add(params.move);
        return moves;
      };

  static PromotionBuilder optional({
    required List<int> ranks,
    List<int>? forcedRanks,
  }) =>
      (PromotionParams params) {
        if (!params.pieceType.promotable) return null;

        Square piece = params.state.board[params.move.from];
        if (piece.isEmpty) return null;
        Colour colour = piece.colour;

        int toRank = params.variant.boardSize.rank(params.move.to);
        bool optPromo = colour == Bishop.white
            ? toRank >= ranks[Bishop.white]
            : toRank <= ranks[Bishop.black];
        if (!optPromo) return null;
        bool forcedPromo = false;
        if (forcedRanks != null) {
          forcedPromo = colour == Bishop.white
              ? toRank >= params.variant.boardSize.maxRank
              : toRank <= Bishop.rank1;
        }

        List<Move> moves = [];
        for (int p in params.variant.promotionPieces) {
          Move m = params.move.copyWith(
            promoSource: params.state.board[params.move.from].type,
            promoPiece: p,
          );
          moves.add(m);
        }
        if (!forcedPromo) moves.add(params.move);
        return moves;
      };
}
