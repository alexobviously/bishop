import 'constants.dart';

class MoveDefinition {
  final Direction direction;
  final int range;
  final int modality;
  final bool enPassant;
  final bool firstOnly;
  final bool lame;

  late int normalised;

  bool get slider => range != 1;
  bool get quiet => modality == Modality.BOTH || modality == Modality.QUIET;
  bool get capture => modality == Modality.BOTH || modality == Modality.CAPTURE;

  MoveDefinition({
    required this.direction,
    this.range = 1,
    this.modality = Modality.BOTH,
    this.enPassant = false,
    this.firstOnly = false,
    this.lame = false,
  });

  String toString() {
    String string = direction.toString();
    List<String> mods = [];
    if (slider) mods.add(range.toString());
    if (enPassant) mods.add('ep');
    if (firstOnly) mods.add('fo');
    if (lame) mods.add('lame');
    if (mods.isNotEmpty) string = '$string {${mods.join(', ')}}';
    return string;
  }
}

class Direction {
  final int h;
  final int v;
  const Direction(this.h, this.v);

  bool get orthogonal => h == 0 || v == 0;
  bool get diagonal => h == v;
  bool get oblique => !orthogonal && !diagonal;

  List<Direction> get permutations {
    List<Direction> _permutations = [];
    List<int> hs = h == 0 ? [0] : [h, -h];
    List<int> vs = v == 0 ? [0] : [v, -v];

    for (int _h in hs) {
      for (int _v in vs) {
        _permutations.add(Direction(_h, _v));
        _permutations.add(Direction(_v, _h));
      }
    }
    return _permutations;
  }

  String toString() => '($h,$v)';
}
