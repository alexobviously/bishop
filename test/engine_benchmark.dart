import 'package:bishop/bishop.dart';

class const EngineBenchmarkPosition({
  required final String name,
  required final String fen,
  final Variant? variant,
  final int targetDepth = 4,
});

final List<EngineBenchmarkPosition> benchmarkPositions = [
  const EngineBenchmarkPosition(
    name: 'Start Position',
    fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    targetDepth: 4,
  ),
  const EngineBenchmarkPosition(
    name: 'Kiwipete (Tactical Middlegame)',
    fen: 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
    targetDepth: 3,
  ),
  const EngineBenchmarkPosition(
    name: 'Tactical Pin & Captures',
    fen: 'r1bqk2r/pppp1ppp/2n5/4p3/1b2P3/2NP1N2/PPP2PPP/R1BQKB1R w KQkq - 1 5',
    targetDepth: 4,
  ),
  const EngineBenchmarkPosition(
    name: 'Pawn & Rook Endgame',
    fen: '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
    targetDepth: 4,
  ),
  EngineBenchmarkPosition(
    name: 'Capablanca Chess',
    fen: 'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1',
    variant: Variant.capablanca(),
    targetDepth: 3,
  ),
];

class const BenchmarkResult({
  required final String name,
  required final int depth,
  required final Move? bestMove,
  required final String bestMoveSan,
  required final int eval,
  required final double elapsedMs,
});

Future<void> main(List<String> args) async {
  int defaultDepth = 0;
  if (args.isNotEmpty) {
    defaultDepth = int.tryParse(args.first) ?? 0;
  }

  print('=== Bishop Engine Benchmark ===');
  print(
    'Running baseline search across ${benchmarkPositions.length} positions...\n',
  );

  List<BenchmarkResult> results = [];
  double totalTimeMs = 0;

  for (final pos in benchmarkPositions) {
    final game = Game(
      variant: pos.variant ?? Variant.standard(),
      fen: pos.fen,
    );
    final engine = Engine(game: game);
    final depth = defaultDepth > 0 ? defaultDepth : pos.targetDepth;

    final stopwatch = Stopwatch()..start();
    final res = await engine.search(
      maxDepth: depth + 1,
      timeLimit: 120000,
      timeBuffer: 120000,
    );
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;
    totalTimeMs += elapsedMs;

    final moveSan = res.move != null ? game.toSan(res.move!) : 'none';
    final result = BenchmarkResult(
      name: pos.name,
      depth: res.depth ?? 0,
      bestMove: res.move,
      bestMoveSan: moveSan,
      eval: res.eval ?? 0,
      elapsedMs: elapsedMs,
    );
    results.add(result);

    print(
      '${result.name.padRight(30)} | '
      'depth: ${result.depth} | '
      'move: ${result.bestMoveSan.padRight(7)} | '
      'eval: ${result.eval.toString().padLeft(6)} | '
      'time: ${result.elapsedMs.toStringAsFixed(1).padLeft(7)} ms',
    );
  }

  print('\n------------------------------------------------------------');
  print('Total Time: ${totalTimeMs.toStringAsFixed(1)} ms');
  print(
    'Average Time per Position: ${(totalTimeMs / results.length).toStringAsFixed(1)} ms',
  );
  print('============================================================');
}
