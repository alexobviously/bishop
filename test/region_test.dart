import 'package:bishop/bishop.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Regions', () {
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
