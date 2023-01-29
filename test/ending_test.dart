import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Endings', () {
    test('WonGameCheckmate', () {
      final g = Game(fen: 'k7/2K5/8/8/8/8/8/1R6 w - - 0 1');
      g.makeMoveString('b1a1');
      expect(g.result, isA<WonGameCheckmate>());
      expect(g.winner, Bishop.white);
    });
    test('DrawnGameStalemate', () {
      final g = Game(fen: 'k7/8/8/1Q6/8/4K3/8/8 w - - 0 1');
      g.makeMoveString('b5b6');
      expect(g.result, isA<DrawnGameStalemate>());
    });
    test('WonGameStalemate', () {
      final g = Game(
        variant: Variant.standard().copyWith(
          gameEndConditions: GameEndConditionSet.symmetric(
            GameEndConditions(stalemate: false),
          ),
        ),
        fen: 'k7/8/8/1Q6/8/4K3/8/8 w - - 0 1',
      );
      g.makeMoveString('b5b6');
      expect(g.result, isA<WonGameStalemate>());
      expect(g.winner, Bishop.white);
    });
    test('WonGameEnteredRegion (koth)', () {
      final g = Game(
        variant: Variant.kingOfTheHill(),
        fen: '8/8/3k4/8/8/4K3/8/8 b - - 0 1',
      );
      g.makeMoveString('d6d5');
      expect(g.result, isA<WonGameEnteredRegion>());
      expect(g.winner, Bishop.black);
    });
    test('WonGameCheckLimit (3c)', () {
      final g = Game(variant: Variant.threeCheck());
      g.makeMultipleMoves([
        'e2e4', 'd7d5', 'd1f3', 'd5e4', 'f3f7',
        'e8d7', 'f7f5', 'd7e8', 'f5b5', //
      ]);
      expect(g.result, isA<WonGameCheckLimit>());
      expect(g.winner, Bishop.white);
    });
    test('WonGameRoyalDead (atomic)', () {
      final g = Game(
        variant: Variant.atomic(),
        fen: 'rnbqkb1r/pppppppp/8/4N3/4P1n1/8/PPPP1PPP/RNBQKB1R b KQkq - 2 3',
      );
      g.makeMoveString('g4f2');
      expect(g.result, isA<WonGameRoyalDead>());
      expect(g.winner, Bishop.black);
    });
    test('DrawnGameInsufficientMaterial', () {
      final g = Game(fen: '8/2N5/8/8/3Kr3/8/8/7k w - - 0 1');
      g.makeMoveString('d4e4');
      expect(g.result, isA<DrawnGameInsufficientMaterial>());
    });
    test('DrawnGameRepetition', () {
      final g = Game(fen: '1R6/8/8/8/3K2r1/8/8/7k w - - 0 1');
      g.makeMultipleMoves(
        ['d4d5', 'g4g5', 'd5d4', 'g5g4', 'd4d5', 'g4g5', 'd5d4', 'g5g4'],
      );
      expect(g.result, isA<DrawnGameRepetition>());
    });
    test('DrawnGameLength', () {
      final g = Game(fen: '8/8/4p3/3pBbK1/3P1P2/3k4/8/8 b - - 99 105');
      g.makeMoveString('d3e3');
      expect(g.result, isA<DrawnGameLength>());
    });
    test('DrawnGameBothRoyalsDead', () {
      final g = Game(
        variant: Variant.atomic(allowExplosionDraw: true),
        fen: '8/8/5k2/3KR3/8/8/8/4r3 b - - 0 1',
      );
      g.makeMoveString('e1e5');
      expect(g.result, isA<DrawnGameBothRoyalsDead>());
    });
    test('WonGameElimination', () {
      final g = Game(
        variant: Variant.horde(),
        fen: '1k6/8/8/1P5r/8/8/8/8 b - - 0 1',
      );
      g.makeMoveString('h5b5');
      expect(g.result, isA<WonGameElimination>());
      expect(g.winner, Bishop.black);
    });
  });
}
