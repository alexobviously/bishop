part of 'serialisation.dart';

class PairTransformAdapter extends DeepAdapter<StateTransformerPair> {
  @override
  String get id => 'bishop.st.pair';

  @override
  StateTransformerPair build(
    Map<String, dynamic>? params, {
    List<BishopTypeAdapter> adapters = const [],
  }) =>
      StateTransformerPair(
        deserialise<StateTransformer>(params?['white'], adapters: adapters),
        deserialise<StateTransformer>(params?['black'], adapters: adapters),
      );

  @override
  Map<String, dynamic>? export(
    StateTransformerPair e, {
    List<BishopTypeAdapter> adapters = const [],
  }) =>
      {
        'white': e.white != null
            ? serialise<StateTransformer>(e.white!, adapters: adapters)
            : null,
        'black': e.black != null
            ? serialise<StateTransformer>(e.black!, adapters: adapters)
            : null,
      };
}

class VisionAreaAdapter extends BishopTypeAdapter<VisionAreaStateTransformer> {
  @override
  String get id => 'bishop.st.visionArea';

  @override
  VisionAreaStateTransformer build(Map<String, dynamic>? params) =>
      VisionAreaStateTransformer(
        area: params?['area'] == null
            ? Area.radius1
            : Area.fromStrings(params!['area'].cast<String>()),
      );

  @override
  Map<String, dynamic> export(VisionAreaStateTransformer e) => {
        if (e.area != Area.radius1) 'area': e.area.export(),
      };
}

class HideFlagsAdapter extends BishopTypeAdapter<HideFlagsStateTransformer> {
  @override
  String get id => 'bishop.st.hideFlags';

  @override
  HideFlagsStateTransformer build(Map<String, dynamic>? params) =>
      HideFlagsStateTransformer(
        forSelf: params?['forSelf'] ?? false,
        forOpponent: params?['forOpponent'] ?? true,
      );

  @override
  Map<String, dynamic> export(HideFlagsStateTransformer e) => {
        if (e.forSelf) 'forSelf': e.forSelf,
        if (!e.forOpponent) 'forOpponent': e.forOpponent,
      };
}
