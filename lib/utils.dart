bool isNumeric(String s) {
  return RegExp(r'^-?[0-9]+$').hasMatch(s);
}
