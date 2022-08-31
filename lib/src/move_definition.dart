import 'constants.dart';

/// Specifies a group of moves.
class MoveDefinition {
  /// Where does this move go?
  /// Analogous to a basic directional atom in Betza notation.
  final Direction direction;

  /// How far this move can go in the [direction].
  /// Set this to 0 for infinite (to the edge of the board).
  final int range;

  /// Modality indicates whether the move is quiet move, capture, or both.
  final Modality modality;

  /// Whether this move an enact en passant.
  final bool enPassant;

  /// If true, this move is only possible as the piece's first move.
  /// Moves of this type will also set the en passant square.
  /// For example, a standard pawn's double move.
  final bool firstOnly;

  /// If true, these moves can be blocked by a piece standing in the path.
  /// For example, a Xiangqi horse's move or a standard pawn's double move.
  final bool lame;

  late int normalised;
  Direction? lameDirection;
  int? lameNormalised;

  bool get slider => range != 1;
  bool get quiet => modality == Modality.both || modality == Modality.quiet;
  bool get capture => modality == Modality.both || modality == Modality.capture;

  MoveDefinition({
    required this.direction,
    this.range = 1,
    this.modality = Modality.both,
    this.enPassant = false,
    this.firstOnly = false,
    this.lame = false,
  });

  @override
  String toString() {
    String string = '$direction [${modality.name}]';
    List<String> mods = [];
    if (slider) mods.add(range.toString());
    if (enPassant) mods.add('ep');
    if (firstOnly) mods.add('fo');
    if (lame) mods.add('lame');
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

  /// Rooks move orthogonally.
  bool get orthogonal => h == 0 || v == 0;

  /// Bishops move diagonally.
  bool get diagonal => h == v;

  /// Knights move obliquely.
  bool get oblique => !orthogonal && !diagonal;

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

  @override
  String toString() => '($h,$v)';

  @override
  bool operator ==(Object other) =>
      other is Direction && h == other.h && v == other.v;

  @override
  int get hashCode => (h << 8) + v;
}
