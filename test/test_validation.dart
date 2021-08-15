import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

import 'constants.dart';

void main() {
  group('Validation', () {
    List<FenTest> fens = [
      FenTest(variant: Variant.standard(), fen: Positions.STANDARD_DEFAULT, valid: true),
      FenTest(variant: Variant.standard(), fen: Positions.KIWIPETE, valid: true),
      FenTest(
          variant: Variant.standard(),
          fen: 'rnbqkbnr/ppp1pppp/8/5p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
          valid: false),
      FenTest(
          variant: Variant.standard(),
          fen: 'rnbqkbnr/ppp1ppppppppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
          valid: false),
      FenTest(
          variant: Variant.standard(),
          fen: 'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR h KQkq - 0 2',
          valid: false),
      FenTest(
          variant: Variant.chess960(),
          fen: 'r1bqkbrn/pp1p1ppQ/2n5/2p5/4P3/2p5/PPP2PPP/1RB1KBRN b Kkq - 1 6',
          valid: true),
      FenTest(
          variant: Variant.chess960(),
          fen: 'r1bqkbrn/pp1p1ppQ/2n5/2p5/4P3/2p5/PPP2PPP/1RB1KBBRN b Kkq - 1 6',
          valid: false),
      FenTest(
          variant: Variant.crazyhouse(),
          fen: 'rnbqkb1r/ppp2p1p/3p1np1/8/5p2/2NQ4/PPP2PPP/2KR1BNR[Pbp] b kq - 1 9',
          valid: true),
      FenTest(variant: Variant.mini(), fen: Positions.STANDARD_MINI, valid: true),
      FenTest(variant: Variant.mini(), fen: 'rnbqk/ppppp/10/PPPPP/RNBQK w Qq - 0 1', valid: false),
      FenTest(variant: Variant.micro(), fen: Positions.STANDARD_MICRO, valid: true),
      FenTest(variant: Variant.micro(), fen: 'knbr/p3/4/3P/RBNNK w Qk - 0 1', valid: false),
    ];

    for (FenTest ft in fens) {
      test('Validate FEN: ${ft.fen} [${ft.variant.name}]', () {
        bool valid = validateFen(variant: ft.variant, fen: ft.fen);
        expect(valid, ft.valid);
      });
    }
  });
}

class FenTest {
  final Variant variant;
  final String fen;
  final bool valid;

  FenTest({required this.variant, required this.fen, required this.valid});
}
