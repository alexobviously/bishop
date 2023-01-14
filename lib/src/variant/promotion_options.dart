part of 'variant.dart';

abstract class PromotionOptions {
  const PromotionOptions();
  PromotionBuilder? build(BuiltVariant variant);

  static const none = NoPromotion();

  static const standard = StandardPromotion();

  factory PromotionOptions.ranks(List<int> ranks) =>
      StandardPromotion(ranks: ranks);

  factory PromotionOptions.optional({
    List<int>? ranks,
    bool forced = true,
    List<int>? forcedRanks,
  }) =>
      OptionalPromotion(
        ranks: ranks,
        forced: forced,
        forcedRanks: forcedRanks,
      );

  factory PromotionOptions.custom(
          PromotionBuilder? Function(BuiltVariant variant) builder) =>
      CustomPromotion(builder: builder);
}

class NoPromotion implements PromotionOptions {
  const NoPromotion();
  @override
  PromotionBuilder? build(_) => null;
}

class StandardPromotion implements PromotionOptions {
  final List<int>? ranks;
  const StandardPromotion({this.ranks});

  @override
  PromotionBuilder? build(BuiltVariant variant) {
    return Promotion.standard(
        ranks: ranks ?? [variant.boardSize.maxRank, Bishop.rank1]);
  }
}

class OptionalPromotion implements PromotionOptions {
  final List<int>? ranks;
  final bool forced;
  final List<int>? forcedRanks;

  const OptionalPromotion({
    this.ranks,
    this.forced = true,
    this.forcedRanks,
  });

  @override
  PromotionBuilder? build(BuiltVariant variant) {
    return Promotion.optional(
      ranks: ranks ?? [variant.boardSize.maxRank, Bishop.rank1],
      forcedRanks: forced
          ? (forcedRanks ?? [variant.boardSize.maxRank, Bishop.rank1])
          : null,
    );
  }
}

class CustomPromotion implements PromotionOptions {
  final PromotionBuilder? Function(BuiltVariant variant) builder;
  const CustomPromotion({required this.builder});

  @override
  PromotionBuilder? build(BuiltVariant variant) => builder(variant);
}
