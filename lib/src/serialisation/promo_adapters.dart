part of 'serialisation.dart';

class NoPromotionAdapter extends BishopTypeAdapter<NoPromotion> {
  @override
  String get id => 'bishop.promo.none';
  @override
  NoPromotion build(Map<String, dynamic>? params) => NoPromotion();
  @override
  Map<String, dynamic>? export(NoPromotion e) => {};
}

class StandardPromotionAdapter extends BishopTypeAdapter<StandardPromotion> {
  @override
  String get id => 'bishop.promo.standard';

  @override
  StandardPromotion build(Map<String, dynamic>? params) => StandardPromotion(
        pieceLimits: params?['pieceLimits'],
        ranks: params?['ranks'],
      );

  @override
  Map<String, dynamic>? export(StandardPromotion e) => {
        if (e.pieceLimits != null) 'pieceLimits': e.pieceLimits,
        if (e.ranks != null) 'ranks': e.ranks,
      };
}

class OptionalPromotionAdapter extends BishopTypeAdapter<OptionalPromotion> {
  @override
  String get id => 'bishop.promo.optional';

  @override
  OptionalPromotion build(Map<String, dynamic>? params) => OptionalPromotion(
        pieceLimits: params?['pieceLimits'],
        ranks: params?['ranks'],
        forced: params?['forced'] ?? true,
        forcedRanks: params?['forcedRanks'],
      );

  @override
  Map<String, dynamic>? export(OptionalPromotion e) => {
        if (e.pieceLimits != null) 'pieceLimits': e.pieceLimits,
        if (e.ranks != null) 'ranks': e.ranks,
        if (!e.forced) 'forced': e.forced,
        if (e.forced && e.forcedRanks != null) 'forcedRanks': e.forcedRanks,
      };
}
