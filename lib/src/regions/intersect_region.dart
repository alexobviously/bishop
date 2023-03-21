part of 'regions.dart';

class IntersectRegion implements BoardRegion {
  final List<BoardRegion> regions;

  const IntersectRegion(this.regions);

  factory IntersectRegion.fromJson(Map<String, dynamic> json) =>
      IntersectRegion(
        (json['regions'] as List).map((e) => BoardRegion.fromJson(e)).toList(),
      );

  @override
  bool contains(int file, int rank) =>
      regions.firstWhereOrNull((e) => !e.contains(file, rank)) == null;

  @override
  Set<int> squares(BoardSize size) => regions.fold<Set<int>>(
        regions.first.squares(size).toSet(),
        (a, b) => a.intersection(b.squares(size).toSet()),
      );

  @override
  IntersectRegion translate(int x, int y) =>
      IntersectRegion(regions.map((e) => e.translate(x, y)).toList());

  @override
  Map<String, dynamic> toJson() => {
        'type': 'intersect',
        'regions': [...regions.map((e) => e.toJson())],
      };

  @override
  String toString() => 'Intersection('
      '${regions.map((e) => e.toString()).join(', ')})';
}
