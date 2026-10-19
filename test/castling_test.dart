import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Castling', () {
    test('Don\'t allow castling with piece between rook and dest', () {
      final g = Game(
        fen: '1r2k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/5Q1p/PPPBBPPP/RN2K2R w KQk - 2 2',
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
    // https://github.com/alexobviously/bishop/issues/85
    test(
      'Queenside castling when black king has moved/castled and rights remain (#85)',
      () {
        // FEN from issue #85: Black has castled to g8, but castling rights 'KQq' remain.
        // White on e1 has clear path to castle queenside (c1, d1 empty and unattacked).
        final g = Game(
          fen: 'r1bq1rk1/pp2npbp/2np2p1/2p5/4P2P/2NPB1P1/PPP1QPB1/R3K2R w KQq - 0 1',
        );
        final castlingMoves = g.generateLegalMoves().castlingMoves;
        expect(
          castlingMoves.length,
          2,
          reason: 'Both O-O and O-O-O should be legal',
        );
        expect(
          castlingMoves.any(
            (m) => m is StandardMove && m.castlingDir == Castling.q,
          ),
          isTrue,
          reason: 'Queenside castling (O-O-O) must be generated',
        );
      },
    );
    // Recreates a failure found in https://github.com/alexobviously/bishop/pull/86
    test(
      'Queenside castling is legal even if kingside square (f1) is attacked',
      () {
        // Position where black king is on g8 and black rook on f8 attacks f1 directly.
        // Castling rights are 'Qq'. White king is on e1 and path c1-d1 is clear and safe.
        // A flaw in Govind\'s PR would still check f1 and block O-O-O if f1 is attacked.
        final g = Game(fen: '5rk1/8/8/8/8/8/8/R3K3 w Qq - 0 1');
        final castlingMoves = g.generateLegalMoves().castlingMoves;
        expect(
          castlingMoves.any(
            (m) => m is StandardMove && m.castlingDir == Castling.q,
          ),
          isTrue,
          reason:
              'O-O-O must not be blocked by an attacked kingside square (f1)',
        );
      },
    );
  });
}
