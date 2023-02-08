part of '../base_actions.dart';

class ActionImmortality extends Action {
  final String? pieceType;
  final int? flag;

  ActionImmortality({
    this.pieceType,
    this.flag,
    super.event = ActionEvent.afterMove,
    super.condition,
  })  : assert(pieceType != null || flag != null),
        super(
          precondition: pieceType != null
              ? (flag != null
                  ? Conditions.merge([
                      Conditions.capturedPieceIs(pieceType),
                      Conditions.capturedPieceHasFlag(flag)
                    ])
                  : Conditions.capturedPieceIs(pieceType))
              : Conditions.capturedPieceHasFlag(flag!),
          action: ActionDefinitions.invalidateMove,
        );
}

class ImmortalityAdapter extends BishopTypeAdapter<ActionImmortality> {
  @override
  String get id => 'bishop.action.immortalPiece';

  @override
  ActionImmortality build(Map<String, dynamic>? params) => ActionImmortality(
        event: ActionEvent.import(params?['event']),
        pieceType: params!['pieceType'],
        flag: params['flag'],
      );

  @override
  Map<String, dynamic>? export(ActionImmortality e) {
    if (e.condition != null) {
      throw BishopException('Unsupported export of condition');
    }
    return {
      if (e.event != ActionEvent.afterMove) 'event': e.event.export(),
      if (e.pieceType != null) 'pieceType': e.pieceType,
      if (e.flag != null) 'flag': e.flag,
    };
  }
}
