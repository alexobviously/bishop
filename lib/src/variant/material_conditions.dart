part of 'variant.dart';

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

  /// Material conditions for standard chess, as well as simple expanded variants
  /// with chancellor and archbishop only (e.g. Capablanca).
  static const STANDARD = const MaterialConditions(
    enabled: true,
    soloMaters: ['P', 'Q', 'R', 'A', 'C'],
    pairMaters: ['N'], // although a knight cannot force mate, it can happen if the opponent helps
    combinedPairMaters: ['B'],
    specialCases: [
      ['B', 'N']
    ],
  );

  /// Disable insufficient material draws.
  static const NONE = const MaterialConditions<String>(enabled: false);
}
