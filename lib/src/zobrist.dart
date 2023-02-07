import 'dart:math';
import 'package:bishop/bishop.dart';

// todo: try to make this a bit more stateless somehow?

/// Used for hashing and storing board states.
/// https://en.wikipedia.org/wiki/Zobrist_hashing
class Zobrist {
  final int seed;
  static const int meta = 0;
  late List<List<int>> table;
  Map<int, int> hashes = {};

  int? _dimX;
  int? _dimY;
  int? _castling;
  int? _turn;

  int get dimX {
    _dimX ??= table.length;
    return _dimX!;
  }

  int get dimY {
    _dimY ??= table.first.length;
    return _dimY!;
  }

  int get castling {
    _castling ??= dimY + 1;
    return _castling!;
  }

  int get turn {
    _turn ??= dimY + 2;
    return _turn!;
  }

  Zobrist(BuiltVariant variant, this.seed, {List<List<int>>? table}) {
    this.table = table ?? buildTable(variant, seed);
  }

  /// Builds a Zobrist lookup table given [variant] and [seed].
  static List<List<int>> buildTable(BuiltVariant variant, int seed) {
    const int numAux =
        16; // we need some extra entries for castling rights, ep, etc
    const int numParts = 4;
    Random r = Random(seed);
    int dimX = variant.boardSize.numIndices + numAux;
    int dimY = max(variant.pieces.length * 4, Castling.mask + 1);
    // castling = dimY + 1;
    // turn = dimY + 2;
    List<List<int>> table = List<List<int>>.generate(
      dimX,
      (i) => List<int>.generate(dimY, (j) => 0),
    );
    for (int i = 0; i < dimX; i++) {
      for (int j = 0; j < dimY; j++) {
        int value = 0;
        for (int k = 0; k < numParts; k++) {
          // compute a random 64 bit int
          int part = r.nextInt(1 << 16); // 16 bit because max value is 2^32-1
          value <<= 16;
          value += part;
        }
        table[i][j] = value;
      }
    }
    return table;
  }

  /// Computes the hash of [state].
  int compute(BishopState state) {
    List<int> board = state.board;
    int hash = 0;
    for (int i = 0; i < board.length; i++) {
      if (board[i] != Bishop.empty) hash ^= table[i][board[i]];
    }
    if (state.epSquare != null) hash ^= table[state.epSquare!][meta];
    hash ^= table[castling][state.castlingRights];
    if (state.turn == Bishop.black) hash ^= table[turn][meta];
    // todo: hands and gates

    return hash;
  }

  /// Increments the count for [hash].
  int incrementHash(int hash) {
    if (hashes.containsKey(hash)) {
      hashes[hash] = hashes[hash]! + 1;
    } else {
      hashes[hash] = 1;
    }
    return hashes[hash]!;
  }

  /// Decrements the count for [hash].
  int decrementHash(int hash) {
    if (hashes.containsKey(hash)) {
      hashes[hash] = hashes[hash]! - 1;
      int hits = hashes[hash]!;
      if (hashes[hash]! < 1) {
        hashes.remove(hash);
        hits = 0;
      }
      return hits;
    } else {
      return 0;
    }
  }

  /// Returns the number of hits for [hash].
  int hashHits(int hash) => hashes[hash] ?? 0;
}
