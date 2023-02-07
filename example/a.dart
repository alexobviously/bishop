import 'package:bishop/bishop.dart';

void main(List<String> args) {
  final g = Game(
    variant: CommonVariants.crazyhouse(),
    fen: '8/7P/8/8/1k6/8/1K6/8[] w - - 0 1',
  );
  final moves = g.generateLegalMoves();
  print(moves.toAlgebraic(g));
  // print(moves.passMoves.toAlgebraic(g));
}
