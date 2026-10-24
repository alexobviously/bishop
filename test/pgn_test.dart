import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('PGN Parsing', () {
    // https://github.com/alexobviously/bishop/issues/76
    test('handles moves without space after move number (e.g. 1.d4) (#76)', () {
      const pgn = '''
1.d4 Nf6 2.Nf3 d5 3.e3 Bf5 4.c4 c6 5.Nc3 e6 6.Bd3 Bxd3 7.Qxd3 Nbd7 8.b3 Bd6
9.O-O O-O 10.Bb2 Qe7 11.Rad1 Rad8 12.Rfe1 dxc4 13.bxc4 e5 14.dxe5 Nxe5 15.
Nxe5 Bxe5 16.Qe2 Rxd1 17.Rxd1 Rd8 18.Rxd8+ Qxd8 19.Qd1 Qxd1+ 20.Nxd1 Bxb2 21.Nxb2 b5
22.f3 Kf8 23.Kf2 Ke7  1/2-1/2
''';

      final pgnData = parsePgn(pgn);
      expect(
        pgnData.moves.first,
        equals('d4'),
        reason: 'First move should be "d4", not "1.d4"',
      );
      expect(pgnData.moves[1], equals('Nf6'));
      expect(
        pgnData.moves[2],
        equals('Nf3'),
        reason: 'Third move should be "Nf3", not "2.Nf3"',
      );
      expect(pgnData.moves.length, equals(46));

      final game = pgnData.buildGame();
      expect(game.moveHistory.length, equals(46));
    });

    // https://github.com/alexobviously/bishop/issues/73
    // FOR NOW, our strategy is to to discard these, just so these more complex
    // PGN files can be parsed. But we'll want to support variations, comments,
    // NAGs and so on later.
    test('handles Lichess commented PGN with variations and NAGs (#73)', () {
      const pgn = '''
1. e4 { [%eval 0.2] [%clk 0:10:00] } 1... e5 { [%eval 0.18] [%clk 0:10:00] } 2. Nf3 { [%eval 0.21] [%clk 0:09:59] } 2... d6 { [%eval 0.64] [%clk 0:09:59] } { C41 Philidor Defense } 3. Bb5+ { [%eval 0.13] [%clk 0:09:47] } 3... Bd7 { [%eval 0.4] [%clk 0:09:55] } 4. Nc3 { [%eval 0.14] [%clk 0:09:37] } 4... Nc6?! { (0.14 → 0.80) Inaccuracy. Bxb5 was best. } { [%eval 0.8] [%clk 0:09:45] } (4... Bxb5 5. Nxb5 c6 6. Nc3 Nd7 7. d4 Ngf6 8. h3 Be7 9. a4) 5. O-O { [%eval 0.65] [%clk 0:09:27] } 5... Nd4 { [%eval 0.88] [%clk 0:09:24] } 6. Bxd7+ { [%eval 0.82] [%clk 0:08:52] } 6... Qxd7 { [%eval 0.83] [%clk 0:09:22] } 7. d3 { [%eval 0.32] [%clk 0:08:32] } 7... Qg4? { (0.32 → 1.67) Mistake. g6 was best. } { [%eval 1.67] [%clk 0:09:17] } (7... g6 8. Nxd4 exd4 9. Nd5 c6 10. Nf4 Bg7 11. a4 Ne7 12. Re1) 8. Nxd4 { [%eval 1.73] [%clk 0:08:21] } 8... Qxd1 { [%eval 1.65] [%clk 0:09:10] } 9. Rxd1 { [%eval 1.58] [%clk 0:08:18] } 9... exd4 { [%eval 1.6] [%clk 0:09:08] } 10. Nd5? { (1.60 → 0.26) Mistake. Nb5 was best. } { [%eval 0.26] [%clk 0:08:03] } (10. Nb5 Kd7 11. Nxd4 g6 12. c3 Bg7 13. Nc2 Re8 14. Re1 Ne7 15. g3 f5 16. Kg2 a5) 10... O-O-O { [%eval 0.31] [%clk 0:09:00] }
''';

      final pgnData = parsePgn(pgn);
      expect(
        pgnData.moves,
        equals([
          'e4',
          'e5',
          'Nf3',
          'd6',
          'Bb5+',
          'Bd7',
          'Nc3',
          'Nc6',
          'O-O',
          'Nd4',
          'Bxd7+',
          'Qxd7',
          'd3',
          'Qg4',
          'Nxd4',
          'Qxd1',
          'Rxd1',
          'exd4',
          'Nd5',
          'O-O-O',
        ]),
      );

      final game = pgnData.buildGame();
      expect(game.moveHistory.length, equals(20));
    });
  });
}
