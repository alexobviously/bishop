import 'dart:math';
import 'package:bishop/bishop.dart';

part 'area.dart';
part 'built_region.dart';
part 'rect_region.dart';
part 'intersect_region.dart';
part 'region_effect.dart';
part 'subtract_region.dart';
part 'union_region.dart';
part 'xor_region.dart';

abstract class Region {
  const Region();
  bool contains(int file, int rank);
  Iterable<int> squares(BoardSize size);
  Region translate(int x, int y);
}

abstract class BoardRegion extends Region {
  const BoardRegion();
  factory BoardRegion.fromJson(Map<String, dynamic> json) {
    String? type = json['type'];
    if (type != null) {
      return _builders[json['type']]!(json);
    }
    return RectRegion.fromJson(json);
  }

  static const _builders = {
    'rect': RectRegion.fromJson,
    'union': UnionRegion.fromJson,
    'intersect': IntersectRegion.fromJson,
    'sub': SubtractRegion.fromJson,
    'xor': XorRegion.fromJson,
  };

  Map<String, dynamic> toJson();

  @override
  BoardRegion translate(int x, int y);

  factory BoardRegion.lrbt(int? l, int? r, int? b, int? t) =>
      RectRegion.lrbt(l, r, b, t);

  factory BoardRegion.square(int file, int rank) =>
      RectRegion.square(file, rank);

  factory BoardRegion.rank(int rank) => RectRegion.rank(rank);
  factory BoardRegion.file(int file) => RectRegion.file(file);

  BuiltRegion build(BoardSize size) =>
      BuiltRegion(squares(size).toList(), size);

  UnionRegion operator +(BoardRegion other) => UnionRegion([
        this,
        if (other is UnionRegion) ...other.regions else other,
      ]);
  SubtractRegion operator -(BoardRegion other) => SubtractRegion(this, other);
  XorRegion operator ^(BoardRegion other) => XorRegion(this, other);
}

class BoardRegionAdapter extends BishopTypeAdapter<BoardRegion> {
  @override
  BoardRegion build(Map<String, dynamic>? params) =>
      BoardRegion.fromJson(params!);

  @override
  Map<String, dynamic> export(BoardRegion e) => e.toJson();

  @override
  String get id => 'bishop.region.board';
}
