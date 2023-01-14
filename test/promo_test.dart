import 'package:bishop/bishop.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Promotions', () {
    final grand = Variant.grand();
    test('Grand - optional, all promos available', () {
      Game g = Game(
        variant: grand,
        fen: '10/10/10/2k4P2/10/10/3K6/10/10/10 w - - 0 1',
      );
      final m = g.generateLegalMoves().from(grand.boardSize.squareNumber('h7'));
      expect(m.length, 7);
    });
    test('Grand - optional, no queen or bishop', () {
      Game g = Game(
        variant: grand,
        fen: '10/10/10/2k4P2/10/10/3K6/3QBBN3/10/10 w - - 0 1',
      );
      final m = g.generateLegalMoves().from(grand.boardSize.squareNumber('h7'));
      expect(m.length, 5);
    });
    test('Grand - forced, no queen or bishop', () {
      Game g = Game(
        variant: grand,
        fen: '10/7P2/10/2k7/10/10/3K6/3QBBN3/10/10 w - - 0 1',
      );
      final m = g.generateLegalMoves().from(grand.boardSize.squareNumber('h9'));
      expect(m.length, 4);
    });
  });
}
