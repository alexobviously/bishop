part of 'serialisation.dart';

/// An adapter to allow serialisation of class-based variant parameters, such
/// as actions, or promotion options.
abstract class BishopTypeAdapter<T> {
  String get id;
  Map<String, dynamic>? export(T e);
  T build(Map<String, dynamic>? params);
  Type get type => T;
  const BishopTypeAdapter();
}

/// A simplified adapter for types that don't take any parameters.
class BasicAdapter<T> implements BishopTypeAdapter<T> {
  @override
  final String id;
  final T Function() builder;
  const BasicAdapter(this.id, this.builder);

  @override
  T build(Map<String, dynamic>? params) => builder();

  @override
  Map<String, dynamic>? export(T e) => null;

  @override
  Type get type => T;
}

/// A type adapter that also takes a list of adapters, allowing deep
/// serialisation. Use this for classes that contain other serialisable
/// classes.
abstract class DeepAdapter<T> extends BishopTypeAdapter<T> {
  @override
  T build(
    Map<String, dynamic>? params, {
    List<BishopTypeAdapter> adapters = const [],
  });
  @override
  Map<String, dynamic>? export(
    T e, {
    List<BishopTypeAdapter> adapters = const [],
  });

  /// A shortcut for BishopSerialisation.export.
  dynamic serialise<X>(
    X object, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
  }) =>
      BishopSerialisation.export<X>(object, adapters: adapters, strict: strict);

  /// A shortcut for BishopSerialisation.build.
  X? deserialise<X>(
    dynamic input, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
    X? Function(dynamic input)? fallback,
  }) =>
      BishopSerialisation.build<X>(
        input,
        adapters: adapters,
        strict: strict,
        fallback: fallback,
      );
}
