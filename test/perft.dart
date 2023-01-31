import 'package:bishop/bishop.dart';

import 'constants.dart';

class Perfts {
  static List<PerftTest> standard = [
    PerftTest(fen: Positions.standardDefault, depth: 3, nodes: 8902),
    PerftTest(fen: Positions.kiwiPete, depth: 2, nodes: 2039),
    PerftTest(fen: Positions.rookPin, depth: 4, nodes: 43238),
    PerftTest(fen: Positions.position4, depth: 3, nodes: 9467),
    PerftTest(fen: Positions.position5, depth: 3, nodes: 62379),
    PerftTest(fen: Positions.position6, depth: 3, nodes: 89890),
  ];

  static List<PerftTest> ruleVariants = [
    PerftTest(
      variant: Variants.crazyhouse,
      fen: '2k5/8/8/8/8/8/8/4K3[QRBNPqrbnp] w - - 0 1',
      depth: 2,
      nodes: 75353,
    ),
    // todo: atomic tests currently fail because of castling
    // it seems like lichess and pychess allow castling to both target and rook,
    // while we just allow target
    PerftTest(
      variant: Variants.atomic,
      fen: 'r4b1r/2kb1N2/p2Bpnp1/8/2Pp3p/1P1PPP2/P5PP/R3K2R b KQ - 0 1',
      depth: 2,
      nodes: 148,
    ),
    PerftTest(
      variant: Variants.atomic,
      fen: '1R4kr/4K3/8/8/8/8/8/8 b k - 0 1',
      depth: 4,
      nodes: 17915,
    ),
    // todo: figure out why this is different (12560 vs 12407)
    PerftTest(
      variant: Variants.threeCheck,
      fen: '7r/1p4p1/pk3p2/RN6/8/P5Pp/3p1P1P/4R1K1 w - - 1 39 +2+0',
      depth: 3,
      nodes: 12407,
    ),
  ];
}

class PerftTest {
  final Variants variant;
  final String fen;
  final int depth;
  final int nodes;

  PerftTest({
    this.variant = Variants.standard,
    required this.fen,
    required this.depth,
    required this.nodes,
  });
}
