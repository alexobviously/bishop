import 'package:bishop/bishop.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'constants.dart';

void main() {
  group('Regions', () {
    final r1 = BoardRegion.lrbt(
      Bishop.fileA,
      Bishop.fileC,
      Bishop.rank1,
      Bishop.rank3,
    );
    final r2 = BoardRegion.lrbt(
      Bishop.fileC,
      Bishop.fileE,
      Bishop.rank3,
      Bishop.rank5,
    );
    final vv = Variant(
      name: 'Region Test Variant',
      boardSize: BoardSize.standard,
      startPosition: Positions.standardDefault,
      pieceTypes: {'B': PieceType.bishop()},
      regions: {
        'union': UnionRegion([r1, r2]),
        'inter': IntersectRegion([r1, r2]),
      },
    );
    List<InRegionTest> tests = [
      InRegionTest(
        region: 'redPalace',
        square: 'd1',
        inRegion: true,
      ),
      InRegionTest(
        region: 'redPalace',
        square: 'f6',
        inRegion: false,
      ),
      InRegionTest(
        region: 'blackSide',
        square: 'h7',
        inRegion: true,
      ),
      InRegionTest(
        region: 'redSide',
        square: 'h7',
        inRegion: false,
      ),
      InRegionTest(
        variant: vv,
        region: 'union',
        square: 'a2',
        inRegion: true,
      ),
      InRegionTest(
        variant: vv,
        region: 'union',
        square: 'b4',
        inRegion: false,
      ),
      InRegionTest(
        variant: vv,
        region: 'inter',
        square: 'a2',
        inRegion: false,
      ),
      InRegionTest(
        variant: vv,
        region: 'inter',
        square: 'c3',
        inRegion: true,
      ),
    ];
    for (InRegionTest t in tests) {
      test('Region test: ${t.region}/${t.square}', () {
        Variant v = t.variant ?? Xiangqi.variant();
        final size = v.boardSize;
        BoardRegion region = v.regions[t.region]!;
        int square = size.squareNumber(t.square);
        bool inRegion = size.inRegion(square, region);
        expect(inRegion, t.inRegion);
      });
    }
    test('Region Equality & Operators', () {
      final r1 = BoardRegion.lrbt(0, 3, 0, 7);
      final r2 = BoardRegion.lrbt(4, 7, 0, 7);
      expect(r1.equals(~r2), true);
      final r3 = BoardRegion.lrbt(0, 1, 0, 7);
      final r4 = BoardRegion.lrbt(2, 3, 0, 7);
      expect(r1.equals(r3 + r4), true);
      expect(r2.equals(~(r3 + r4)), true);
      final r5 = BoardRegion.lrbt(1, 3, 1, 3);
      final r6 = BoardRegion.lrbt(2, 4, 2, 4);
      expect((r5 & r6).equals((r5 + r6) - (r5 ^ r6)), true);
    });
  });
}

class InRegionTest {
  final Variant? variant;
  final String region;
  final String square;
  final bool inRegion;
  const InRegionTest({
    this.variant,
    required this.region,
    required this.square,
    required this.inRegion,
  });
}
