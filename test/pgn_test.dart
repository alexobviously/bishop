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
  });
}
