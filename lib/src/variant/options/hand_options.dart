part of 'variant.dart';

/// Defines behaviour of hands in a variant.
class HandOptions {
  /// Whether hands are enabled.
  final bool enableHands;

  /// If true, all captured opponent pieces will be added to the player's hand.
  final bool addCapturesToHand;

  final DropBuilder dropBuilder;

  const HandOptions({
    this.enableHands = false,
    this.addCapturesToHand = false,
    this.dropBuilder = DropBuilder.standard,
  });

  factory HandOptions.fromJson(
    Map<String, dynamic> json, {
    List<BishopTypeAdapter> adapters = const [],
  }) =>
      HandOptions(
        enableHands: json['enableHands'],
        addCapturesToHand: json['addCapturesToHand'],
        dropBuilder: (json.containsKey('dropBuilder')
                ? BishopSerialisation.build<DropBuilder>(
                    json['dropBuilder'],
                    adapters: adapters,
                  )
                : null) ??
            DropBuilder.standard,
      );

  Map<String, dynamic> toJson({
    bool verbose = false,
    List<BishopTypeAdapter> adapters = const [],
  }) {
    return {
      'enableHands': enableHands,
      'addCapturesToHand': addCapturesToHand,
      if (verbose || dropBuilder is! StandardDropBuilder)
        'dropBuilder': BishopSerialisation.export<DropBuilder>(
          dropBuilder,
          adapters: adapters,
        ),
    };
  }

  static const disabled = HandOptions();
  static const captures =
      HandOptions(enableHands: true, addCapturesToHand: true);
  static const enabledOnly = HandOptions(enableHands: true);
}

abstract class DropBuilder {
  const DropBuilder();

  DropBuilderFunction build(BuiltVariant variant);

  static const standard = StandardDropBuilder();
  static const unrestricted = UnrestrictedDropBuilder();
  factory DropBuilder.region(BoardRegion region) => RegionDropBuilder(region);
}

class StandardDropBuilder extends DropBuilder {
  const StandardDropBuilder();

  @override
  DropBuilderFunction build(BuiltVariant variant) => Drops.standard();
}

class UnrestrictedDropBuilder extends DropBuilder {
  const UnrestrictedDropBuilder();

  @override
  DropBuilderFunction build(BuiltVariant variant) =>
      Drops.standard(restrictPromoPieces: false);
}

class RegionDropBuilder extends DropBuilder {
  final BoardRegion region;
  const RegionDropBuilder(this.region);

  @override
  DropBuilderFunction build(BuiltVariant variant) => Drops.region(region);
}
