part of 'variant.dart';

/// Defines behaviour of hands in a variant.
class HandOptions {
  /// Whether hands are enabled.
  final bool enableHands;

  /// If true, all captured opponent pieces will be added to the player's hand.
  final bool addCapturesToHand;

  const HandOptions({this.enableHands = false, this.addCapturesToHand = false});

  factory HandOptions.fromJson(Map<String, dynamic> json) => HandOptions(
        enableHands: json['enableHands'],
        addCapturesToHand: json['addCapturesToHand'],
      );

  Map<String, dynamic> toJson() => {
        'enableHands': enableHands,
        'addCapturesToHand': addCapturesToHand,
      };

  static const disabled = HandOptions();
  static const captures =
      HandOptions(enableHands: true, addCapturesToHand: true);
  static const enabledOnly = HandOptions(enableHands: true);

  @override
  int get hashCode => enableHands.hashCode ^ addCapturesToHand.hashCode << 1;

  @override
  bool operator ==(Object other) =>
      other is HandOptions && hashCode == other.hashCode;
}
