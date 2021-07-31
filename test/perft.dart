import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:squares/game.dart';
import 'package:squares/variant.dart';
import 'constants.dart';

const int STANDARD = 0;

class PerftBenchmark extends BenchmarkBase {
  final String fen;
  final int variant;
  final int depth;
  final int nodes;
  Game? game;

  PerftBenchmark(String fen, this.variant, this.depth, this.nodes)
      : this.fen = fen,
        super("Perft(fen:'$fen')");

  @override
  void setup() {
    game = Game(variant: Variant.standard(), fen: fen);
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
    //PerftBenchmark(Positions.STANDARD_DEFAULT, STANDARD, 3, 8902),
    //PerftBenchmark(Positions.STANDARD_DEFAULT, STANDARD, 4, 197281),
    //PerftBenchmark(Positions.KIWIPETE, STANDARD, 1, 48),
    //PerftBenchmark(Positions.KIWIPETE, STANDARD, 2, 2039),
    PerftBenchmark(Positions.ROOK_PIN, STANDARD, 1, 14),
  ];
  for (PerftBenchmark perft in perfts) {
    perft.report();
  }
}
