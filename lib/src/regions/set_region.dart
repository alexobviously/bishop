part of 'regions.dart';

class DirectionSetRegion extends BoardRegion {
  final Iterable<Direction> directions;
  const DirectionSetRegion(this.directions);

  factory DirectionSetRegion.fromJson(Map<String, dynamic> json) =>
      DirectionSetRegion(
        (json['squares'] as List)
            .map<Direction>((e) => Direction.fromString(e))
            .toSet(),
      );

  @override
  bool contains(int file, int rank) =>
      directions.contains(Direction(file, rank));

  @override
  Iterable<int> squares(BoardSize size) =>
      directions.map((e) => size.square(e.h, e.v));

  @override
  Map<String, dynamic> toJson() => {
        'type': 'dset',
        'squares': directions.map((e) => e.simpleString).toList(),
      };

  @override
  BoardRegion translate(int x, int y) =>
      DirectionSetRegion(directions.map((e) => e.translate(x, y)).toSet());

  @override
  String toString() => 'DirectionSetRegion($directions)';
}

class SetRegion extends DirectionSetRegion {
  final Iterable<String> squareNames;
  SetRegion(this.squareNames)
      : super(squareNames.map((e) => Direction.fromSquareName(e)).toSet());

  factory SetRegion.fromJson(Map<String, dynamic> json) =>
      SetRegion((json['squares'] as List).cast<String>().toSet());

  @override
  Map<String, dynamic> toJson() => {
        'type': 'set',
        'squares': squareNames.toList(),
      };

  @override
  String toString() => 'SetRegion($squareNames)';
}
