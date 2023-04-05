part of 'regions.dart';

/// A region that contains all squares that are in [left] or [right], but not
/// in both of them, i.e. XOR.
class XorRegion extends BoardRegion {
  final BoardRegion left;
  final BoardRegion right;

  const XorRegion(this.left, this.right);

  factory XorRegion.fromJson(Map<String, dynamic> json) => XorRegion(
        BoardRegion.fromJson(json['l']),
        BoardRegion.fromJson(json['r']),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'xor',
        'l': left.toJson(),
        'r': right.toJson(),
      };

  @override
  bool contains(int file, int rank) =>
      left.contains(file, rank) ^ right.contains(file, rank);

  @override
  Iterable<int> squares(BoardSize size) {
    final l = left.squares(size);
    final r = right.squares(size);
    return l
        .where((e) => !r.contains(e))
        .followedBy(r.where((e) => !l.contains(e)));
  }

  @override
  XorRegion translate(int x, int y) =>
      XorRegion(left.translate(x, y), right.translate(x, y));
}
