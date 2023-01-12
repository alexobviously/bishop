import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

import 'constants.dart';

void main() {
  List<DrawTest> tests = [
    DrawTest(
      variant: Variant.standard(),
      fen: Positions.standardDefault,
      draw: false,
    ),
    DrawTest(
      variant: Variant.standard(),
      fen: '8/8/8/8/8/1k6/2q5/K7 w - - 0 1',
      draw: true,
    ),
    DrawTest(
      variant: Variant.standard(),
      fen: '6r1/8/8/8/8/1k6/8/K7 w - - 0 1',
      draw: false,
    ),
    DrawTest(
      variant: Variant.standard(),
      fen: '6n1/8/8/8/8/1k6/8/K7 w - - 0 1',
      draw: true,
    ),
  ];
  group('Draws', () {
    for (DrawTest t in tests) {
      test('Draw Test: ${t.fen}', () {
        Game g = Game(variant: t.variant, fen: t.fen);
        expect(g.drawn, t.draw);
      });
    }
  });
}

class DrawTest {
  final Variant variant;
  final String fen;
  final bool draw;
  const DrawTest(
      {required this.variant, required this.fen, required this.draw});
}
