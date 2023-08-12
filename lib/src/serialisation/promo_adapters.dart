part of 'serialisation.dart';

class NoPromotionAdapter extends BasicAdapter<NoPromotion> {
  const NoPromotionAdapter() : super('bishop.promo.none', NoPromotion.new);
}

class StandardPromotionAdapter extends BishopTypeAdapter<StandardPromotion> {
  @override
  String get id => 'bishop.promo.standard';

  @override
  StandardPromotion build(Map<String, dynamic>? params) => StandardPromotion(
        pieceLimits: (params?['pieceLimits'] as Map<String, dynamic>?)?.map(
          (k, e) => MapEntry(k, e as int),
        ),
        ranks: params?['ranks']?.cast<int>(),
        optional: params?['optional'] ?? false,
      );

  @override
  Map<String, dynamic> export(StandardPromotion e) => {
        if (e.pieceLimits != null) 'pieceLimits': e.pieceLimits,
        if (e.ranks != null) 'ranks': e.ranks,
        if (e.optional != false) 'optional': e.optional,
      };
}

class OptionalPromotionAdapter extends BishopTypeAdapter<OptionalPromotion> {
  @override
  String get id => 'bishop.promo.optional';

  @override
  OptionalPromotion build(Map<String, dynamic>? params) => OptionalPromotion(
        pieceLimits: (params?['pieceLimits'] as Map<String, dynamic>?)?.map(
          (k, e) => MapEntry(k, e as int),
        ),
        ranks: params?['ranks']?.cast<int>(),
        forced: params?['forced'] ?? true,
        forcedRanks: params?['forcedRanks']?.cast<int>(),
      );

  @override
  Map<String, dynamic>? export(OptionalPromotion e) => {
        if (e.pieceLimits != null) 'pieceLimits': e.pieceLimits,
        if (e.ranks != null) 'ranks': e.ranks,
        if (!e.forced) 'forced': e.forced,
        if (e.forced && e.forcedRanks != null) 'forcedRanks': e.forcedRanks,
      };
}

class RegionPromotionAdapter extends BishopTypeAdapter<RegionPromotion> {
  @override
  RegionPromotion build(Map<String, dynamic>? params) => RegionPromotion(
        whiteRegion: params?['wRegion'] != null || params?['region'] != null
            ? BoardRegion.fromJson(params?['wRegion'] ?? params?['region'])
            : null,
        blackRegion: params?['bRegion'] != null || params?['region'] != null
            ? BoardRegion.fromJson(params?['bRegion'] ?? params?['region'])
            : null,
        whiteId: params?['wId'],
        blackId: params?['bId'],
        optional: params?['optional'] ?? false,
      );

  @override
  Map<String, dynamic>? export(RegionPromotion e) {
    bool same = e.whiteRegion == e.blackRegion && e.whiteRegion != null;
    return {
      if (same) 'region': e.whiteRegion!.toJson(),
      if (e.whiteRegion != null && !same) 'wRegion': e.whiteRegion!.toJson(),
      if (e.blackRegion != null && !same) 'bRegion': e.blackRegion!.toJson(),
      if (e.whiteId != null && e.whiteRegion == null) 'wId': e.whiteId,
      if (e.blackId != null && e.blackRegion == null) 'bId': e.blackId,
      if (e.optional) 'optional': e.optional,
    };
  }

  @override
  String get id => 'bishop.promo.region';
}
