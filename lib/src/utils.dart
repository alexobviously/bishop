import 'package:bishop/bishop.dart';

bool isNumeric(String s) {
  return RegExp(r'^-?[0-9]+$').hasMatch(s);
}

bool isAlpha(String str) {
  return RegExp(r'^[a-zA-Z]+$').hasMatch(str);
}

String replaceMultiple(
  String source,
  List<String> originals,
  List<String> replacements,
) {
  assert(originals.length == replacements.length);
  String output = source;
  for (int i = 0; i < originals.length; i++) {
    output = output.replaceAll(originals[i], replacements[i]);
  }
  return output;
}

bool validateFen({
  required Variant variant,
  required String fen,
  bool strict = false,
}) {
  try {
    Game g = Game(variant: variant);
    g.loadFen(fen, strict);
  } catch (e) {
    print('$e ($fen)');
    return false;
  }
  return true;
}

/// Looks up a built in variant by name.
Variant? variantFromString(String name) => Variants.values
    .firstWhereOrNull((e) => e.name.toLowerCase() == name.toLowerCase())
    ?.build();

Map<int, List<int>> compareBoards(List<int> before, List<int> after) {
  if (before.length != after.length) {
    throw BishopException('Board lengths don\'t match');
  }
  Map<int, List<int>> res = {};
  for (int i = 0; i < before.length; i++) {
    if (before[i] != after[i]) {
      res[i] = [before[i], after[i]];
    }
  }
  return res;
}
