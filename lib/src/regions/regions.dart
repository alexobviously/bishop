import 'dart:math';
import 'package:bishop/bishop.dart';

part 'area.dart';
part 'rect_region.dart';
part 'intersect_region.dart';
part 'region_effect.dart';
part 'union_region.dart';

abstract class Region {
  bool contains(int file, int rank);
  Iterable<int> squares(BoardSize size);
  Region translate(int x, int y);
}

abstract class BoardRegion extends Region {
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
    'intersect': IntersectRegion.fromJson
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
