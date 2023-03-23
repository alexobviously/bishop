import 'package:bishop/bishop.dart';
import 'package:test/test.dart';

void main() {
  group('Square/Piece Representation', () {
    test('Empty', () {
      int x = Bishop.empty;
      expect(x.isEmpty, true);
      expect(x.piece, 0);
      expect(x.hasFlag(4), false);
      expect(x.inInitialState, false);
    });
    test('Simple Piece', () {
      int x = makePiece(3, Bishop.white);
      expect(x.isEmpty, false);
      expect(x.type, 3);
      expect(x.colour, Bishop.white);
      expect(x.flags, 0);
      expect(x.inInitialState, false);
    });
    test('Promoted Piece', () {
      int x = makePiece(2, Bishop.black, internalType: 1);
      expect(x.isEmpty, false);
      expect(x.type, 2);
      expect(x.internalType, 1);
      expect(x.colour, Bishop.black);
      expect(x.flags, 0);
      expect(x.piece, makePiece(2, Bishop.black));
      expect(x.inInitialState, false);
    });
    test('Piece with Flags', () {
      int x = makePiece(6, Bishop.black).setFlag(3).setFlag(7);
      expect(x.isEmpty, false);
      expect(x.type, 6);
      expect(x.hasFlag(3), true);
      expect(x.hasFlag(4), false);
      expect(x.hasFlag(7), true);
      expect(x.inInitialState, false);
    });
    test('Piece in Initial State', () {
      int x = makePiece(1, Bishop.white, initialState: true);
      expect(x.isEmpty, false);
      expect(x.type, 1);
      expect(x.inInitialState, true);
    });
    test('Compare makePiece to alterations', () {
      int x = makePiece(7, Bishop.white)
          .flipColour()
          .setFlag(7)
          .toggleFlag(8)
          .toggleFlag(4)
          .unsetFlag(8)
          .setInitialState(true)
          .setInternalType(4);
      int y = makePiece(
        7,
        Bishop.black,
        flags: makeFlags([4, 7]),
        internalType: 4,
        initialState: true,
      );
      expect(x, y);
    });
  });
}
