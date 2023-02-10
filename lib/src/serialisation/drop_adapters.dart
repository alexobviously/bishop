part of 'serialisation.dart';

class StandardDropAdapter extends BishopTypeAdapter<StandardDropBuilder> {
  @override
  String get id => 'bishop.drops.standard';

  @override
  StandardDropBuilder build(Map<String, dynamic>? params) =>
      StandardDropBuilder();

  @override
  Map<String, dynamic>? export(StandardDropBuilder e) => null;
}

class UnrestrictedDropAdapter
    extends BishopTypeAdapter<UnrestrictedDropBuilder> {
  @override
  String get id => 'bishop.drops.unrestricted';

  @override
  UnrestrictedDropBuilder build(Map<String, dynamic>? params) =>
      UnrestrictedDropBuilder();

  @override
  Map<String, dynamic>? export(UnrestrictedDropBuilder e) => null;
}

class RegionDropAdapter extends BishopTypeAdapter<RegionDropBuilder> {
  @override
  String get id => 'bishop.drops.region';

  @override
  RegionDropBuilder build(Map<String, dynamic>? params) =>
      RegionDropBuilder(BoardRegion.fromJson(params!['region']));

  @override
  Map<String, dynamic> export(RegionDropBuilder e) =>
      {'region': e.region.toJson()};
}
