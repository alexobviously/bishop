part of 'regions.dart';

class IntersectionRegion implements BoardRegion {
  final List<BoardRegion> regions;

  const IntersectionRegion(this.regions);

  @override
  bool contains(int file, int rank) =>
      regions.firstWhereOrNull((e) => !e.contains(file, rank)) == null;

  @override
  Set<int> squares(BoardSize size) => regions.fold<Set<int>>(
        regions.first.squares(size).toSet(),
        (a, b) => a.intersection(b.squares(size).toSet()),
      );

  @override
  IntersectionRegion translate(int x, int y) =>
      IntersectionRegion(regions.map((e) => e.translate(x, y)).toList());

  @override
  Map<String, dynamic> toJson() => {
        'type': 'intersection',
        'regions': [...regions.map((e) => e.toJson())],
      };

  @override
  String toString() => 'Intersection('
      '${regions.map((e) => e.toString()).join(', ')})';
}
