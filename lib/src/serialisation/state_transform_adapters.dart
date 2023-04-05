part of 'serialisation.dart';

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
