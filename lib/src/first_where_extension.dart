extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T e) test) {
    for (T e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
