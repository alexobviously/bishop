part of 'regions.dart';

/// A region that is created from a `BoardRegion` when `BuiltVariant` is built.
class BuiltRegion implements Region {
  final List<int> boardSquares;
  final BoardSize size;

  const BuiltRegion(this.boardSquares, this.size);

  bool containsSquare(int square) => boardSquares.contains(square);

  @override
  bool contains(int file, int rank) => containsSquare(size.square(file, rank));

  @override
  List<int> squares(BoardSize size) => boardSquares;

  @override
  Region translate(int x, int y) => BuiltRegion(
        boardSquares
            .map((e) => size.square(size.file(e) + x, size.rank(e) + y))
            .toList(),
        size,
      );
}
