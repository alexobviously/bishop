part of 'regions.dart';

/// A region that contains all of the squares of each region in [regions].
class UnionRegion extends BoardRegion {
  final List<BoardRegion> regions;

  const UnionRegion(this.regions);

  factory UnionRegion.fromJson(Map<String, dynamic> json) => UnionRegion(
        (json['regions'] as List).map((e) => BoardRegion.fromJson(e)).toList(),
      );

  @override
  bool contains(int file, int rank) =>
      regions.firstWhereOrNull((e) => e.contains(file, rank)) != null;

  @override
  Set<int> squares(BoardSize size) =>
      regions.expand((e) => e.squares(size)).toSet();

  @override
  UnionRegion translate(int x, int y) =>
      UnionRegion(regions.map((e) => e.translate(x, y)).toList());

  @override
  Map<String, dynamic> toJson() => {
        'type': 'union',
        'regions': [...regions.map((e) => e.toJson())],
      };

  @override
  String toString() => 'Union(${regions.map((e) => e.toString()).join(', ')})';

  @override
  UnionRegion operator +(BoardRegion other) => UnionRegion([...regions, other]);
}
