part of '../variant.dart';

class GameEndConditionSet {
  final GameEndConditions white;
  final GameEndConditions black;

  const GameEndConditionSet(this.white, this.black);

  Map<String, dynamic> toJson() => isSymmetric
      ? white.toJson()
      : {
          'white': white.toJson(),
          'black': black.toJson(),
        };

  factory GameEndConditionSet.fromJson(Map<String, dynamic> json) =>
      json.containsKey('white')
          ? GameEndConditionSet(
              GameEndConditions.fromJson(json['white']),
              GameEndConditions.fromJson(json['black']),
            )
          : GameEndConditionSet.symmetric(GameEndConditions.fromJson(json));

  factory GameEndConditionSet.symmetric(GameEndConditions conditions) =>
      GameEndConditionSet(conditions, conditions);

  static const standard = GameEndConditionSet(
    GameEndConditions.standard,
    GameEndConditions.standard,
  );

  static const threeCheck = GameEndConditionSet(
    GameEndConditions.threeCheck,
    GameEndConditions.threeCheck,
  );

  bool get isSymmetric => white == black;

  bool get hasCheckLimit =>
      white.checkLimit != null || black.checkLimit != null;

  GameEndConditions operator [](int index) {
    if (index == Bishop.white) return white;
    if (index == Bishop.black) return black;
    throw RangeError('index can only be 0 or 1');
  }

  @override
  int get hashCode => white.hashCode ^ black.hashCode << 4;

  @override
  bool operator ==(Object other) =>
      other is GameEndConditionSet &&
      white == other.white &&
      black == other.black;
}

class GameEndConditions {
  /// If true, when this player has no legal moves the game will be stalemate.
  /// If false, it will be a loss for them.
  final bool stalemate;

  /// If true, this player loses when they have no pieces on the board.
  final bool elimination;

  /// If not null, this player can lose by being checked this many times.
  final int? checkLimit;

  const GameEndConditions({
    this.stalemate = true,
    this.elimination = true,
    this.checkLimit,
  });

  Map<String, dynamic> toJson() => {
        'stalemate': stalemate,
        'elimination': elimination,
        if (checkLimit != null) 'checkLimit': checkLimit,
      };

  factory GameEndConditions.fromJson(Map<String, dynamic> json) =>
      GameEndConditions(
        stalemate: json['stalemate'],
        elimination: json['elimination'],
        checkLimit: json['checkLimit'],
      );

  static const GameEndConditions standard = GameEndConditions();
  static const GameEndConditions threeCheck = GameEndConditions(checkLimit: 3);

  @override
  String toString() => 'GameEndConditions(checkLimit: $checkLimit)';

  @override
  int get hashCode =>
      stalemate.hashCode ^ elimination.hashCode << 1 ^ checkLimit.hashCode << 2;

  @override
  bool operator ==(Object other) =>
      other is GameEndConditions &&
      stalemate == other.stalemate &&
      elimination == other.elimination &&
      checkLimit == other.checkLimit;
}

// TODO: make a shortcut for ActionCheckPieceCount here 