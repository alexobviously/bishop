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
  RegionDropBuilder build(Map<String, dynamic>? params) => RegionDropBuilder(
        whiteRegion: params?['wRegion'] != null || params?['region'] != null
            ? BoardRegion.fromJson(params?['wRegion'] ?? params?['region'])
            : null,
        blackRegion: params?['bRegion'] != null || params?['region'] != null
            ? BoardRegion.fromJson(params?['bRegion'] ?? params?['region'])
            : null,
        whiteId: params?['wId'],
        blackId: params?['bId'],
      );

  @override
  Map<String, dynamic> export(RegionDropBuilder e) {
    bool same = e.whiteRegion == e.blackRegion && e.whiteRegion != null;
    return {
      if (same) 'region': e.whiteRegion!.toJson(),
      if (e.whiteRegion != null && !same) 'wRegion': e.whiteRegion!.toJson(),
      if (e.blackRegion != null && !same) 'bRegion': e.blackRegion!.toJson(),
      if (e.whiteId != null && e.whiteRegion == null) 'wId': e.whiteId,
      if (e.blackId != null && e.blackRegion == null) 'bId': e.blackId,
    };
  }
}
