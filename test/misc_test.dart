import 'package:bishop/bishop.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Misc', () {
    test('Pawn Forward Premove', () {
      Game g = Game(
        variant: Variant.standard(),
        fen: 'rn1qkbnr/ppp1pppp/2b5/3p4/2PP4/5Q2/PP2PPPP/RNB1KBNR b KQkq - 0 1',
      );
      final m = g
          .generatePremoves()
          .from(Bishop.squareNumber('d4'))
          .to(Bishop.squareNumber('d5'));
      expect(m.length, 1);
    });
  });
}
