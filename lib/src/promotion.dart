import 'package:bishop/bishop.dart';

typedef PromotionBuilder = List<Move> Function(PromotionParams request);

class PromotionParams {
  final Move base;
  final BishopState state;
  final BuiltVariant variant;
  final PieceType pieceType;

  const PromotionParams({
    required this.base,
    required this.state,
    required this.variant,
    required this.pieceType,
  });
}

class Promotion {
  /// Generates a move for each piece in [variant.promotionPieces] for the [base] move.
  static List<Move> basic(PromotionParams params) {
    List<Move> moves = [];
    for (int p in params.variant.promotionPieces) {
      Move m = params.base.copyWith(
        promoSource: params.state.board[params.base.from].type,
        promoPiece: p,
      );
      moves.add(m);
    }
    return moves;
  }
}
