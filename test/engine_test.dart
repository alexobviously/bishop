import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Killer Move Heuristic', () {
    late Game game;
    late Engine engine;

    setUp(() {
      game = Game();
      engine = Engine(game: game);
    });

    test('Initial killer moves table is empty', () {
      for (int ply = 0; ply < Engine.maxPly; ply++) {
        expect(engine.killersFor(ply), equals([null, null]));
      }
    });

    test('orderMoves prioritizes killer moves over standard quiet moves', () {
      final moves = game.generateLegalMoves();
      final e2e4 = moves.firstWhere(
        (m) => game.toAlgebraic(m) == 'e2e4',
      );
      final d2d4 = moves.firstWhere(
        (m) => game.toAlgebraic(m) == 'd2d4',
      );
      final g1f3 = moves.firstWhere(
        (m) => game.toAlgebraic(m) == 'g1f3',
      );

      // Initially at ply 0 (no killers active)
      expect(engine.scoreMove(e2e4, null, 0), equals(0));

      // Store d2d4 first, then e2e4 to test slot shifting:
      // e2e4 becomes Killer 1 (slot 0), d2d4 becomes Killer 2 (slot 1)
      engine.storeKiller(1, d2d4);
      engine.storeKiller(1, e2e4);

      expect(engine.scoreMove(e2e4, null, 1), equals(9000));
      expect(engine.scoreMove(d2d4, null, 1), equals(8000));
      expect(engine.scoreMove(g1f3, null, 1), equals(0));

      final ordered = engine.orderMoves(moves, null, 1);
      expect(ordered.first, equals(e2e4));
      expect(ordered[1], equals(d2d4));
    });

    test(
      'Killer move table stores up to 2 distinct quiet moves per ply',
      () async {
        // Search a position where quiet moves cause cutoffs
        final tacticalGame = Game(
          fen: 'r1bqk2r/pppp1ppp/2n5/4p3/1b2P3/2NP1N2/PPP2PPP/R1BQKB1R w KQkq - 1 5',
        );
        final eng = Engine(game: tacticalGame);
        await eng.search(maxDepth: 3);

        // Verify that after search, killers exist and are quiet moves
        bool foundKiller = false;
        for (int ply = 0; ply < Engine.maxPly; ply++) {
          final killers = eng.killersFor(ply);
          for (final k in killers) {
            if (k != null) {
              foundKiller = true;
              expect(k.capture, isFalse, reason: 'Killers must be quiet moves');
            }
          }
        }
        expect(
          foundKiller,
          isTrue,
          reason: 'Search should have populated killer moves',
        );
      },
    );

    test('clearKillers resets all entries to null', () async {
      final tacticalGame = Game(
        fen: 'r1bqk2r/pppp1ppp/2n5/4p3/1b2P3/2NP1N2/PPP2PPP/R1BQKB1R w KQkq - 1 5',
      );
      final eng = Engine(game: tacticalGame);
      await eng.search(maxDepth: 3);

      eng.clearKillers();
      for (int ply = 0; ply < Engine.maxPly; ply++) {
        expect(eng.killersFor(ply), equals([null, null]));
      }
    });

    test(
      'Killers rank below captures and hash move, but above regular quiet moves',
      () {
        final capGame = Game(
          fen: 'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        );
        final eng = Engine(game: capGame);
        final moves = capGame.generateLegalMoves();

        final captureMove = moves.firstWhere((m) => m.capture); // exd5
        final quietMove = moves.firstWhere(
          (m) => !m.capture && !m.castling && capGame.toAlgebraic(m) == 'g1f3',
        );
        final anotherQuiet = moves.firstWhere(
          (m) => !m.capture && !m.castling && capGame.toAlgebraic(m) == 'b1c3',
        );

        // Store quietMove as Killer 1 at ply 2
        eng.storeKiller(2, quietMove);

        final hashScore = eng.scoreMove(quietMove, quietMove, 2);
        final captureScore = eng.scoreMove(captureMove, null, 2);
        final killerScore = eng.scoreMove(quietMove, null, 2);
        final baseQuietScore = eng.scoreMove(anotherQuiet, null, 2);

        expect(hashScore, equals(100000));
        expect(captureScore, greaterThan(10000));
        expect(killerScore, equals(9000));
        expect(baseQuietScore, equals(0));

        expect(hashScore, greaterThan(captureScore));
        expect(captureScore, greaterThan(killerScore));
        expect(killerScore, greaterThan(baseQuietScore));
      },
    );

    test('Engine finds checkmate with killer heuristic active', () async {
      // Mate in 1: Scholar's mate position
      final mateGame = Game(
        fen: 'r1bqkb1r/pppp1ppp/2n5/4p3/2B1n3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 5',
      );
      final eng = Engine(game: mateGame);
      final result = await eng.search(maxDepth: 2);

      expect(result.hasMove, isTrue);
      expect(mateGame.toAlgebraic(result.move!), 'f3f7');
    });
  });
}
