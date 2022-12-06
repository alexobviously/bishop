import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

/*
 +---+---+---+---+---+---+---+---+
 | r |   |   | q | k |   |   | n |8   [qp]
 +---+---+---+---+---+---+---+---+
 |   |   | p |   |   |   |   |   |7
 +---+---+---+---+---+---+---+---+
 |   |   | b |   | p | p | b |   |6
 +---+---+---+---+---+---+---+---+
 | p | p |   | p | P |   | B | n |5
 +---+---+---+---+---+---+---+---+
 |   |   |   |   |   |   |   | p |4
 +---+---+---+---+---+---+---+---+
 |   |   |   |   |   | P |   |   |3
 +---+---+---+---+---+---+---+---+
 | P | P | P | P |   |   | P | P |2
 +---+---+---+---+---+---+---+---+
 | R | N | B |   |   | R | K |   |1 * [RN]
 +---+---+---+---+---+---+---+---+
   a   b   c   d   e   f   g   h

Fen: r2qk2n/2p5/2b1ppb1/pp1pP1Bn/7p/5P2/PPPP2PP/RNB2RK1[RNqp] w q - 0 31
*/

void main() {
  group('Misc', () {
    test('Crazyhouse take promoted pawn', () {
      Game g = Game(variant: Variant.crazyhouse());
      List<String> moves =
          'e2e3,d7d5,d1f3,g8f6,f3f4,b8c6,f1b5,c8d7,b5c6,d7c6,g1e2,b@d6,n@e5,d6e5,f4e5,n@g4,e5g3,e7e6,f2f3,f8d6,b@f4,d6f4,g3f4,b@e5,f4b4,a7a5,b4c5,e5d6,c5c3,d6b4,c3d3,g4e5,d3d4,e5d7,b@g3,b4c5,d4d3,b7b5,e1g1,h7h5,e2d4,c5d4,e3d4,h5h4,g3f4,f6h5,f4e3,g7g5,b@e5,f7f6,d3g6,n@f7,e3g5,d7e5,d4e5,b@f5,p@g7,f5g6,g7h8q,f7h8'
              .split(',');
      for (String m in moves) {
        bool ok = g.makeMoveString(m);
        expect(ok, true);
      }

      expect(g.handString, 'NRqp');
    });
    test('Put pawn on first, last lane', () {
      Game g = Game(
        variant: Variant.crazyhouse(),
      );
      List<String> moves = [
        'e2e4',
        'e7e5',
        'd2d4',
        'e5d4',
        'd1f3',
        'g8f6',
        'c1g5'
      ];
      for (String m in moves) {
        bool ok = g.makeMoveString(m);
        expect(ok, true);
      }
      List<Move> gmoves = g.generateLegalMoves();
      Set<String> smoves = {};
      for (Move m in gmoves) {
        smoves.add(g.toAlgebraic(m));
      }
      expect(smoves.contains('p@e7'), true);
      expect(smoves.contains('p@d1'), false);
      expect(smoves.contains('p@g8'), false);
    });
  });
}
