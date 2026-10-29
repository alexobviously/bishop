import 'dart:math';

import 'package:bishop/bishop.dart';

part 'area.dart';
part 'built_region.dart';
part 'rect_region.dart';
part 'intersect_region.dart';
part 'region_effect.dart';
part 'set_region.dart';
part 'subtract_region.dart';
part 'union_region.dart';
part 'xor_region.dart';

abstract class const Region() {
  bool contains(int file, int rank);
  Iterable<int> squares(BoardSize size);
  Region translate(int x, int y);
}

abstract class const BoardRegion() extends Region {
  factory fromJson(Map<String, dynamic> json) {
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
    'set': SetRegion.fromJson,
    'dset': DirectionSetRegion.fromJson,
  };

  Map<String, dynamic> toJson();

  @override
  BoardRegion translate(int x, int y);

  factory lrbt(int? l, int? r, int? b, int? t) => RectRegion.lrbt(l, r, b, t);

  factory square(int file, int rank) => RectRegion.square(file, rank);

  factory rank(int rank) => RectRegion.rank(rank);
  factory file(int file) => RectRegion.file(file);

  BuiltRegion build(BoardSize size) =>
      BuiltRegion(squares(size).toList(), size);

  UnionRegion operator +(BoardRegion other) => UnionRegion([
    this,
    if (other is UnionRegion) ...other.regions else other,
  ]);
  IntersectRegion operator &(BoardRegion other) => IntersectRegion([
    this,
    if (other is IntersectRegion) ...other.regions else other,
  ]);
  SubtractRegion operator -(BoardRegion other) => SubtractRegion(this, other);
  XorRegion operator ^(BoardRegion other) => XorRegion(this, other);
}

class const BoardRegionAdapter() extends BishopTypeAdapter<BoardRegion> {
  @override
  BoardRegion build(Map<String, dynamic>? params) =>
      BoardRegion.fromJson(params!);

  @override
  Map<String, dynamic> export(BoardRegion e) => e.toJson();

  @override
  String get id => 'bishop.region.board';
}
