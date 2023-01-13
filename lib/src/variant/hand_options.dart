part of 'variant.dart';

/// Defines behaviour of hands in a variant.
class HandOptions {
  /// Whether hands are enabled.
  final bool enableHands;

  /// If true, all captured opponent pieces will be added to the player's hand.
  final bool addCapturesToHand;

  const HandOptions({this.enableHands = false, this.addCapturesToHand = false});

  static const disabled = HandOptions();
  static const captures =
      HandOptions(enableHands: true, addCapturesToHand: true);
  static const enabledOnly = HandOptions(enableHands: true);
}
