bool isNumeric(String s) {
  return RegExp(r'^-?[0-9]+$').hasMatch(s);
}

bool isAlpha(String str) {
  return RegExp(r'^[a-zA-Z]+$').hasMatch(str);
}

String replaceMultiple(String source, List<String> originals, List<String> replacements) {
  assert(originals.length == replacements.length);
  String output = source;
  for (int i = 0; i < originals.length; i++) {
    output = output.replaceAll(originals[i], replacements[i]);
  }
  return output;
}
