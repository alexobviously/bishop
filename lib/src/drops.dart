import 'package:bishop/bishop.dart';

typedef DropBuilderFunction = List<Move> Function(MoveParams params);

class Drops {
  static DropBuilderFunction standard({bool restrictPromoPieces = true}) =>
      (MoveParams params) {
        final state = params.state;
        Set<int> hand = state.handPieceTypes(params.colour);
        if (hand.isEmpty) return [];
        final variant = params.variant;
        final size = variant.boardSize;
        List<Move> drops = [];
        for (int i = 0; i < size.numIndices; i++) {
          if (!size.onBoard(i)) continue;
          if (state.board[i].isNotEmpty) continue;
          int hRank = size.rank(i);
          bool onEdgeRank = hRank == Bishop.rank1 || hRank == size.maxRank;
          for (int p in hand) {
            if (restrictPromoPieces) {
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

  static DropBuilderFunction pair(
    DropBuilderFunction white,
    DropBuilderFunction black,
  ) =>
      (params) => params.colour == Bishop.white ? white(params) : black(params);

  static DropBuilderFunction none() => (_) => [];

  static DropBuilderFunction region(Region region) => (MoveParams params) {
        Set<int> hand = params.state.handPieceTypes(params.colour);
        if (hand.isEmpty) return [];
        final size = params.variant.boardSize;
        List<Move> drops = [];
        for (int i in size.squaresForRegion(region)) {
          if (!size.onBoard(i)) continue;
          if (params.state.board[i].isNotEmpty) continue;
          drops.addAll(hand.map((e) => DropMove(to: i, piece: e)));
        }
        return drops;
      };

  static DropBuilderFunction regions(Region? white, Region? black) => pair(
        white == null ? none() : region(white),
        black == null ? none() : region(black),
      );
}
