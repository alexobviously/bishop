import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Makruk', () {
    test('Starting position setup and moves', () {
      final g = Game(variant: CommonVariants.makruk());
      expect(g.fen, 'rnbkqbnr/8/pppppppp/8/8/PPPPPPPP/8/RNBKQBNR w - - 0 1');

      // White has 8 single pawn pushes + 4 knight moves + 6 rook moves on open 2nd rank + 4 khon moves = 22 moves.
      // Wait, let's verify exact legal move count from startpos.
      final legalMoves = g.generateLegalMoves();
      expect(legalMoves.isNotEmpty, isTrue);

      // Verify pawns cannot double push
      expect(
        legalMoves.any((m) => g.size.rank(m.to) == Bishop.rank5),
        isFalse,
        reason: 'Pawns on rank 3 should not be able to double push to rank 5',
      );

      // Verify no castling moves exist
      expect(legalMoves.castlingMoves.isEmpty, isTrue);
    });

    test('Khon (B) moves 1 square diagonally or 1 square forward', () {
      // Place White Khon on e4
      final g = Game(
        variant: CommonVariants.makruk(),
        fen: '4k3/8/8/8/4B3/8/8/3K4 w - - 0 1',
      );
      final khonMoves = g
          .generateLegalMoves()
          .where((m) => m.from == g.size.squareNumber('e4'))
          .map(g.toSan)
          .toSet();
      // From e4, FfW can move to: d5 (diag), e5 (fwd), f5 (diag), d3 (diag), f3 (diag)
      expect(khonMoves, equals({'Bd5', 'Be5', 'Bf5', 'Bd3', 'Bf3'}));
    });

    test('Met (Q) moves 1 square diagonally', () {
      // Place White Met on e4
      final g = Game(
        variant: CommonVariants.makruk(),
        fen: '4k3/8/8/8/4Q3/8/8/3K4 w - - 0 1',
      );
      final metMoves = g
          .generateLegalMoves()
          .where((m) => m.from == g.size.squareNumber('e4'))
          .map(g.toSan)
          .toSet();
      // From e4, F can move to: d5, f5, d3, f3
      expect(metMoves, equals({'Qd5', 'Qf5', 'Qd3', 'Qf3'}));
    });

    test('White pawn promotes on rank 6 to Met (Q)', () {
      final g = Game(
        variant: CommonVariants.makruk(),
        fen: 'rnbkqbnr/8/1ppppppp/P7/8/1PPPPPPP/8/RNBKQBNR w - - 0 1',
      );
      final pMoves = g
          .generateLegalMoves()
          .where((m) => m.from == g.size.squareNumber('a5'))
          .toList();
      expect(pMoves.isNotEmpty, isTrue);
      expect(pMoves.every((m) => m.promotion), isTrue);

      g.makeMoveSan('a6=Q');
      expect(
        g.board[g.size.squareNumber('a6')].type,
        g.variant.pieceIndex('Q'),
      );
    });

    test('Black pawn promotes on rank 3 to Met (q)', () {
      final g = Game(
        variant: CommonVariants.makruk(),
        fen: 'rnbkqbnr/8/1PPPPPPP/8/4p3/1ppp1ppp/8/RNBKQBNR b - - 0 1',
      );
      final pMoves = g
          .generateLegalMoves()
          .where((m) => m.from == g.size.squareNumber('e4'))
          .toList();
      expect(pMoves.isNotEmpty, isTrue);
      expect(pMoves.every((m) => m.promotion), isTrue);

      g.makeMoveSan('e3=Q');
      expect(
        g.board[g.size.squareNumber('e3')].type,
        g.variant.pieceIndex('Q'),
      );
    });
  });
}
