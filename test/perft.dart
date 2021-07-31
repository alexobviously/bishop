import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:squares/squares.dart';
import 'constants.dart';

const int STANDARD = 0;

class PerftBenchmark extends BenchmarkBase {
  final String fen;
  final int variant;
  final int depth;
  final int nodes;
  Squares? game;

  PerftBenchmark(String fen, this.variant, this.depth, this.nodes)
      : this.fen = fen,
        super("Perft(fen:'$fen')");

  @override
  void setup() {
    game = Squares(variant: Variant.standard(), fen: fen);
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
    PerftBenchmark(Positions.STANDARD_DEFAULT, STANDARD, 3, 8902),
    PerftBenchmark(Positions.KIWIPETE, STANDARD, 2, 2039),
    PerftBenchmark(Positions.ROOK_PIN, STANDARD, 4, 43238),
    PerftBenchmark(Positions.POSITION_4, STANDARD, 3, 9467),
    //PerftBenchmark(Positions.POSITION_5, STANDARD, 3, 62379), // broken - check promotion to rook
    //PerftBenchmark(Positions.POSITION_5, STANDARD, 2, 1486),
    PerftBenchmark(Positions.POSITION_6, STANDARD, 3, 89890),
  ];
  for (PerftBenchmark perft in perfts) {
    perft.report();
  }
}
