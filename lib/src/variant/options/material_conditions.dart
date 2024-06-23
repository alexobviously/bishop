part of '../variant.dart';

/// Specifies the minimum sets of pieces required for the game not to be a draw.
/// [T] should be `String` for definitions, and is converted to `int` when the `Variant` is built.
class MaterialConditions<T> {
  /// If material conditions are not enabled, insufficient material draws will not be checked.
  final bool enabled;

  /// Pieces that can deliver checkmate on their own (or with a king).
  /// e.g. Queens and Rooks in standard chess.
  final List<T> soloMaters;

  /// Pieces that can mate if there are two of them. The pieces can belong to different players.
  /// Note: this doesn't consider the fact that two bishops of the same colour can't deliver mate.
  final List<T> pairMaters;

  /// Pieces that can mate if there are two of them. **The pieces can belong to different players**.
  /// e.g. Bishops in standard chess.
  /// Note: this doesn't consider the fact that two bishops of the same colour can't deliver mate.
  final List<T> combinedPairMaters;

  /// Specific sets of pieces that can deliver mate.
  /// e.g. a Knight and a Bishop in standard chess.
  final List<List<T>> specialCases;

  const MaterialConditions({
    required this.enabled,
    this.soloMaters = const [],
    this.pairMaters = const [],
    this.combinedPairMaters = const [],
    this.specialCases = const [],
  });

  factory MaterialConditions.fromJson(Map<String, dynamic> json) =>
      MaterialConditions(
        enabled: json['enabled'],
        soloMaters: (json['soloMaters'] ?? []).cast<T>(),
        pairMaters: (json['pairMaters'] ?? []).cast<T>(),
        combinedPairMaters: (json['combinedPairMaters'] ?? []).cast<T>(),
        specialCases: (json['specialCases'] as List<dynamic>?)
                ?.map((e) => (e as List<dynamic>).map((e) => e as T).toList())
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (enabled) ...{
          'soloMaters': soloMaters,
          'pairMaters': pairMaters,
          'combinedPairMaters': combinedPairMaters,
          'specialCases': specialCases,
        },
      };

  MaterialConditions<T> copyWith({
    bool? enabled,
    List<T>? soloMaters,
    List<T>? pairMaters,
    List<T>? combinedPairMaters,
    List<List<T>>? specialCases,
  }) =>
      MaterialConditions(
        enabled: enabled ?? this.enabled,
        soloMaters: soloMaters ?? this.soloMaters,
        pairMaters: pairMaters ?? this.pairMaters,
        combinedPairMaters: combinedPairMaters ?? this.combinedPairMaters,
        specialCases: specialCases ?? this.specialCases,
      );

  /// Material conditions for standard chess, as well as simple expanded variants
  /// with chancellor and archbishop only (e.g. Capablanca).
  static const standard = MaterialConditions(
    enabled: true,
    soloMaters: ['P', 'Q', 'R', 'A', 'C'],
    // although a knight cannot force mate, it can happen if the opponent helps
    pairMaters: ['N'],
    combinedPairMaters: ['B'],
    specialCases: [
      ['B', 'N'],
    ],
  );

  /// Disable insufficient material draws.
  static const none = MaterialConditions<String>(enabled: false);
}

extension ConvertMaterialConditions on MaterialConditions<String> {
  /// Converts String-form `MaterialConditions` into int-form, based on [pieces].
  MaterialConditions<int> convert(List<PieceDefinition> pieces) {
    int pieceIndex(String symbol) =>
        pieces.indexWhere((p) => p.symbol == symbol);
    List<int> pieceIndices(List<String> symbols) =>
        symbols.map((p) => pieceIndex(p)).where((p) => p >= 0).toList();
    if (!enabled) {
      return const MaterialConditions(enabled: false);
    } else {
      return MaterialConditions(
        enabled: true,
        soloMaters: pieceIndices(soloMaters),
        pairMaters: pieceIndices(pairMaters),
        combinedPairMaters: pieceIndices(combinedPairMaters),
        specialCases: specialCases.map((e) => pieceIndices(e)).toList(),
      );
    }
  }
}
