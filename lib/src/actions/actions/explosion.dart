part of '../base_actions.dart';

/// Creates an explosion in [area] whenever a piece is captured.
class ActionExplodeOnCapture extends Action {
  final Area area;
  final List<String>? immunePieces;
  final bool alwaysSuicide;

  ActionExplodeOnCapture(
    this.area, {
    this.immunePieces,
    this.alwaysSuicide = true,
  }) : super(
          event: ActionEvent.afterMove,
          precondition: Conditions.isCapture,
          action: ActionDefinitions.explosion(
            area,
            immunePieces: immunePieces,
            alwaysSuicide: alwaysSuicide,
          ),
        );
}

/// Creates an explosion with [radius] whenever a piece is captured.
class ActionExplosionRadius extends ActionExplodeOnCapture {
  final int radius;

  ActionExplosionRadius(
    this.radius, {
    super.immunePieces,
    super.alwaysSuicide = true,
  }) : super(Area.radius(radius));
}

class ExplodeOnCaptureAdapter
    extends BishopTypeAdapter<ActionExplodeOnCapture> {
  @override
  String get id => 'bishop.action.explodeOnCapture';

  @override
  ActionExplodeOnCapture build(Map<String, dynamic>? params) =>
      ActionExplodeOnCapture(
        Area.fromStrings(params!['area'].cast<String>()),
        immunePieces: params['immunePieces']?.cast<String>(),
        alwaysSuicide: params['alwaysSuicide'] ?? true,
      );

  @override
  Map<String, dynamic> export(ActionExplodeOnCapture e) => {
        'area': e.area.export(),
        if (e.immunePieces?.isNotEmpty ?? false) 'immunePieces': e.immunePieces,
        if (!e.alwaysSuicide) 'alwaysSuicide': e.alwaysSuicide,
      };
}

class ExplosionRadiusAdapter extends BishopTypeAdapter<ActionExplosionRadius> {
  @override
  String get id => 'bishop.action.explosionRadius';

  @override
  ActionExplosionRadius build(Map<String, dynamic>? params) =>
      ActionExplosionRadius(
        params!['radius'],
        immunePieces: params['immunePieces']?.cast<String>(),
        alwaysSuicide: params['alwaysSuicide'] ?? true,
      );

  @override
  Map<String, dynamic> export(ActionExplosionRadius e) => {
        'radius': e.radius,
        if (e.immunePieces?.isNotEmpty ?? false) 'immunePieces': e.immunePieces,
        if (!e.alwaysSuicide) 'alwaysSuicide': e.alwaysSuicide,
      };
}
