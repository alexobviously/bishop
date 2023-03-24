import 'package:bishop/bishop.dart';

abstract class MoveDefinition {
  /// Modality indicates whether the move is quiet move, capture, or both.
  final Modality modality;

  /// If true, this move is only possible as the piece's first move.
  /// Moves of this type will also set the en passant square.
  /// For example, a standard pawn's double move.
  final bool firstOnly;

  const MoveDefinition({
    this.modality = Modality.both,
    this.firstOnly = false,
  });

  factory MoveDefinition.fromBetza(Atom atom, Direction d) {
    if (atom.base == '*') {
      return TeleportMoveDefinition(modality: atom.modality);
    }
    return StandardMoveDefinition.fromBetza(atom, d);
  }

  MoveDefinition normalise(BoardSize size);

  bool get quiet => modality == Modality.both || modality == Modality.quiet;
  bool get capture => modality == Modality.both || modality == Modality.capture;

  /// Used to rapidly exclude moves in cases where we're looking for attacks.
  bool excludeMove(int from, int to, int dirMult, BoardSize size) => false;
}

class TeleportMoveDefinition extends MoveDefinition {
  const TeleportMoveDefinition({super.modality});
  @override
  TeleportMoveDefinition normalise(BoardSize size) => this;
}

/// Specifies a group of moves.
class StandardMoveDefinition extends MoveDefinition {
  /// Where does this move go?
  /// Analogous to a basic directional atom in Betza notation.
  final Direction direction;

  /// How far this move can go in the [direction].
  /// Set this to 0 for infinite (to the edge of the board).
  final int range;

  /// Whether this move an enact en passant.
  final bool enPassant;

  /// If true, these moves can be blocked by a piece standing in the path.
  /// For example, a Xiangqi horse's move or a standard pawn's double move.
  final bool lame;

  /// The distance after hopping that the piece can land at.
  /// -1 means this is not a hop move.
  /// 0 means any distance is acceptable (e.g. Xiangqi cannon).
  /// Currently only -1, 0 and 1 are supported by Betza notation ('p' and 'g').
  final int hopDistance;

  /// The number to add to a square id to translate in the direction specified
  /// by this move.
  /// Don't set this yourself, it will be calculated when `Variant.normalise()`
  /// is called.
  final int normalised;
  final Direction? lameDirection;
  final int? lameNormalised;

  bool get slider => range != 1;
  bool get unlimitedSlider => range == 0;
  bool get limitedSlider => range > 1;
  bool get hopper => slider && hopDistance > -1;
  bool get limitedHopper => slider && hopDistance > 0;

  const StandardMoveDefinition({
    required this.direction,
    this.range = 1,
    super.modality = Modality.both,
    this.enPassant = false,
    super.firstOnly = false,
    this.lame = false,
    this.hopDistance = -1,
    this.normalised = 0,
    this.lameDirection,
    this.lameNormalised,
  });

  /// Build a move definition from a betza [atom] and a [direction].
  factory StandardMoveDefinition.fromBetza(Atom atom, Direction direction) =>
      StandardMoveDefinition(
        direction: direction,
        range: atom.range,
        modality: atom.modality,
        enPassant: atom.enPassant,
        firstOnly: atom.firstOnly,
        lame: atom.lame,
        hopDistance: atom.unlimitedHopper
            ? 0
            : atom.limitedHopper
                ? 1
                : -1,
      );

  StandardMoveDefinition copyWith({
    Direction? direction,
    int? range,
    Modality? modality,
    bool? enPassant,
    bool? firstOnly,
    bool? lame,
    int? hopDistance,
    int? normalised,
    Direction? lameDirection,
    int? lameNormalised,
  }) =>
      StandardMoveDefinition(
        direction: direction ?? this.direction,
        range: range ?? this.range,
        modality: modality ?? this.modality,
        enPassant: enPassant ?? this.enPassant,
        firstOnly: firstOnly ?? this.firstOnly,
        lame: lame ?? this.lame,
        hopDistance: hopDistance ?? this.hopDistance,
        normalised: normalised ?? this.normalised,
        lameDirection: lameDirection ?? this.lameDirection,
        lameNormalised: lameNormalised ?? this.lameNormalised,
      );

  /// Calculates the values needed to use this on a board of [size].
  @override
  StandardMoveDefinition normalise(BoardSize size) {
    int normalised = direction.v * size.h * 2 - direction.h;
    Direction? lameDirection = this.lameDirection;
    int? lameNormalised = this.lameNormalised;
    if (lame) {
      lameDirection = Direction(direction.h ~/ 2, direction.v ~/ 2);
      lameNormalised = lameDirection.v * size.north - lameDirection.h;
    }
    return copyWith(
      normalised: normalised,
      lameDirection: lameDirection,
      lameNormalised: lameNormalised,
    );
  }

  @override
  bool excludeMove(int from, int to, int dirMult, BoardSize size) {
    if (!slider) {
      return from + (normalised * dirMult) != to;
    }
    final n = normalised * dirMult;
    if (n > 0 != to > from) return true;
    if (n == 0) return from == to; // idk could happen
    // There might be optimisations for limited sliders that
    // could go here, but this is pretty fast.
    return (to - from) % n != 0;
  }

  @override
  String toString() {
    String string = '$direction [${modality.name}] [$normalised]';
    List<String> mods = [];
    if (slider) mods.add(range.toString());
    if (enPassant) mods.add('ep');
    if (firstOnly) mods.add('fo');
    if (lame) mods.add('lame');
    if (hopper) mods.add('hop: $hopDistance');
    if (mods.isNotEmpty) string = '$string {${mods.join(', ')}}';
    return string;
  }
}

/// Represents a direction on a chessboard.
class Direction {
  /// Squares travelled horizontally.
  final int h;

  /// Squares travelled vertically.
  final int v;
  const Direction(this.h, this.v);

  factory Direction.fromString(String str) {
    final parts = str.split(',');
    return Direction(int.parse(parts.first), int.parse(parts.last));
  }

  static const none = Direction(0, 0);
  static const unit = Direction(1, 1);

  String get simpleString => '$h,$v';

  /// Rooks move orthogonally.
  bool get orthogonal => h == 0 || v == 0;

  /// Bishops move diagonally.
  bool get diagonal => h.abs() == v.abs();

  /// Knights move obliquely.
  bool get oblique => !orthogonal && !diagonal;

  /// Whether this direction is orthogonal, diagonal, or oblique.
  DirectionType get type => orthogonal
      ? DirectionType.orthogonal
      : diagonal
          ? DirectionType.diagonal
          : DirectionType.oblique;

  /// A list of directions that occur from mirroring this `Direction` in both axes.
  List<Direction> get permutations {
    List<Direction> perms = [];
    List<int> hs = h == 0 ? [0] : [h, -h];
    List<int> vs = v == 0 ? [0] : [v, -v];

    for (int h in hs) {
      for (int v in vs) {
        perms.add(Direction(h, v));
        perms.add(Direction(v, h));
      }
    }
    return perms;
  }

  /// Returns this direction in the positive direction of both axes.
  Direction abs() => Direction(h.abs(), v.abs());

  /// Returns a copy of this Direction, translated by [x] and [y].
  Direction translate(int x, int y) => Direction(h + x, v + y);

  @override
  String toString() => '($h,$v)';

  @override
  bool operator ==(Object other) =>
      other is Direction && h == other.h && v == other.v;

  Direction operator +(Direction other) => Direction(h + other.h, v + other.v);
  Direction operator -(Direction other) => Direction(h - other.h, v - other.v);

  Direction operator *(Object other) {
    if (other is Direction) {
      return Direction(h * other.h, v * other.v);
    }
    if (other is int) {
      return other == 1 ? this : Direction(h * other, v * other);
    }
    throw Exception('Direction can only be multiplied by an int or another'
        'Direction (tried to use ${other.runtimeType}).');
  }

  Direction operator ~/(Object other) {
    if (other is Direction) {
      return Direction(h ~/ other.h, v ~/ other.v);
    }
    if (other is int) {
      return other == 1 ? this : Direction(h ~/ other, v ~/ other);
    }
    throw Exception('Direction can only be divided by an int or another'
        'Direction (tried to use ${other.runtimeType}).');
  }

  Direction operator -() => Direction(-h, -v);

  @override
  int get hashCode => (h << 8) + v;
}

enum DirectionType {
  orthogonal,
  diagonal,
  oblique;
}

extension MoveDefListExtension on Iterable<StandardMoveDefinition> {
  bool get hasOrthogonal =>
      firstWhereOrNull((e) => e.direction.orthogonal) != null;
  bool get hasDiagonal => firstWhereOrNull((e) => e.direction.diagonal) != null;
  bool get hasOblique => firstWhereOrNull((e) => e.direction.oblique) != null;
}
