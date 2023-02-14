part of '../base_actions.dart';

/// Creates an explosion in [area] whenever a piece is captured.
class ActionExplodeOnCapture extends Action {
  final Area area;
  ActionExplodeOnCapture(this.area)
      : super(
          event: ActionEvent.afterMove,
          precondition: Conditions.isCapture,
          action: ActionDefinitions.explosion(area),
        );
}

/// Creates an explosion with [radius] whenever a piece is captured.
class ActionExplosionRadius extends ActionExplodeOnCapture {
  final int radius;
  ActionExplosionRadius(this.radius) : super(Area.radius(radius));
}

class ExplodeOnCaptureAdapter
    extends BishopTypeAdapter<ActionExplodeOnCapture> {
  @override
  String get id => 'bishop.action.explodeOnCapture';

  @override
  ActionExplodeOnCapture build(Map<String, dynamic>? params) =>
      ActionExplodeOnCapture(Area.fromStrings(params!['area'].cast<String>()));

  @override
  Map<String, dynamic> export(ActionExplodeOnCapture e) => {
        'area': e.area.export(),
      };
}

class ExplosionRadiusAdapter extends BishopTypeAdapter<ActionExplosionRadius> {
  @override
  String get id => 'bishop.action.explosionRadius';

  @override
  ActionExplosionRadius build(Map<String, dynamic>? params) =>
      ActionExplosionRadius(params!['radius']);

  @override
  Map<String, dynamic> export(ActionExplosionRadius e) => {
        'radius': e.radius,
      };
}
