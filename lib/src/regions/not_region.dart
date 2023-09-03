part of 'regions.dart';

class NotRegion extends BoardRegion {
  final BoardRegion region;

  const NotRegion(this.region);

  factory NotRegion.fromJson(Map<String, dynamic> json) =>
      NotRegion(BoardRegion.fromJson(json['region']));

  @override
  bool contains(int file, int rank) => !region.contains(file, rank);

  @override
  Set<int> squares(BoardSize size) =>
      RectRegion.lrbt(0, size.maxFile, 0, size.maxRank)
          .squares(size)
          .difference(region.squares(size).toSet());

  @override
  NotRegion translate(int x, int y) => NotRegion(region.translate(x, y));

  @override
  Map<String, dynamic> toJson() => {
        'type': 'not',
        'region': region.toJson(),
      };

  @override
  String toString() => 'Not($region)';
}
