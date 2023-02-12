part of 'variant.dart';

abstract class PromotionOptions {
  /// If specified, this will not allow promotion to specified piece types
  /// beyond the limits specified here.
  /// This is compiled to <int, int> in `BuiltVariant.pieceLimits`.
  final Map<String, int>? pieceLimits;
  PromotionBuilder? build(BuiltVariant variant);

  const PromotionOptions({this.pieceLimits});

  static const none = NoPromotion();

  static const standard = StandardPromotion();

  factory PromotionOptions.ranks(
    List<int> ranks, {
    Map<String, int>? pieceLimits,
  }) =>
      StandardPromotion(
        ranks: ranks,
        pieceLimits: pieceLimits,
      );

  factory PromotionOptions.optional({
    List<int>? ranks,
    bool forced = true,
    List<int>? forcedRanks,
    Map<String, int>? pieceLimits,
  }) =>
      OptionalPromotion(
        ranks: ranks,
        forced: forced,
        forcedRanks: forcedRanks,
        pieceLimits: pieceLimits,
      );

  factory PromotionOptions.limited(Map<String, int>? pieceLimits) =>
      StandardPromotion(
        pieceLimits: pieceLimits,
      );

  factory PromotionOptions.custom(
    PromotionBuilder? Function(BuiltVariant variant) builder,
    Map<String, int>? pieceLimits,
  ) =>
      CustomPromotion(builder: builder, pieceLimits: pieceLimits);
}

class NoPromotion extends PromotionOptions {
  const NoPromotion();

  @override
  PromotionBuilder? build(BuiltVariant variant) => null;
}

class StandardPromotion extends PromotionOptions {
  final List<int>? ranks;
  const StandardPromotion({this.ranks, super.pieceLimits});

  @override
  PromotionBuilder? build(BuiltVariant variant) {
    return Promotion.standard(
      ranks: ranks ?? [variant.boardSize.maxRank, Bishop.rank1],
    );
  }
}

class OptionalPromotion extends PromotionOptions {
  final List<int>? ranks;
  final bool forced;
  final List<int>? forcedRanks;

  const OptionalPromotion({
    this.ranks,
    this.forced = true,
    this.forcedRanks,
    super.pieceLimits,
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

class CustomPromotion extends PromotionOptions {
  final PromotionBuilder? Function(BuiltVariant variant) builder;
  const CustomPromotion({required this.builder, super.pieceLimits});

  @override
  PromotionBuilder? build(BuiltVariant variant) => builder(variant);
}
