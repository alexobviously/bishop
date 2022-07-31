import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

import 'constants.dart';

void main() {
  group('Validation', () {
    List<FenTest> fens = [
      FenTest(
        variant: Variant.standard(),
        fen: Positions.standardDefault,
        valid: true,
      ),
      FenTest(
        variant: Variant.standard(),
        fen: Positions.kiwiPete,
        valid: true,
      ),
      FenTest(
        variant: Variant.standard(),
        fen: 'rnbqkbnr/ppp1pppp/8/5p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        valid: false,
      ),
      FenTest(
        variant: Variant.standard(),
        fen:
            'rnbqkbnr/ppp1ppppppppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        valid: false,
      ),
      FenTest(
        variant: Variant.standard(),
        fen: 'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR h KQkq - 0 2',
        valid: false,
      ),
      FenTest(
        variant: Variant.standard(),
        fen: 'rnbqkbnr/pppppppp/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        valid: false,
      ),
      FenTest(
        variant: Variant.chess960(),
        fen: 'r1bqkbrn/pp1p1ppQ/2n5/2p5/4P3/2p5/PPP2PPP/1RB1KBRN b Kkq - 1 6',
        valid: true,
      ),
      FenTest(
        variant: Variant.chess960(),
        fen: 'r1bqkbrn/pp1p1ppQ/2n5/2p5/4P3/2p5/PPP2PPP/1RB1KBBRN b Kkq - 1 6',
        valid: false,
      ),
      FenTest(
        variant: Variant.crazyhouse(),
        fen:
            'rnbqkb1r/ppp2p1p/3p1np1/8/5p2/2NQ4/PPP2PPP/2KR1BNR[Pbp] b kq - 1 9',
        valid: true,
      ),
      FenTest(
        variant: Variant.micro(),
        fen: Positions.standardMicro,
        valid: true,
      ),
      FenTest(
        variant: Variant.micro(),
        fen: 'rnbqk/ppppp/10/PPPPP/RNBQK w Qq - 0 1',
        valid: false,
      ),
      FenTest(
        variant: Variant.nano(),
        fen: Positions.standardNano,
        valid: true,
      ),
      FenTest(
        variant: Variant.nano(),
        fen: 'knbr/p3/4/3P/RBNNK w Qk - 0 1',
        valid: false,
      ),
      FenTest(
        variant: Variant.mini(),
        fen: Positions.standardMini,
        valid: true,
      ),
      FenTest(
        variant: Variant.miniRandom(),
        fen: 'rqnqkn/pppppp/6/6/PPPPPP/RQNQKN w Kk - 0 1',
        valid: true,
      ),
      FenTest(
        variant: Musketeer.variant(),
        fen: Musketeer.defaultFen,
        valid: true,
      ),
      FenTest(
        variant: Musketeer.variant(),
        fen: '8/rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        valid: false,
      ),
      FenTest(
        variant: Musketeer.variant(),
        fen:
            '1a4o1/rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/2A2O2 w KQkq - 0 1',
        valid: true,
      ),
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

  const FenTest({
    required this.variant,
    required this.fen,
    required this.valid,
  });
}
