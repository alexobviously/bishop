part of 'serialisation.dart';

class StandardDropAdapter extends BasicAdapter<StandardDropBuilder> {
  const StandardDropAdapter()
      : super('bishop.drops.standard', StandardDropBuilder.new);
}

class UnrestrictedDropAdapter extends BasicAdapter<UnrestrictedDropBuilder> {
  const UnrestrictedDropAdapter()
      : super('bishop.drops.unrestricted', UnrestrictedDropBuilder.new);
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
