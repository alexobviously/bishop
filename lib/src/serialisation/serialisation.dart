import 'package:bishop/bishop.dart';

part 'drop_adapters.dart';
part 'promo_adapters.dart';
part 'type_adapter.dart';

class BishopSerialisation {
  static List<BishopTypeAdapter> get baseAdapters {
    _baseAdapters ??= [
      ...basePromoAdapters,
      ...baseDropAdapters,
      ...baseActionAdapters,
    ];
    return _baseAdapters!;
  }

  static List<BishopTypeAdapter>? _baseAdapters;

  static List<BishopTypeAdapter> get basePromoAdapters => [
        NoPromotionAdapter(),
        StandardPromotionAdapter(),
        OptionalPromotionAdapter(),
      ];

  static List<BishopTypeAdapter> get baseDropAdapters => [
        StandardDropAdapter(),
        UnrestrictedDropAdapter(),
      ];

  static List<BishopTypeAdapter> get baseActionAdapters => [
        AddToHandAdapter(),
        CheckRoyalsAliveAdapter(),
        ExplodeOnCaptureAdapter(),
        ExplosionRadiusAdapter(),
        FlyingGeneralsAdapter(),
        RemoveFromHandAdapter(),
      ];

  static List<T> buildMany<T>(
    List input, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
  }) =>
      input
          .map((e) => build<T>(e, adapters: adapters, strict: strict))
          .where((e) => e != null)
          .map((e) => e as T)
          .toList();

  static T? build<T>(
    dynamic input, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
  }) {
    adapters = [...adapters, ...baseAdapters];
    String? id;
    Map<String, dynamic>? params;
    if (input is String) id = input;
    if (input is Map<String, dynamic>) {
      id = input['id'];
      params = input;
    }
    if (id == null) {
      throw BishopException('Invalid adapter ($input)');
    }
    final adapter = adapters.firstWhereOrNull((e) => e.id == id);
    if (adapter == null) {
      if (strict) {
        throw BishopException('Adapter not found ($id)');
      }
      return null;
    }
    final object = adapter.build(params);
    if (object is! T) {
      if (strict) {
        throw BishopException('Adapter ($id) of invalid type (not $T)');
      }
      return null;
    }
    return object;
  }

  static List exportMany<T>(
    List<T> objects, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
  }) =>
      objects
          .map((e) => export<T>(e, adapters: adapters, strict: strict))
          .where((e) => e != null)
          .toList();

  static dynamic export<T>(
    T object, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
  }) {
    adapters = [...adapters, ...baseAdapters];
    try {
      final adapter =
          adapters.firstWhereOrNull((e) => e.type == object.runtimeType);
      if (adapter == null) {
        if (strict) {
          throw BishopException('Adapter not found (${object.runtimeType})');
        }
        return null;
      }
      final params = adapter.export(object);
      if (params == null || params.isEmpty) {
        return adapter.id;
      }
      return {
        'id': adapter.id,
        ...params,
      };
    } on BishopException {
      if (strict) rethrow;
      return null;
    }
  }
}
