import 'package:bishop/bishop.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Hopper Pieces', () {
    List<HopperTest> tests = [
      HopperTest(
        name: 'Cannon - Simple',
        fen: '4c3/8/1k6/8/8/2K1c3/8/4C3 w - - 0 1',
        numMoves: 9,
      ),
      HopperTest(
        name: 'Cannon - Simple, Mate',
        fen: '4c3/8/2k5/8/8/2K1c3/8/4C3 w - - 0 1',
        numMoves: 9,
        checkmate: true,
      ),
      HopperTest(
        name: 'Cannon - Complex',
        fen: '4c3/8/1k1C4/8/8/2K1c3/8/4C3 w - - 0 1',
        numMoves: 20, // Cd3 mates yourself
      ),
      HopperTest(
        name: 'Cannon - Complex, Mate',
        fen: '8/8/1k1Cc3/8/8/2K1c3/8/4C3 w - - 0 1',
        numMoves: 16,
        checkmate: true,
      ),
      HopperTest(
        name: 'Grasshopper - Simple',
        fen: '8/8/2k5/4g3/8/2K5/8/4G3 w - - 0 1',
        numMoves: 2,
      ),
      HopperTest(
        name: 'Grasshopper - Simple, Mate',
        fen: '8/8/2kG4/4g3/8/2K5/8/4G3 w - - 0 1',
        numMoves: 4,
        checkmate: true,
      ),
      HopperTest(
        name: 'Grasshopper - Complex',
        fen: '4g3/8/8/2k5/4g3/2K5/8/2gGG3 w - - 0 1',
        numMoves: 5,
      ),
      HopperTest(
        name: 'Grasshopper - Complex, Mate',
        fen: '4g3/8/8/2kG4/4g3/2K5/8/2gGG3 w - - 0 1',
        numMoves: 8,
        checkmate: true,
      ),
    ];
    Variant v = Variant(
      name: 'Cannon Test',
      startPosition: '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
      materialConditions: MaterialConditions.none,
      pieceTypes: {
        'K': PieceType.staticKing(),
        'G': PieceType.grasshopper(),
        'C': Xiangqi.cannon(),
      },
    );
    for (HopperTest t in tests) {
      test(t.name, () {
        Game g = Game(variant: v, fen: t.fen);
        final moves = g.generateLegalMoves();
        final sanMoves = moves.map((e) => g.toSan(e)).toList();
        bool checkmate = sanMoves.where((e) => e.endsWith('#')).isNotEmpty;
        expect(moves.length, t.numMoves);
        expect(checkmate, t.checkmate);
      });
    }
  });
}

class HopperTest {
  final String name;
  final String fen;
  final int numMoves;
  final bool checkmate;
  const HopperTest({
    required this.name,
    required this.fen,
    required this.numMoves,
    this.checkmate = false,
  });
}
