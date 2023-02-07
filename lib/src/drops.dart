import 'package:bishop/bishop.dart';

typedef DropBuilderFunction = List<Move> Function(MoveParams params);

class Drops {
  static DropBuilderFunction standard({bool restrictPromoPieces = true}) =>
      (MoveParams params) {
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
            final m = DropMove(to: i, piece: p);
            // NormalMove m = NormalMove.drop(to: i, dropPiece: p);
            drops.add(m);
          }
        }
        return drops;
      };
}
