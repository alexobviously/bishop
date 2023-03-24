import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:bishop/bishop.dart';
import 'perft.dart';

import 'dart:math';

class PerftBenchmark extends BenchmarkBase {
  final PerftTest test;
  Game? game;

  PerftBenchmark(this.test) : super("Perft(fen:'${test.fen}')");

  @override
  void setup() {
    game = Game(variant: test.variant.build(), fen: test.fen);
  }

  @override
  void teardown() {
    game = null;
  }

  @override
  void run() {
    int t1 = 0;
    t1 = DateTime.now().millisecondsSinceEpoch;

    int result = game!.perft(test.depth);
    int t2 = DateTime.now().millisecondsSinceEpoch;
    num nps = result / ((t2 - t1) / 1000);
    npsResults.add(nps);
    if (_showNps) {
      print('${nps.toStringAsFixed(2)}nps ($result nodes) (${test.fen})');
    }

    if (result != test.nodes) {
      throw 'Wrong result: Expected <${test.nodes}> but got <$result>.';
    }
  }
}

bool _showNps = false;
List<num> npsResults = [];

void main(List<String> args) {
  if (args.isNotEmpty && args.first == 'shownps') {
    _showNps = true;
  }
  List<PerftBenchmark> perfts = [
    ...Perfts.standard.map((e) => PerftBenchmark(e)),
  ];
  double total = 0;
  for (PerftBenchmark perft in perfts) {
    double time = perft.measure();
    print(
      '${time.toStringAsFixed(2)}us [${perft.test.fen}, ${perft.test.variant.name}]',
    );
    total += time;
  }
  print('-- Total Runtime: ${(total / 1000).toStringAsFixed(2)}ms --');
  num npsAvg = npsResults.reduce((p, e) => p + e) / npsResults.length;
  num npsMin = npsResults.reduce(min);
  num npsMax = npsResults.reduce(max);
  print('-- Total Tests: ${npsResults.length}, '
      'mean NPS: ${npsAvg.toStringAsFixed(2)}, '
      'min: ${npsMin.toStringAsFixed(2)}, '
      'max: ${npsMax.toStringAsFixed(2)} --');
}

// 12/01/23, on windows machine
// 263459.50us [rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1, standard]
// 88322.57us [r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1, standard]
// 1158172.00us [8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1, standard]
// 406882.00us [r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1, standard]
// 2271406.50us [rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8, standard]
// 3559100.50us [r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10, standard]
// -- Total Runtime: 7747.34ms --
