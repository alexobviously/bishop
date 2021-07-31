import 'dart:math';

import 'package:squares/squares.dart';

class Zobrist {
  static const int META = 0;
  late List<List<int>> table;

  late int CASTLING;
  late int TURN;

  Zobrist(Variant variant, int seed) {
    init(variant, seed);
  }

  void init(Variant variant, int seed) {
    const int NUM_AUX = 16; // we need some extra entries for castling rights, ep, etc
    const int PARTS = 4;
    Random r = Random(seed);
    int numEntries = variant.boardSize.numIndices + NUM_AUX;
    int numPieces = variant.pieces.length * 2;
    CASTLING = numPieces + 1;
    TURN = numPieces + 2;
    table = List<List<int>>.generate(numEntries, (i) => List<int>.generate(numPieces, (j) => 0));
    for (int i = 0; i < numEntries; i++) {
      for (int j = 0; j < numPieces; j++) {
        int value = 0;
        for (int k = 0; k < PARTS; k++) {
          // compute a random 64 bit int
          int part = r.nextInt(1 << 16); // 16 bit because max value is 2^32-1
          value <<= 16;
          value += part;
        }
        table[i][j] = value;
      }
    }
  }

  int compute(State state, List<int> board) {
    int _hash = 0;
    for (int i = 0; i < board.length; i++) {
      if (board[i] != EMPTY) _hash ^= table[i][board[i]];
    }
    if (state.epSquare != null) _hash ^= table[state.epSquare!][META];
    _hash ^= table[CASTLING][state.castlingRights];
    if (state.turn == BLACK) _hash ^= table[TURN][META];

    return _hash;
  }
}
