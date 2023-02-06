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
}
