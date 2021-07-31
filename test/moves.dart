import 'package:squares/squares.dart';

import 'constants.dart';

main(List<String> args) {
  // Squares g = Squares(variant: Variant.standard(), fen: Positions.ROOK_PIN);
  // List<Move> moves = g.generateLegalMoves();
  // print(moves.length);
  // // for (Move m in moves) {
  // //   // if (m.capture) continue;
  // //   // String sqn = squareName(m.from, g.size);
  // //   // if (['e1', 'a1', 'h1'].contains(sqn)) continue;
  // //   // if (sqn != 'a2') continue;
  // //   print('${m.algebraic(g.size)}');
  // //   // print(m.from);
  // //   // print(m.to);
  // // }
  // Move m = g.getMove('a5b6')!;
  // print(m.algebraic(g.size));
  // print(g.toSan(m));
  // print(g.state.royalSquares.map((e) => squareName(e, g.size)));
  // g.makeMove(m);
  // print(g.kingAttacked(1 - g.state.turn));
  // print(g.ascii());
  // List<Move> _moves = g.generateLegalMoves();
  // print(_moves.map((e) => e.algebraic(g.size)).toList());
  Squares game = Squares(variant: Variant.chess960());

  print(game.fen);
}
