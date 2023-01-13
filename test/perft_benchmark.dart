import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:bishop/bishop.dart';
import 'constants.dart';

class PerftBenchmark extends BenchmarkBase {
  final String fen;
  final Variants variant;
  final int depth;
  final int nodes;
  Game? game;

  PerftBenchmark(
    this.fen,
    this.depth,
    this.nodes, {
    this.variant = Variants.standard,
  }) : super("Perft(fen:'$fen')");

  @override
  void setup() {
    game = Game(variant: variant.build(), fen: fen);
  }

  @override
  void teardown() {
    game = null;
  }

  @override
  void run() {
    int result = game!.perft(depth);
    if (result != nodes) {
      throw 'Wrong result: Expected <$nodes> but got <$result>.';
    }
  }
}

void main() {
  List<PerftBenchmark> perfts = [
    PerftBenchmark(Positions.standardDefault, 3, 8902),
    PerftBenchmark(Positions.kiwiPete, 2, 2039),
    PerftBenchmark(Positions.rookPin, 4, 43238),
    PerftBenchmark(Positions.position4, 3, 9467),
    PerftBenchmark(Positions.position5, 3, 62379),
    PerftBenchmark(Positions.position6, 3, 89890),
    // PerftBenchmark(
    //   'bqnb1rkr/pp3ppp/3ppn2/2p5/5P2/P2P4/NPP1P1PP/BQ1BNRKR w HFhf - 2 9',
    //   3,
    //   12189,
    //   variant: Variants.chess960,
    // ), // used to fail, now seems fine - be aware
    // PerftBenchmark(
    //   '2nnrbkr/p1qppppp/8/1ppb4/6PP/3PP3/PPP2P2/BQNNRBKR w HEhe - 1 9',
    //   3,
    //   18002,
    //   variant: Variants.chess960,
    // ),
  ];
  double total = 0;
  for (PerftBenchmark perft in perfts) {
    double time = perft.measure();
    print('${time.toStringAsFixed(2)}us [${perft.fen}, ${perft.variant.name}]');
    total += time;
  }
  print('-- Total Runtime: ${(total / 1000).toStringAsFixed(2)}ms --');
}

// 12/01/23
// 263459.50us [rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1, standard]
// 88322.57us [r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1, standard]
// 1158172.00us [8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1, standard]
// 406882.00us [r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1, standard]
// 2271406.50us [rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8, standard]
// 3559100.50us [r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10, standard]
// -- Total Runtime: 7747.34ms --