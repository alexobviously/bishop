part of 'serialisation.dart';

abstract class BishopTypeAdapter<T> {
  String get id;
  Map<String, dynamic>? export(T e);
  T build(Map<String, dynamic>? params);
  Type get type => T;
}
