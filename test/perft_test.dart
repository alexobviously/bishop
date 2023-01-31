import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

import 'perft.dart';

void main() {
  group('Perft', () {
    for (PerftTest pt in Perfts.standard) {
      test('Perft ${pt.fen} [${pt.variant.name}]', () {
        Game g = Game(variant: pt.variant.build(), fen: pt.fen);
        int nodes = g.perft(pt.depth);
        expect(nodes, equals(pt.nodes));
      });
    }
  });
}
