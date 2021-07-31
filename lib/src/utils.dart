bool isNumeric(String s) {
  return RegExp(r'^-?[0-9]+$').hasMatch(s);
}

bool isAlpha(String str) {
  return RegExp(r'^[a-zA-Z]+$').hasMatch(str);
}
