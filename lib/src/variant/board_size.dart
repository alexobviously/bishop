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

  /// Builds a BoardSize from a string like '8x8'.
  factory BoardSize.fromString(String str) {
    final parts = str.split('x');
    return BoardSize(int.parse(parts.first), int.parse(parts.last));
  }

  String get simpleString => '${h}x$v';

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

  /// Whether [a] and [b] are connected by a rook move.
  bool orthogonallyConnected(int a, int b) =>
      squaresOnSameFile(a, b) || squaresOnSameRank(a, b);

  /// Whether [a] and [b] are connected by a bishop move.
  bool diagonallyConnected(int a, int b) =>
      (rank(b) - rank(a)).abs() == (file(b) - file(a)).abs();

  /// Gets a Direction between [a] and [b].
  Direction directionBetween(int a, int b) =>
      Direction(file(b) - file(a), rank(b) - rank(a));

  /// [a] and [b] are square names like 'd4', 'h10'.
  Direction directionBetweenString(String a, String b) =>
      directionBetween(squareNumber(a), squareNumber(b));

  /// Determine what sort of direction connects [a] and  [b].
  DirectionType directionTypeBetween(int a, int b) =>
      directionBetween(a, b).type;

  /// [a] and [b] are square names like 'd4', 'h10'.
  DirectionType directionTypeBetweenString(String a, String b) =>
      directionTypeBetween(squareNumber(a), squareNumber(b));

  /// Whether [a] and [b] are connected by a move in [direction].
  bool connected(int a, int b, Direction direction) {
    int fileDiff = file(b) - file(a);
    if (direction.h == 0 && fileDiff != 0) return false;
    int rankDiff = rank(b) - rank(a);
    if (direction.v == 0 && rankDiff != 0) return false;
    if (direction.h != 0 && fileDiff % direction.h != 0) return false;
    if (direction.v != 0 && rankDiff % direction.v != 0) return false;
    return true;
  }

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
    if (square >= numIndices) return false;
    int x = square % (h * 2);
    return x < h;
  }

  /// Returns all the squares in [area], translated to [centre] - a square id.
  Iterable<int> squaresForArea(int centre, Area area) =>
      area.translate(file(centre), rank(centre)).squares(this);

  /// Returns all of the squares in [region].
  /// If you want to find the squares for an `Area`, use `squaresForArea()`.
  Iterable<int> squaresForRegion(Region region) => region.squares(this);

  /// Returns the name for a square, according to chess conventions, e.g. c6, b1.
  String squareName(int square) {
    int rank = v - (square ~/ (h * 2));
    int file = square % (h * 2);
    String fileName = String.fromCharCode(Bishop.asciiA + file);
    return '$fileName$rank';
  }

  /// Check whether a square name is valid for this board size.
  bool isValidSquareName(String name) {
    try {
      squareNumber(name);
    } catch (e) {
      return false;
    }
    return true;
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

  /// Gets the secret (off-board) square [i], for storing flags in.
  int secretSquare(int i) => ((i ~/ h) * 2 * h) + (i % h) + h;

  @override
  String toString() => 'BoardSize($h, $v)';

  @override
  int get hashCode => h.hashCode << 8 + v.hashCode;

  @override
  bool operator ==(Object other) =>
      other is BoardSize && other.h == h && other.v == v;
}
