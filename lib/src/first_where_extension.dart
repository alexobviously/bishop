extension IterableExtension<T> on Iterable<T> {
  /// Returns the first element matching [test], or null if there is none.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
