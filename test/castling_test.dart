import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Castling', () {
    test('Don\'t allow castling with piece between rook and dest', () {
      final g = Game(
        fen:
            '1r2k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/5Q1p/PPPBBPPP/RN2K2R w KQk - 2 2',
      );
      expect(g.generateLegalMoves().castlingMoves.length, 1);
    });
    // https://github.com/alexobviously/bishop/issues/72
    test('Chess960 K-C1:R-A1 castling', () {
      final g = Game(
        variant: CommonVariants.chess960(),
        fen: 'rnkqbbrn/pppppppp/8/8/8/8/PPPPPPPP/R1K1BBRN w AGag - 0 1',
      );
      final moves = g.generateLegalMoves();
      expect(moves.castlingMoves.length, 1);
      expect(moves.from(g.size.squareNumber('c1')).length, 3);
    });
    // https://github.com/alexobviously/bishop/issues/77
    test('Chess960 K-B1:R-C1 castling', () {
      final g = Game(
        variant: CommonVariants.chess960(),
        fen: 'rkr4n/ppppqbpp/3bpp1n/8/8/2BPPN2/PPPQBPPP/RKR4N w KQkq - 6 7',
      );
      final moves = g.generateLegalMoves();
      expect(moves.castlingMoves.length, 1);
      expect(moves.from(g.size.squareNumber('b1')).length, 1);
    });
    test('Castling rights when a rook takes a rook', () {
      final g = Game(
        fen: 'rnbqk1nr/ppp1ppb1/6p1/3p4/8/2N5/PPPPPPP1/R1BQKBNR w KQkq - 0 5',
      );
      g.makeMoveString('h1h8');
      expect(g.state.castlingRights, castlingRights('Qq'));
    });
  });
}
