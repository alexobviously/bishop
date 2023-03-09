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

  static const antichess = GameEndConditionSet(
    GameEndConditions.antichess,
    GameEndConditions.antichess,
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
  /// Occurs when a player has no legal moves.
  final EndType stalemate;

  /// Occurs when a player has no pieces on the board (or hand).
  final EndType elimination;

  /// If not null, this player can lose by being checked this many times.
  final int? checkLimit;
  // todo: when dart 3 comes out, make this an (EndType, int?)

  const GameEndConditions({
    this.stalemate = EndType.draw,
    this.elimination = EndType.lose,
    this.checkLimit,
  });

  Map<String, dynamic> toJson() => {
        'stalemate': stalemate.name,
        'elimination': elimination.name,
        if (checkLimit != null) 'checkLimit': checkLimit,
      };

  factory GameEndConditions.fromJson(Map<String, dynamic> json) =>
      GameEndConditions(
        stalemate: EndType.fromName(json['stalemate']),
        elimination: EndType.fromName(json['elimination']),
        checkLimit: json['checkLimit'],
      );

  static const GameEndConditions standard = GameEndConditions();
  static const GameEndConditions threeCheck = GameEndConditions(checkLimit: 3);
  static const GameEndConditions antichess =
      GameEndConditions(stalemate: EndType.win, elimination: EndType.win);

  @override
  String toString() => 'GameEndConditions(elimination: ${elimination.name},'
      'stalemate: ${stalemate.name}, checkLimit: $checkLimit)';

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

/// What happens when a game end condition is met.
/// This is from the perspective of the player the condition happens to.
/// i.e. if a player has no legal moves and thus enters the stalemate condition,
/// with EndType.win, the player with no moves will win.
/// EndType.none disables a condition.
enum EndType {
  win,
  lose,
  draw,
  none;

  const EndType();
  static EndType fromName(String name) =>
      values.firstWhere((e) => e.name == name);

  bool get isNone => this == EndType.none;
  bool get isNotNone => !isNone;
  bool get isWinLose => this == EndType.win || this == EndType.lose;
  bool get isDraw => this == EndType.draw;
  bool get isWin => this == EndType.win;
  bool get isLose => this == EndType.lose;
}
