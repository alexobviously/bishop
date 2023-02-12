import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Actions', () {
    test('Explosion', () {
      final g = Game(
        variant: Variant.atomic(),
        fen: '4k3/8/1nn5/2pp4/4P3/8/8/4K3 w - - 0 1',
      );
      g.makeMoveString('e4d5');
      expect(g.state.pieceCount(Bishop.black), 2);
    });
    test('Add to Hand', () {
      final g = Game(
        variant: MiscVariants.spawn(),
        fen: '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
      );
      g.makeMoveString('e1e2');
      expect(g.state.hands![Bishop.white].length, 1);
    });

    test('Remove from Hand', () {
      final g = Game(
        variant: Variant.standard().copyWith(
          handOptions: HandOptions.enabledOnly,
          actions: [Action(action: ActionDefinitions.removeFromHand('P'))],
        ),
        fen: '4k3/8/8/8/8/8/8/4K3[PPPP] w - - 0 1',
      );
      g.makeMoveString('e1e2');
      expect(g.state.hands![Bishop.white].length, 3);
    });
    test('Piece specific action doesn\'t execute for other pieces', () {
      final g = Game(
        variant: MiscVariants.spawn(),
        fen: '4k3/8/8/8/8/8/8/N3K3 w - - 0 1',
      );
      g.makeMoveString('a1c2');
      expect(g.state.hands![Bishop.white].length, 0);
    });
    test('Check Piece Count (Kinglet - win)', () {
      final g = Game(
        variant: MiscVariants.kinglet(),
        fen: '1Q6/8/1p6/3k4/4K3/P7/7N/7n w - - 0 1',
      );
      g.makeMultipleMoves(['e4d5', 'b6b5', 'b8b5']);
      expect(g.result, isA<WonGameElimination>());
      expect(g.winner, Bishop.white);
    });
    test('Check Piece Count (Kinglet - invalid)', () {
      final g = Game(
        variant: MiscVariants.kinglet(),
        fen: '8/PP6/8/8/8/1p6/7N/7n w - - 0 1',
      );
      g.makeMultipleMoves(['a7a8k', 'b3b2']);
      expect(
        g.state
            .pieces[makePiece(g.variant.pieceIndexLookup['K']!, Bishop.white)],
        1,
      );
      expect(
        g.generateLegalMoves().from(g.size.squareNumber('b7')).length,
        0,
      );
    });
    test('Check Piece Count (Three Kings - win)', () {
      final g = Game(
        variant: MiscVariants.threeKings(),
        fen: '1k6/2k5/3k4/8/8/R5n1/R7/RKK4K b - - 0 1',
      );
      g.makeMoveString('g3h1');
      expect(g.result, isA<WonGameElimination>());
      expect(g.winner, Bishop.black);
    });
    test('Check Piece Count (Three Kings x Atomic - invalid)', () {
      final tk = MiscVariants.threeKings();
      final g = Game(
        variant: tk.copyWith(
          actions: [ActionExplosionRadius(1), ...tk.actions],
        ),
        fen: '1k5r/2k4r/8/3k4/3K4/R7/R7/RK5K w - - 0 1',
      );
      expect(g.makeMoveString('d4d5'), false);
    });
    test('Immortality (piece type)', () {
      final v = Variant.standard()
          .copyWith(actions: [ActionImmortality(pieceType: 'B')]);
      final g = Game(variant: v, fen: '7k/8/3b4/8/4N3/8/8/7K w - - 0 1');
      final moves = g.generateLegalMoves();
      expect(moves.captures.length, 0);
    });
  });
}
