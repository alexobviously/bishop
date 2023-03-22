import 'package:bishop/bishop.dart';

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
    '*': Direction.none,
  };
  static const List<String> shorthands = ['B', 'R', 'Q', 'K'];
  static const List<String> dirModifiers = ['f', 'b', 'r', 'l', 'v', 's', 'h'];
  static const List<String> funcModifiers = [
    'n', // 'lame'/blockable move, e.g. Xiangqi knight
    'j',
    'i', // only allowed for first move of the piece, e.g. pawn double move
    'e', // en-passant
    'p', // unlimited hopper (Xiangqi cannon)
    'g', // limited hopper (Grasshopper)
  ];
  static const Map<String, Modality> modalities = {
    'm': Modality.quiet,
    'c': Modality.capture,
  };

  static final _dirAtomRegex = RegExp(r'^(\(([0-9]{1,2}),([0-9]{1,2})\))');

  static Direction? atomDirection(String atom) {
    if (atomMap.containsKey(atom)) {
      return atomMap[atom]!;
    }
    final m = _matchLongDirAtom(atom);
    if (m == null) return null;
    return Direction(int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  static RegExpMatch? _matchLongDirAtom(String substring) =>
      _dirAtomRegex.firstMatch(substring);

  static List<Atom> parse(String string) {
    List<Atom> atoms = [];

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

    for (int i = 0; i < string.length; i++) {
      String c = string[i];
      if (isNumeric(c)) {
        range = int.parse(c);
      }
      if (atomsStr.isNotEmpty) {
        add();
      }

      if (dirModifiers.contains(c)) {
        dirs.add(c);
      } else if (funcModifiers.contains(c)) {
        funcs.add(c);
      } else if (modalities.containsKey(c)) {
        modality = modalities[c]!;
      } else if (shorthands.contains(c)) {
        if (c != 'K') range = 0;
        if (c != 'R') atomsStr.add('F');
        if (c != 'B') atomsStr.add('W');
      } else if (atomMap.containsKey(c)) {
        atomsStr.add(c);
      } else {
        final m = _matchLongDirAtom(string.substring(i));
        if (m != null) {
          String a = m.group(0)!;
          atomsStr.add(a);
          i += a.length - 1;
        }
      }
    }

    if (atomsStr.isNotEmpty) add();

    return atoms;
  }
}

/// A single component of a piece's move set.
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

  bool get teleport => base == '*';
  bool get firstOnly => funcMods.contains('i');
  bool get enPassant => funcMods.contains('e');
  bool get lame => funcMods.contains('n');
  bool get unlimitedHopper => funcMods.contains('p');
  bool get limitedHopper => funcMods.contains('g');
  bool get quiet => modality == Modality.both || modality == Modality.quiet;
  bool get capture => modality == Modality.both || modality == Modality.capture;

  /// Generates all of the directions for this atom.
  List<Direction> get directions {
    if (teleport) return [Direction.none];
    Direction baseDir = Betza.atomDirection(base)!;
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
        bool fr = hasDir('fr') || fh || rr || hl || rh || fs || s;
        bool fl = hasDir('fl') || fh || ll || hr || lh || fs || s;
        bool br = hasDir('br') || bh || rr || hr || rh || bs || s;
        bool bl = hasDir('bl') || bh || ll || hl || lh || bs || s;
        bool rf = hasDir('rf') || fh || rv || hr || rh || ff || vv;
        bool rb = hasDir('rb') || bh || rv || hl || rh || bb || vv;
        bool lf = hasDir('lf') || fh || lv || hl || lh || ff || vv;
        bool lb = hasDir('lb') || bh || lv || hr || lh || bb || vv;
        bool f = hasDir('f');
        bool b = hasDir('b');
        bool l = hasDir('l');
        bool r = hasDir('r');
        if (fr || r) {
          dirs.add(Direction(h, v)); // fr
        }
        if (fl || l) {
          dirs.add(Direction(-h, v)); // fl
        }
        if (br || r) {
          dirs.add(Direction(h, -v)); // br
        }
        if (bl || l) {
          dirs.add(Direction(-h, -v)); // bl
        }
        if (rf | f) {
          dirs.add(Direction(v, h)); // rf
        }
        if (rb | b) {
          dirs.add(Direction(v, -h)); // rb
        }
        if (lf | f) {
          dirs.add(Direction(-v, h)); // lf
        }
        if (lb | b) {
          dirs.add(Direction(-v, -h)); // lb
        }
      }
    }
    return dirs;
  }

  /// Generates all the move definitions for this atom.
  List<MoveDefinition> get moveDefinitions =>
      directions.map((d) => MoveDefinition.fromBetza(this, d)).toList();

  @override
  String toString() =>
      '${modality.betza}${dirMods.join('')}${funcMods.join('')}'
      '$base${range == 1 ? '' : range}';
}
