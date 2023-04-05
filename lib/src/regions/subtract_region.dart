part of 'regions.dart';

/// A region that consists of [positive], with [negative] cut out of it.
class SubtractRegion extends BoardRegion {
  final BoardRegion positive;
  final BoardRegion negative;

  const SubtractRegion(this.positive, this.negative);

  factory SubtractRegion.fromJson(Map<String, dynamic> json) => SubtractRegion(
        BoardRegion.fromJson(json['+']),
        BoardRegion.fromJson(json['-']),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'sub',
        '+': positive.toJson(),
        '-': negative.toJson(),
      };

  @override
  bool contains(int file, int rank) =>
      positive.contains(file, rank) && !negative.contains(file, rank);

  @override
  Iterable<int> squares(BoardSize size) => positive.squares(size).where(
        (e) => !negative.contains(size.file(e), size.rank(e)),
      );

  @override
  SubtractRegion translate(int x, int y) => SubtractRegion(
        positive.translate(x, y),
        negative.translate(x, y),
      );

  @override
  String toString() => 'Subtract($positive, $negative)';
}
