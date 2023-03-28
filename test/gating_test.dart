import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Gating', () {
    test('Flex - Simple', () {
      final g = Game(variant: CommonVariants.seirawan());
      final m = g
          .generateLegalMoves()
          .from(g.size.squareNumber('b1'))
          .to(g.size.squareNumber('a3'));
      expect(m.length, 3);
      expect(m.gatingMoves.length, 2);
      g.makeMoveString('b1a3/h');
      expect(g.state.pieceOnSquare('b1'), 'H');
      expect(g.state.pieceOnSquare('a3'), 'N');
      g.undo();
      g.makeMoveString('b1a3');
      expect(g.state.pieceOnSquare('b1'), '.');
      expect(g.state.pieceOnSquare('a3'), 'N');
    });
  });
  test('Flex - Castling', () {
    final g = Game(
      variant: CommonVariants.seirawan(),
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQK2R[HEhe] w '
          'KQkqABCDEFGHabcdefgh - 0 1',
    );
    final m =
        g.generateLegalMoves().from(g.size.squareNumber('e1')).castlingMoves;
    expect(m.length, 5);
    g.makeMoveString('e1g1/ee1');
    expect(
      ['e1', 'f1', 'g1', 'h1'].map((e) => g.state.pieceOnSquare(e)),
      orderedEquals(['E', 'R', 'K', '.']),
    );
    g.undo();
    g.makeMoveString('e1g1/hh1');
    expect(
      ['e1', 'f1', 'g1', 'h1'].map((e) => g.state.pieceOnSquare(e)),
      orderedEquals(['.', 'R', 'K', 'H']),
    );
  });
}
