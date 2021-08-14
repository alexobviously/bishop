class MaterialConditions {
  final bool enabled;
  final List<String> soloMaters;
  final List<String> pairMaters;
  final List<List<String>> specialCases;

  MaterialConditions({
    required this.enabled,
    this.soloMaters = const [],
    this.pairMaters = const [],
    this.specialCases = const [],
  });

  factory MaterialConditions.standard() => MaterialConditions(
        enabled: true,
        soloMaters: ['Q', 'R', 'A', 'C'],
        pairMaters: ['B'],
        specialCases: [
          ['B', 'N']
        ],
      );

  factory MaterialConditions.none() => MaterialConditions(enabled: false);
}
