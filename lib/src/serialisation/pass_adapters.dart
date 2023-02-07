part of 'serialisation.dart';

class NoPassAdapter extends BishopTypeAdapter<NoPass> {
  @override
  String get id => 'bishop.pass.none';
  @override
  NoPass build(Map<String, dynamic>? params) => NoPass();
  @override
  Map<String, dynamic>? export(NoPass e) => null;
}

class StandardPassAdapter extends BishopTypeAdapter<StandardPass> {
  @override
  String get id => 'bishop.pass.standard';
  @override
  StandardPass build(Map<String, dynamic>? params) => StandardPass();
  @override
  Map<String, dynamic>? export(StandardPass e) => null;
}
