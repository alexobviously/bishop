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

  PerftBenchmark(this.fen, this.variant, this.depth, this.nodes) : super("Perft(fen:'$fen')");

  @override
  void setup() {
    Map<int, Variant> variants = {
      standard: Variant.standard(),
      CHESS960: Variant.chess960(),
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
  List<PerftBenchmark> perfts = [
    PerftBenchmark(Positions.STANDARD_DEFAULT, standard, 3, 8902),
    PerftBenchmark(Positions.KIWIPETE, standard, 2, 2039),
    PerftBenchmark(Positions.ROOK_PIN, standard, 4, 43238),
    PerftBenchmark(Positions.POSITION_4, standard, 3, 9467),
    PerftBenchmark(Positions.POSITION_5, standard, 3, 62379),
    PerftBenchmark(Positions.POSITION_6, standard, 3, 89890),
    // PerftBenchmark('bqnb1rkr/pp3ppp/3ppn2/2p5/5P2/P2P4/NPP1P1PP/BQ1BNRKR w HFhf - 2 9', CHESS960, 3, 12189), // fails
    //PerftBenchmark('2nnrbkr/p1qppppp/8/1ppb4/6PP/3PP3/PPP2P2/BQNNRBKR w HEhe - 1 9', CHESS960, 3, 18002),
  ];
  for (PerftBenchmark perft in perfts) {
    perft.report();
  }
}
