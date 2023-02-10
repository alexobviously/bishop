part of '../base_actions.dart';

class ActionImmortality extends Action {
  final String? pieceType;
  final int? pieceIndex;
  final int? flag;

  ActionImmortality({
    this.pieceType,
    this.pieceIndex,
    this.flag,
    super.event = ActionEvent.afterMove,
    super.condition,
  }) : super(
          precondition: Conditions.merge([
            if (pieceType != null) Conditions.capturedPieceIs(pieceType),
            if (flag != null) Conditions.capturedPieceHasFlag(flag),
            if (pieceIndex != null) Conditions.capturedPieceType(pieceIndex),
          ]),
          action: ActionDefinitions.invalidateMove,
        );

  @override
  Action forPieceType(int type) => ActionImmortality(
        pieceIndex: type,
        flag: flag,
        event: event,
        condition: condition,
      );
}

class ImmortalityAdapter extends BishopTypeAdapter<ActionImmortality> {
  @override
  String get id => 'bishop.action.immortality';

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
      if (e.pieceIndex != null) 'pieceIndex': e.pieceIndex,
      if (e.flag != null) 'flag': e.flag,
    };
  }
}
