import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  List<CountMovesTest> countMoveTests = [
    CountMovesTest('N', 8),
    CountMovesTest('Q', 8),
    CountMovesTest('B', 4),
    CountMovesTest('fmWfceFifmnD', 4), // pawn
    CountMovesTest('BN', 12),
    CountMovesTest('FWDA', 16), // musketeer elephant
    CountMovesTest('B2ND', 16), // musketeer spider
    CountMovesTest('FWDsN', 16), // musketeer cannon
    CountMovesTest('rbB', 1),
    CountMovesTest('fR', 1),
    CountMovesTest('bB', 2),
    CountMovesTest('fsN', 2),
    CountMovesTest('vZ', 4),
    CountMovesTest('lfC', 1),
    CountMovesTest('flrbN', 2), // works but should it?
  ];
  group('Betza - Count Moves', () {
    for (CountMovesTest t in countMoveTests) {
      test('Count Moves - ${t.betza}', () {
        PieceType pt = PieceType.fromBetza(t.betza);
        expect(pt.moves.length, t.num);
      });
    }
  });
}

class CountMovesTest {
  final String betza;
  final int num;
  const CountMovesTest(this.betza, this.num);
}
