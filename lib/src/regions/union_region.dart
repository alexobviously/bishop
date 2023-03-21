part of 'regions.dart';

class UnionRegion implements BoardRegion {
  final List<BoardRegion> regions;

  const UnionRegion(this.regions);

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
}
