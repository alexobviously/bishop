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

  /// A Xiangqi board.
  static const xiangqi = BoardSize(9, 10);

  /// Returns the rank that [square] is on.
  int file(int square) => square % (h * 2);

  /// Returns that file that [square] is on.
  int rank(int square) => v - (square ~/ (h * 2)) - 1;

  /// Gets the square index at [file] and [rank].
  int square(int file, int rank) => (v - rank - 1) * (h * 2) + file;

  /// Returns true if [a] and [b] are facing.
  /// Useful for Xiangqi's flying generals rule.
  bool squaresOnSameFile(int a, int b) => file(a) == file(b);

  /// Returns true if [a] and [b] are on the same rank.
  bool squaresOnSameRank(int a, int b) => rank(a) == rank(b);

  /// Get the first rank for player [colour].
  int firstRank(int colour) => colour == Bishop.white ? Bishop.rank1 : maxRank;

  /// Get the last rank (i.e. promotion rank) for player [colour].
  int lastRank(int colour) => firstRank(colour.opponent);

  // Returns true if [square] is within the bounds of [region].
  bool inRegion(int square, Region region) =>
      region.contains(file(square), rank(square));

  /// Determines whether a square is on the board.
  bool onBoard(int square) {
    if (square < 0) return false;
    if (square >= numSquares * 2) return false;
    int x = square % (h * 2);
    return x < h;
  }

  List<int> squaresForArea(int centre, Area area) =>
      area.translate(file(centre), rank(centre)).squares(this);

  /// Returns the name for a square, according to chess conventions, e.g. c6, b1.
  String squareName(int square) {
    int rank = v - (square ~/ (h * 2));
    int file = square % (h * 2);
    String fileName = String.fromCharCode(Bishop.asciiA + file);
    return '$fileName$rank';
  }

  /// Returns the square id for a square with [name].
  int squareNumber(String name) {
    name = name.toLowerCase();
    RegExp rx = RegExp(r'([A-Za-z])([0-9]+)');
    RegExpMatch? match = rx.firstMatch(name);
    assert(match != null, 'Invalid square name: $name');
    assert(match!.groupCount == 2, 'Invalid square name: $name');
    String file = match!.group(1)!;
    String rank = match.group(2)!;
    int fileNum = file.codeUnits[0] - Bishop.asciiA;
    int rankNum = v - int.parse(rank);
    int square = rankNum * h * 2 + fileNum;
    return square;
  }

  @override
  String toString() => 'BoardSize($h, $v)';
}
