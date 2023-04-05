import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('State Transform', () {
    test('Vision Area', () {
      final v = Variant.standard().copyWith(
        stateTransformer: VisionAreaStateTransformer(),
      );
      final g = Game(
        variant: v,
        fen: 'rnbqkbnr/ppp1pppp/8/3p4/P7/8/1PPPPPNP/RNBQKB1R w KQkq - 0 1',
      );
      expect(g.state.pieceOnSquare('d5'), 'p');
      expect(g.state.transform(Bishop.white).pieceOnSquare('d5'), '.');
      expect(g.state.transform(Bishop.black).pieceOnSquare('d5'), 'p');
      g.makeMoveString('d2d4');
      expect(g.state.transform(Bishop.white).pieceOnSquare('d5'), 'p');
      expect(g.state.transform(Bishop.black).pieceOnSquare('d4'), 'P');
      expect(g.state.transform(Bishop.white).pieceOnSquare('g2'), 'N');
      expect(g.state.transform(Bishop.black).pieceOnSquare('g2'), '.');
      g.makeMoveString('c8h3');
      expect(g.state.transform(Bishop.black).pieceOnSquare('g2'), 'N');
      expect(g.state.transform(Bishop.white).pieceOnSquare('h3'), 'b');
    });
  });
}
