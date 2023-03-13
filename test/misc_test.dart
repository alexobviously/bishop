import 'package:bishop/bishop.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Misc', () {
    test('Pawn Forward Premove', () {
      final g = Game(
        variant: Variant.standard(),
        fen: 'rn1qkbnr/ppp1pppp/2b5/3p4/2PP4/5Q2/PP2PPPP/RNB1KBNR b KQkq - 0 1',
      );
      final m = g
          .generatePremoves()
          .from(Bishop.squareNumber('d4'))
          .to(Bishop.squareNumber('d5'));
      expect(m.length, 1);
    });
  });
  test('Forbid Checks (Racing Kings)', () {
    final g = Game(
      variant: CommonVariants.racingKings(),
      fen: '8/1k6/4N3/7K/8/8/8/8 w - - 0 1',
    );
    expect(g.makeMoveString('e6d8'), false);
    expect(g.makeMoveString('e6c5'), false);
    expect(g.makeMoveString('e6d4'), true);
  });
  test('Hand count from FEN (dart chess)', () {
    final g = Game(variant: MiscVariants.dart());
    expect(g.state.hands![Bishop.white].length, 3);
    expect(g.state.hands![Bishop.black].length, 3);
  });
  test('Forced Captures (Antichess)', () {
    final g = Game(
      variant: CommonVariants.antichess(),
      fen: '8/3r4/8/8/8/8/r2R3r/8 w - - 0 1',
    );
    final moves = g.generateLegalMoves();
    expect(moves.length, 3);
  });
  test('Forced Captures (Antichess - no captures)', () {
    final g = Game(
      variant: CommonVariants.antichess(),
      fen: '8/4r3/8/8/8/r7/3R4/7r w - - 0 1',
    );
    final moves = g.generateLegalMoves();
    expect(moves.length, 14);
  });
  test('Captured Pieces (static)', () {
    final g = Game(
      fen: 'rnbqkbnr/ppppp2p/8/8/8/8/PPPPPPPP/RNBQKB1R w KQkq - 0 1',
    );
    expect(g.state.capturedPiecesList(), unorderedEquals(['p', 'p', 'N']));
  });
  test('Captured Pieces (after sequence)', () {
    final g = Game();
    g.makeMultipleMoves(
      ['e2e4', 'd7d5', 'e4d5', 'd8d5', 'b1c3', 'c8e6', 'c3d5', 'e6d5'],
    );
    expect(g.state.capturedPiecesList(), unorderedEquals(['P', 'p', 'N', 'q']));
  });
  test('Captured Pieces (crazyhouse)', () {
    final g = Game(
      variant: CommonVariants.crazyhouse(),
      fen: 'rnbqkbnr/p3pppp/2p5/8/8/8/PPPP1PPP/RNBQKBNR[PPp] w KQkq - 0 4',
    );
    expect(g.state.capturedPiecesList(), unorderedEquals(['p']));
  });
  test('Lame Leaper Block (Xiangqi Elephant)', () {
    final g = Game(
      variant: Xiangqi.variant(),
      fen: '2baka2r/C2R5/4R4/2p5p/1n2n1p2/9/P1P3P1P/4C1N2/9/2BAKAB2 b - - 0 1',
    );
    final moves = g.generateLegalMoves().from(g.size.squareNumber('c10'));
    expect(moves.length, 0);
  });
}
