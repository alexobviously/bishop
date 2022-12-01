import 'package:bishop/bishop.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

/*

 +---+---+---+---+---+---+---+---+---+---+
 |   |   |   | r |   | n |   |   |   | r |10
 +---+---+---+---+---+---+---+---+---+---+
 |   | n |   | q | k | c |   | b |   |   |9
 +---+---+---+---+---+---+---+---+---+---+
 | p |   |   |   | p | p |   | p |   |   |8
 +---+---+---+---+---+---+---+---+---+---+
 |   |   | p |   |   | P |   | a | p |   |7
 +---+---+---+---+---+---+---+---+---+---+
 |   |   |   |   |   |   | p |   |   | p |6
 +---+---+---+---+---+---+---+---+---+---+
 |   |   | Q | P |   |   | P |   |   |   |5
 +---+---+---+---+---+---+---+---+---+---+
 |   |   |   |   |   |   |   | B | P |   |4
 +---+---+---+---+---+---+---+---+---+---+
 | P |   |   |   | P |   |   | P |   | P |3
 +---+---+---+---+---+---+---+---+---+---+
 |   |   | B |   | K | C | A |   | N |   |2
 +---+---+---+---+---+---+---+---+---+---+
 | R |   |   |   |   | R |   |   |   |   |1 *
 +---+---+---+---+---+---+---+---+---+---+
   a   b   c   d   e   f   g   h   i   j

Fen: 3r1n3r/1n1qkc1b2/p3pp1p2/2p2P1ap1/6p2p/2QP2P3/7BP1/P3P2P1P/2B1KCA1N1/R4R4 w - - 1 19
*/

void main() {
  group('Misc', () {
    test('Grand Chess Promote', () {
      Game g = Game(
        variant: Variant.grand(),
      );
      List<String> moves =
          'f3f5,i8i7,i3i4,g9h7,h2i3,g8g7,d3d4,c8c7,f5f6,g7g6,g3g5,h7i5,i3h4,i5h7,c3c4,j8j6,d4d5,i9g8,d2d4,b8b7,j1f1,c9a7,c4c5,b7b6,b3b4,b6c5,b4c5,d8d6,b2d3,a7c5,d3c5,d6c5,d4c5,a10d10,f6f7,g8f10'
              .split(',');
      for (String m in moves) {
        bool ok = g.makeMoveString(m);
        expect(ok, true);
      }
      List<Move> gmoves = g.generateLegalMoves();
      //expected moves f7e8 f7e8n
      Set<String> f7moves = {};
      for (Move m in gmoves) {
        String alg = g.toAlgebraic(m);
        if (alg.startsWith('f7')) f7moves.add(alg);
      }
      expect(f7moves.contains('f7e8'), true);
      expect(f7moves.contains('f7e8n'), true);
      expect(f7moves.length, 2);
    });
  });
}
