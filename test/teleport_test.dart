import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Teleportation', () {
    final v = Variant(
      name: 'Pseudo-duck',
      startPosition: 'b3/4/4/3B w - - 0 1',
      boardSize: const BoardSize(4, 4),
      pieceTypes: {
        'M': PieceType.fromBetza('m*'),
        'C': PieceType.fromBetza('c*'),
        'B': PieceType.fromBetza('*'),
      },
    );
    test('Move Definitions', () {
      final a = PieceType.fromBetza('*');
      expect(a.moves.length, 1);
      expect(a.moves.first, isA<TeleportMoveDefinition>());
      expect(a.moves.first.modality, Modality.both);

      final b = PieceType.fromBetza('m*cfhN');
      expect(b.moves.length, 5);
      expect(b.moves.first, isA<TeleportMoveDefinition>());
      expect(b.moves.first.modality, Modality.quiet);
      expect(b.moves.last, isA<StandardMoveDefinition>());
    });
    test('Quiet', () {
      final g = Game(variant: v, fen: 'bbbb/4/4/3M w - - 0 1');
      final moves = g.generateLegalMoves();
      expect(moves.length, 11);
    });
    test('Capture', () {
      final g = Game(variant: v, fen: 'bbbb/4/4/3C w - - 0 1');
      final moves = g.generateLegalMoves();
      expect(moves.length, 4);
    });
    test('Both', () {
      final g = Game(variant: v, fen: 'bbbb/4/4/3B w - - 0 1');
      final moves = g.generateLegalMoves();
      expect(moves.length, 15);
    });
    test('Mix', () {
      final g = Game(variant: v, fen: 'bbbb/4/4/2CM w - - 0 1');
      final moves = g.generateLegalMoves();
      expect(moves.length, 14);
    });
  });
}
