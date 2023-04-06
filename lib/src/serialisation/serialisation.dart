import 'package:bishop/bishop.dart';

part 'drop_adapters.dart';
part 'first_move_adapters.dart';
part 'pass_adapters.dart';
part 'promo_adapters.dart';
part 'state_transform_adapters.dart';
part 'type_adapter.dart';

class BishopSerialisation {
  static List<BishopTypeAdapter> get baseAdapters {
    _baseAdapters ??= [
      ...basePromoAdapters,
      ...baseDropAdapters,
      ...basePassAdapters,
      ...baseStartPosAdapters,
      ...baseActionAdapters,
      ...baseFirstMoveAdapters,
      ...baseStateTransformAdapters,
    ];
    return _baseAdapters!;
  }

  static List<BishopTypeAdapter>? _baseAdapters;

  static List<BishopTypeAdapter> get basePromoAdapters => [
        NoPromotionAdapter(),
        RegionPromotionAdapter(),
        StandardPromotionAdapter(),
        OptionalPromotionAdapter(),
      ];

  static List<BishopTypeAdapter> get baseDropAdapters => [
        RegionDropAdapter(),
        StandardDropAdapter(),
        UnrestrictedDropAdapter(),
      ];

  static List<BishopTypeAdapter> get basePassAdapters => [
        NoPassAdapter(),
        StandardPassAdapter(),
      ];

  static List<BishopTypeAdapter> get baseStartPosAdapters => [
        Chess960StartPosAdapter(),
        RandomChessStartPosAdapter(),
      ];

  static List<BishopTypeAdapter> get baseActionAdapters => [
        AddToHandAdapter(),
        BlockOriginAdapter(),
        CheckPieceCountAdapter(),
        CheckRoyalsAliveAdapter(),
        ExitRegionEndingAdapter(),
        ExplodeOnCaptureAdapter(),
        ExplosionRadiusAdapter(),
        FillRegionAdapter(),
        FlyingGeneralsAdapter(),
        ImmortalityAdapter(),
        RemoveFromHandAdapter(),
        TransferOwnershipAdapter(),
      ];

  static List<BishopTypeAdapter> get baseFirstMoveAdapters => [
        FirstMovePairAdapter(),
        FirstMoveSetAdapter(),
        RanksFirstMoveAdapter(),
        InitialFirstMoveAdapter(),
      ];

  static List<BishopTypeAdapter> get baseStateTransformAdapters => [
        HideFlagsAdapter(),
        PairTransformAdapter(),
        VisionAreaAdapter(),
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

  static Map<String, T> buildMap<T>(
    Map<String, dynamic> input, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
  }) =>
      (input.map(
        (k, v) => MapEntry(k, build<T>(v, adapters: adapters, strict: strict)),
      )..removeWhere((_, v) => v == null))
          .map((k, v) => MapEntry(k, v as T));

  static T? build<T>(
    dynamic input, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
    T? Function(dynamic input)? fallback,
  }) {
    if (input == null) return null;
    adapters = [...adapters, ...baseAdapters];
    String? id;
    Map<String, dynamic>? params;
    if (input is String) id = input;
    if (input is Map<String, dynamic>) {
      id = input['id'];
      params = input;
    }
    if (id == null) {
      if (fallback != null) {
        return fallback(input);
      }
      throw BishopException('Invalid adapter ($input)');
    }
    final adapter = adapters.firstWhereOrNull((e) => e.id == id);
    if (adapter == null) {
      if (strict) {
        throw BishopException('Adapter not found: $id');
      }
      return null;
    }
    final object = adapter is DeepAdapter
        ? adapter.build(params, adapters: adapters)
        : adapter.build(params);
    if (object is! T) {
      if (strict) {
        throw BishopException('Adapter $id of invalid type (not $T)');
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

  static Map<String, dynamic> exportMap<T>(
    Map<String, T> objects, {
    List<BishopTypeAdapter> adapters = const [],
    bool strict = true,
  }) =>
      objects.map((k, v) => export<T>(v, adapters: adapters, strict: strict));

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
          throw BishopException('Adapter not found: ${object.runtimeType}');
        }
        return null;
      }
      final params = adapter is DeepAdapter
          ? adapter.export(object, adapters: adapters)
          : adapter.export(object);
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
