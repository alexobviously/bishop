import 'package:bishop/bishop.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

import 'constants.dart';

void main() {
  final List<CompareTest> tests = [
    CompareTest(
      variant: Variant.standard(),
      pos1: Positions.standardDefault,
      pos2: Positions.standardDefault,
    ),
    CompareTest(
      variant: Variant.standard(),
      pos1: 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2',
      pos2: Positions.standardDefault,
      moves: ['e2e4', 'c7c5'],
    ),
    CompareTest(
      variant: Variant.standard(),
      pos1: 'rnbqkbnr/pp2pppp/8/2pP4/8/5N2/PPPP1PPP/RNBQKB1R b KQkq - 0 3',
      pos2: 'rnbqkbnr/pp2pppp/8/2pp4/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3',
      moves: ['e4d5'],
    ),
    CompareTest(
      variant: Variant.threeCheck(),
      pos1: 'rnbqkbnr/pppQpppp/8/8/4p3/8/PPPP1PPP/RNB1KBNR b KQkq - 1 3 +1+0',
      pos2: Positions.standardDefault,
      moves: ['e2e4', 'd7d5', 'd1g4', 'd5e4', 'g4d7'],
    ),
  ];
  group('Zobrist Hashing', () {
    for (CompareTest t in tests) {
      test('Compare hashes: ${t.pos1} vs ${t.pos2} after ${t.moves}', () {
        Game g1 = Game(variant: t.variant, fen: t.pos1);
        int h1 = g1.state.hash;
        Game g2 = Game(variant: t.variant, fen: t.pos2);
        for (String m in t.moves) {
          Move? move = g2.getMove(m);
          if (move != null) {
            g2.makeMove(move);
          } else {
            fail('Move $m not found');
          }
        }
        int h2 = g2.state.hash;
        if (h1 != h2) {
          print(' --- Failure details --- ');
          print('Hashes: $h1, $h2');
          print('FEN 1: ${g1.fen}');
          print('FEN 2: ${g2.fen}');
          print(g1.fen == g2.fen ? 'FENs match' : 'FENs don\'t match');
          print(' ----------------------- ');
        }
        expect(h1, h2);
      });
    }
  });
  group('Piece Counting', () {
    for (CompareTest t in tests) {
      test('Compare pieces: ${t.pos1} vs ${t.pos2} after ${t.moves}', () {
        Game g1 = Game(variant: t.variant, fen: t.pos1);
        List<int> p1 = g1.state.pieces;
        Game g2 = Game(variant: t.variant, fen: t.pos2);
        for (String m in t.moves) {
          Move? move = g2.getMove(m);
          if (move != null) {
            g2.makeMove(move);
          } else {
            fail('Move $m not found');
          }
        }
        List<int> p2 = g2.state.pieces;
        if (!ListEquality().equals(p1, p2)) {
          print(' --- Failure details --- ');
          print('Pieces: $p1, $p2');
          print('FEN 1: ${g1.fen}');
          print('FEN 2: ${g2.fen}');
          print(g1.fen == g2.fen ? 'FENs match' : 'FENs don\'t match');
          print(' ----------------------- ');
        }
        expect(p1, p2);
      });
    }
  });
}

class CompareTest {
  final Variant variant;
  final String pos1;
  final String pos2;
  final List<String> moves;

  const CompareTest({
    required this.variant,
    required this.pos1,
    required this.pos2,
    this.moves = const [],
  });
}
