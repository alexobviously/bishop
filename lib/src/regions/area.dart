part of 'regions.dart';

class Area implements Region {
  final List<Direction> directions;

  int get minX => directions.map((e) => e.h).reduce(min);
  int get minY => directions.map((e) => e.v).reduce(min);
  int get maxX => directions.map((e) => e.h).reduce(max);
  int get maxY => directions.map((e) => e.v).reduce(max);

  const Area({required this.directions});

  factory Area.fromStrings(List<String> directions) =>
      Area(directions: directions.map((e) => Direction.fromString(e)).toList());

  List<String> export() => directions.map((e) => e.simpleString).toList();

  factory Area.filled({
    required int width,
    required int height,
    int xOffset = 0,
    int yOffset = 0,
    bool omitCentre = false,
  }) {
    int xStart = -(width ~/ 2) + xOffset;
    int yStart = -(height ~/ 2) + yOffset;
    List<Direction> dirs = List.generate(
      width,
      (x) => List.generate(height, (y) => Direction(x + xStart, y + yStart)),
    ).expand((e) => e).toList();
    if (omitCentre) {
      dirs.remove(const Direction(0, 0));
    }
    return Area(directions: dirs);
  }

  factory Area.radius(int size, {bool omitCentre = false}) => Area.filled(
        width: size * 2 + 1,
        height: size * 2 + 1,
        omitCentre: omitCentre,
      );

  static const radius1 = Area(
    directions: [
      //
      Direction(-1, 1), Direction(0, 1), Direction(1, 1),
      Direction(-1, 0), Direction(0, 0), Direction(1, 0),
      Direction(-1, -1), Direction(0, -1), Direction(1, -1),
    ],
  );

  @override
  Area translate(int x, int y) =>
      Area(directions: directions.map((e) => e.translate(x, y)).toList());

  @override
  bool contains(int file, int rank) =>
      directions.contains(Direction(file, rank));

  @override
  List<int> squares(BoardSize size) {
    List<Direction> dirs = [...directions];
    dirs.removeWhere(
      (e) => e.h < 0 || e.v < 0 || e.h > size.maxFile || e.v > size.maxRank,
    );
    return dirs.map((e) => size.square(e.h, e.v)).toList();
  }
}
