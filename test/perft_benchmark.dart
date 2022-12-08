import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:bishop/bishop.dart';
import 'constants.dart';

const int standard = 0;

class PerftBenchmark extends BenchmarkBase {
  final String fen;
  final int variant;
  final int depth;
  final int nodes;
  Game? game;

  PerftBenchmark(this.fen, this.variant, this.depth, this.nodes)
      : super("Perft(fen:'$fen')");

  @override
  void setup() {
    Map<int, Variant> variants = {
      standard: Variant.standard(),
      chess960: Variant.chess960(),
    };
    game = Game(variant: variants[variant]!, fen: fen);
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
  int startTime = DateTime.now().millisecondsSinceEpoch;
  List<PerftBenchmark> perfts = [
    PerftBenchmark(Positions.standardDefault, standard, 3, 8902),
    PerftBenchmark(Positions.kiwiPete, standard, 2, 2039),
    PerftBenchmark(Positions.rookPin, standard, 4, 43238),
    PerftBenchmark(Positions.position4, standard, 3, 9467),
    PerftBenchmark(Positions.position5, standard, 3, 62379),
    PerftBenchmark(Positions.position6, standard, 3, 89890),
    // PerftBenchmark('bqnb1rkr/pp3ppp/3ppn2/2p5/5P2/P2P4/NPP1P1PP/BQ1BNRKR w HFhf - 2 9', CHESS960, 3, 12189), // fails
    //PerftBenchmark('2nnrbkr/p1qppppp/8/1ppb4/6PP/3PP3/PPP2P2/BQNNRBKR w HEhe - 1 9', CHESS960, 3, 18002),
  ];
  for (PerftBenchmark perft in perfts) {
    perft.report();
  }
  int runTime = DateTime.now().millisecondsSinceEpoch - startTime;
  print('-- Total Runtime: $runTime ms --');
}

// 08/12/2022 before region changes
// Perft(fen:'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')(RunTime): 259431.75 us.
// Perft(fen:'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1')(RunTime): 96030.33333333333 us.
// Perft(fen:'8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1')(RunTime): 1068963.5 us.
// Perft(fen:'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1')(RunTime): 430368.8 us.
// Perft(fen:'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8')(RunTime): 2365476.0 us.
// Perft(fen:'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10')(RunTime): 4026768.0 us.
// -- Total Runtime: 15905 ms --