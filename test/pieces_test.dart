import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  List<CountMovesTest> countMoveTests = [
    const CountMovesTest('N', 8),
    const CountMovesTest('Q', 8),
    const CountMovesTest('B', 4),
    const CountMovesTest('fmWfceFifmnD', 4), // pawn
    const CountMovesTest('BN', 12),
    const CountMovesTest('FWDA', 16), // musketeer elephant
    const CountMovesTest('B2ND', 16), // musketeer spider
    const CountMovesTest('FWDsN', 16), // musketeer cannon
    const CountMovesTest('rbB', 1),
    const CountMovesTest('fR', 1),
    const CountMovesTest('bB', 2),
    const CountMovesTest('fsN', 2),
    const CountMovesTest('vZ', 4),
    const CountMovesTest('lfC', 1),
    const CountMovesTest('flrbN', 2), // works but should it?
  ];
  List<MoveTest> moveTests = [
    const MoveTest('ffN', ['c6', 'e6']),
    const MoveTest('lfN', ['c6']),
    const MoveTest('lhN', ['c6', 'b5', 'b3', 'c2']),
    const MoveTest('rfZ', ['f7']),
    const MoveTest('bhC', ['c1', 'e1', 'g3', 'a3']),
    const MoveTest('rbF1', ['e3']),
    const MoveTest('vN', ['c2', 'c6', 'e2', 'e6']),
    const MoveTest('fslbC', ['a5', 'g5', 'c1']),
    const MoveTest('(4,1)', ['c8', 'e8', 'h3', 'h5']),
    const MoveTest('r(4,3)', ['h1', 'h7']),
    const MoveTest('frN2rfN', ['f5', 'h6', 'e6']),
    const MoveTest(
      'N0',
      ['b8', 'f8', 'c6', 'e6', 'h6', 'b5', 'f5', 'b3', 'f3', 'c2', 'e2', 'h2'],
    ),
  ];
  group('Pieces', () {
    for (CountMovesTest t in countMoveTests) {
      test('Count Moves - ${t.betza}', () {
        PieceType pt = PieceType.fromBetza(t.betza);
        expect(pt.moves.length, t.num);
      });
    }
    for (MoveTest t in moveTests) {
      test('Move Test - ${t.betza}', () {
        final v = Variant(
          name: 'Test',
          startPosition: '1k6/8/8/8/3T4/8/8/6K1 w KQkq - 0 1',
          pieceTypes: {
            'K': PieceType.staticKing(),
            'T': PieceType.fromBetza(t.betza),
          },
        );
        final g = Game(variant: v);
        final moves = g
            .generateLegalMoves()
            .from(g.size.squareNumber('d4'))
            .map((e) => g.size.squareName(e.to))
            .toList();
        expect(moves, unorderedEquals(t.targets));
      });
    }
  });
}

class CountMovesTest {
  final String betza;
  final int num;
  const CountMovesTest(this.betza, this.num);
}

class MoveTest {
  final String betza;
  final List<String> targets;
  const MoveTest(this.betza, this.targets);
}
