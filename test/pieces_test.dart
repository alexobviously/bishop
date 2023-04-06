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
  List<MoveTest> moveTests = [
    MoveTest('ffN', ['c6', 'e6']),
    MoveTest('lfN', ['c6']),
    MoveTest('lhN', ['c6', 'b5', 'b3', 'c2']),
    MoveTest('rfZ', ['f7']),
    MoveTest('bhC', ['c1', 'e1', 'g3', 'a3']),
    MoveTest('rbF1', ['e3']),
    MoveTest('vN', ['c2', 'c6', 'e2', 'e6']),
    MoveTest('fslbC', ['a5', 'g5', 'c1']),
    MoveTest('(4,1)', ['c8', 'e8', 'h3', 'h5']),
    MoveTest('r(4,3)', ['h1', 'h7']),
    MoveTest('frN2rfN', ['f5', 'h6', 'e6']),
    MoveTest(
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
