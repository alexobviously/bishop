import 'constants.dart';
import 'move_definition.dart';
import 'utils.dart';

class Betza {
  static const Map<String, Direction> atomMap = {
    'W': Direction(1, 0),
    'F': Direction(1, 1),
    'D': Direction(2, 0),
    'N': Direction(2, 1),
    'A': Direction(2, 2),
    'C': Direction(3, 1),
    'Z': Direction(3, 2),
    'H': Direction(3, 0),
    'G': Direction(3, 3),
  };
  static const List<String> shorthands = ['B', 'R', 'Q', 'K'];
  static const List<String> dirModifiers = ['f', 'b', 'r', 'l', 'v', 's', 'h'];
  static const List<String> funcModifiers = [
    'n', // 'lame'/blockable move, e.g. xiangqi knight
    'j',
    'i', // only allowed for first move of the piece, e.g. pawn double move
    'e', // en-passant
    'p', // unlimited hopper (Xiangqi cannon)
    'g', // limited hopper
  ];
  static const Map<String, Modality> modalities = {
    'm': Modality.quiet,
    'c': Modality.capture,
  };

  static List<Atom> parse(String string) {
    List<Atom> atoms = [];

    List<String> chars = string.split('');
    List<String> atomsStr = [];
    List<String> dirs = [];
    List<String> funcs = [];
    int range = 1;
    Modality modality = Modality.both;

    void add() {
      for (String a in atomsStr) {
        Atom atom = Atom(
          base: a,
          dirMods: dirs,
          funcMods: funcs,
          range: range,
          modality: modality,
        );
        atoms.add(atom);
      }
      atomsStr = [];
      dirs = [];
      funcs = [];
      range = 1;
      modality = Modality.both;
    }

    for (String c in chars) {
      if (isNumeric(c)) {
        range = int.parse(c);
      }
      if (atomsStr.isNotEmpty) {
        add();
      }

      if (dirModifiers.contains(c)) dirs.add(c);
      if (funcModifiers.contains(c)) funcs.add(c);
      if (modalities.containsKey(c)) modality = modalities[c]!;
      if (atomMap.containsKey(c)) atomsStr.add(c);
      if (shorthands.contains(c)) {
        if (c != 'K') range = 0;
        if (c != 'R') atomsStr.add('F');
        if (c != 'B') atomsStr.add('W');
      }
    }

    if (atomsStr.isNotEmpty) add();

    return atoms;
  }
}

class Atom {
  final String base;
  final List<String> dirMods;
  final List<String> funcMods;
  final int range;
  final Modality modality;

  const Atom({
    required this.base,
    this.dirMods = const [],
    this.funcMods = const [],
    this.range = 1,
    this.modality = Modality.both,
  });

  bool get firstOnly => funcMods.contains('i');
  bool get enPassant => funcMods.contains('e');
  bool get lame => funcMods.contains('n');
  bool get unlimitedHopper => funcMods.contains('p');
  bool get limitedHopper => funcMods.contains('g');
  bool get quiet => modality == Modality.both || modality == Modality.quiet;
  bool get capture => modality == Modality.both || modality == Modality.capture;

  List<Direction> get directions {
    Direction baseDir = Betza.atomMap[base]!;
    int h = baseDir.h;
    int v = baseDir.v;
    bool allDirs = dirMods.isEmpty;
    List<Direction> dirs = [];
    if (baseDir.orthogonal) {
      int m = h == 0 ? v : h;
      if (allDirs || dirMods.contains('f') || dirMods.contains('v')) {
        dirs.add(Direction(0, m));
      }
      if (allDirs || dirMods.contains('b') || dirMods.contains('v')) {
        dirs.add(Direction(0, -m));
      }
      if (allDirs || dirMods.contains('r') || dirMods.contains('s')) {
        dirs.add(Direction(m, 0));
      }
      if (allDirs || dirMods.contains('l') || dirMods.contains('s')) {
        dirs.add(Direction(-m, 0));
      }
    }
    if (baseDir.diagonal) {
      bool vert = allDirs || dirMods.contains('v');
      bool side = allDirs || dirMods.contains('s');
      bool f = vert || dirMods.contains('f');
      bool b = vert || dirMods.contains('b');
      bool r = side || dirMods.contains('r');
      bool l = side || dirMods.contains('l');
      bool forward = f || !b;
      bool backward = b || !f;
      bool right = r || !l;
      bool left = l || !r;
      if (forward && right) dirs.add(Direction(h, v));
      if (forward && left) dirs.add(Direction(-h, v));
      if (backward && right) dirs.add(Direction(h, -v));
      if (backward && left) dirs.add(Direction(-h, -v));
    }
    if (baseDir.oblique) {
      if (allDirs) {
        dirs.addAll(baseDir.permutations);
      } else {
        // this is extremely cursed but thinking of a better way hurts my brain
        String dirString = dirMods.join('');
        bool hasDir(String d) {
          bool contains = dirString.contains(d);
          if (!contains) return false;
          dirString = dirString.replaceFirst(d, '');
          return true;
        }

        bool fh = hasDir('fh');
        bool bh = hasDir('bh');
        bool lv = hasDir('lv');
        bool rv = hasDir('rv');
        bool ll = hasDir('ll');
        bool rr = hasDir('rr');
        bool ff = hasDir('ff');
        bool bb = hasDir('bb');
        bool fs = hasDir('fs');
        bool bs = hasDir('bs');
        bool hl = hasDir('hl');
        bool hr = hasDir('hr');
        bool lh = hasDir('lh');
        bool rh = hasDir('rh');
        bool vv = hasDir('v');
        bool s = hasDir('s');
        if (hasDir('fr') || fh || rr || hl || rh || fs || s) {
          dirs.add(Direction(h, v)); // fr
        }
        if (hasDir('fl') || fh || ll || hr || lh || fs || s) {
          dirs.add(Direction(-h, v)); // fl
        }
        if (hasDir('br') || bh || rr || hr || rh || bs || s) {
          dirs.add(Direction(h, -v)); // br
        }
        if (hasDir('bl') || bh || ll || hl || lh || bs || s) {
          dirs.add(Direction(-h, -v)); // bl
        }
        if (hasDir('rf') || fh || rv || hr || rh || ff || vv) {
          dirs.add(Direction(v, h)); // rf
        }
        if (hasDir('rb') || bh || rv || hl || rh || bb || vv) {
          dirs.add(Direction(v, -h)); // rb
        }
        if (hasDir('lf') || fh || lv || hl || lh || ff || vv) {
          dirs.add(Direction(-v, h)); // lf
        }
        if (hasDir('lb') || bh || lv || hr || lh || bb || vv) {
          dirs.add(Direction(-v, -h)); // lb
        }
      }
    }
    return dirs;
  }

  List<MoveDefinition> get moveDefinitions =>
      directions.map((d) => MoveDefinition.fromBetza(this, d)).toList();

  @override
  String toString() =>
      '${modality.betza}${dirMods.join('')}${funcMods.join('')}$base${range == 1 ? '' : range}';
}
