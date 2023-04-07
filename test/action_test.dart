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
      expect(g.state.blackPieceCount, 3);
      expect(g.state.whitePieceCount, 1);
    });
    test('Explosion - Don\'t explode pawn', () {
      final g = Game(
        variant: Variant.atomic(),
        fen: 'r1bk3r/pp3ppp/n1pppq1n/4N3/7Q/4P3/PP1P1PPP/RNBK3R w - - 2 10',
      );
      g.makeMoveString('e5f7');
      expect(g.fen, 'r1bk3r/pp4pp/n1ppp2n/8/7Q/4P3/PP1P1PPP/RNBK3R b - - 0 10');
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
        variant: tk.withAction(ActionExplosionRadius(1), first: true),
        fen: '1k5r/2k4r/8/3k4/3K4/R7/R7/RK5K w - - 0 1',
      );
      expect(g.makeMoveString('d4d5'), false);
    });
    test('Immortality (piece type)', () {
      final v =
          Variant.standard().withAction(ActionImmortality(pieceType: 'B'));
      final g = Game(variant: v, fen: '7k/8/3b4/8/4N3/8/8/7K w - - 0 1');
      final moves = g.generateLegalMoves();
      expect(moves.captures.length, 0);
    });
    test('Transfer Ownership (Andernach)', () {
      final g = Game(variant: MiscVariants.andernach());
      g.makeMultipleMoves(['e2e4', 'd7d5', 'e4d5']);
      expect(g.state.pieceOnSquare('d5'), 'p');
      g.makeMultipleMoves(['c8g4', 'd1g4']);
      expect(g.state.pieceOnSquare('g4'), 'q');
      g.makeMultipleMoves(['b8a6', 'b2b4', 'a6b4']);
      expect(g.state.pieceOnSquare('b4'), 'N');
    });
    test('Transfer Ownership (quiet, promo)', () {
      final g = Game(
        variant: Variant.standard().withAction(ActionTransferOwnership()),
        fen: '8/1k3P2/8/8/8/8/3K4/8 w - - 0 1',
      );
      g.makeMoveString('f7f8b');
      expect(g.state.pieceOnSquare('f8'), 'b');
    });
  });
  test('Fill Region (Kono)', () {
    final g =
        Game(variant: OtherGames.kono(), fen: 'PPPPP/4P/1P3/5/4p w - - 0 1');
    g.makeMoveString('b3a4');
    expect(g.result, isA<WonGameEnteredRegion>());
    expect(g.winner, Bishop.white);
  });
}
