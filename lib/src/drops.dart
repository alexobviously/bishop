import 'package:bishop/bishop.dart';

class DropParams {
  final int colour;
  final BishopState state;
  final BuiltVariant variant;
  const DropParams({
    required this.colour,
    required this.state,
    required this.variant,
  });
}

typedef DropBuilderFunction = List<Move> Function(DropParams params);

class Drops {
  static DropBuilderFunction standard({bool restrictPromoPieces = true}) =>
      (DropParams params) {
        final variant = params.variant;
        final size = variant.boardSize;
        final state = params.state;
        List<Move> drops = [];
        Set<int> hand = state.handPieceTypes(params.colour);
        for (int i = 0; i < size.numIndices; i++) {
          if (!size.onBoard(i)) continue;
          if (state.board[i].isNotEmpty) continue;
          for (int p in hand) {
            int hRank = size.rank(i);
            if (restrictPromoPieces) {
              bool onEdgeRank = hRank == Bishop.rank1 || hRank == size.maxRank;
              if (onEdgeRank &&
                  variant.pieces[p].type.promoOptions.canPromote) {
                continue;
              }
            }
            Move m = Move.drop(to: i, dropPiece: p);
            drops.add(m);
          }
        }
        return drops;
      };
}
