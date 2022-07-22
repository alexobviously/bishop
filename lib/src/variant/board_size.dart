part of 'variant.dart';

/// Specifies the dimensions of a board.
class BoardSize {
  /// The horizontal size, i.e. number of files on the board.
  final int h;

  /// The vertical size, i.e. number of ranks on the board.
  final int v;

  /// The total number of squares on a board of this size.
  int get numSquares => h * v;

  /// The total number of indices in the internal board representation.
  int get numIndices => numSquares * 2;

  /// Returns the shortest dimension.
  int get minDim => min(h, v);

  /// Returns the longest dimension.
  int get maxDim => max(h, v);

  /// Index of the last rank.
  int get maxRank => v - 1;

  /// Index of the last file.
  int get maxFile => h - 1;

  /// The number of indices required to travel one square north.
  int get north => h * 2;

  const BoardSize(this.h, this.v);

  /// A standard 8x8 board.
  static const standard = BoardSize(8, 8);

  /// A mini 6x6 board.
  static const mini = BoardSize(6, 6);

  @override
  String toString() => 'BoardSize($h, $v)';
}
