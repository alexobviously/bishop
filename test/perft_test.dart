import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

import 'constants.dart';

void main() {
  group('Perft', () {
    List<PerftTest> perfts = [
      PerftTest(variant: Variant.standard(), fen: Positions.standardDefault, depth: 3, nodes: 8902),
      PerftTest(variant: Variant.standard(), fen: Positions.kiwiPete, depth: 2, nodes: 2039),
      PerftTest(variant: Variant.standard(), fen: Positions.rookPin, depth: 4, nodes: 43238),
      PerftTest(variant: Variant.standard(), fen: Positions.position4, depth: 3, nodes: 9467),
      PerftTest(variant: Variant.standard(), fen: Positions.position5, depth: 3, nodes: 62379),
      PerftTest(variant: Variant.standard(), fen: Positions.position6, depth: 3, nodes: 89890),
    ];

    for (PerftTest pt in perfts) {
      test('Perft ${pt.fen} [${pt.variant.name}]', () {
        Game g = Game(variant: pt.variant, fen: pt.fen);
        int nodes = g.perft(pt.depth);
        expect(nodes, equals(pt.nodes));
      });
    }
  });
}

class PerftTest {
  final Variant variant;
  final String fen;
  final int depth;
  final int nodes;

  PerftTest({
    required this.variant,
    required this.fen,
    required this.depth,
    required this.nodes,
  });
}
