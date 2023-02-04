part of '../base_actions.dart';

class ActionCheckRoyalsAlive extends Action {
  final bool allowDraw;

  ActionCheckRoyalsAlive({
    super.event = ActionEvent.afterMove,
    super.precondition,
    super.condition,
    this.allowDraw = false,
  }) : super(
          action: (ActionTrigger trigger) {
            int king = trigger.variant.royalPiece;
            List<bool> kingsAlive = Bishop.colours
                .map(
                  (e) =>
                      trigger
                          .state.board[trigger.state.royalSquares[e].piece] ==
                      makePiece(king, e),
                )
                .toList();
            if (kingsAlive[Bishop.white]) {
              return kingsAlive[Bishop.black]
                  ? []
                  : [
                      EffectSetGameResult(
                        WonGameRoyalDead(winner: Bishop.white),
                      )
                    ];
            }
            return kingsAlive[Bishop.black]
                ? [EffectSetGameResult(WonGameRoyalDead(winner: Bishop.black))]
                : (allowDraw
                    ? [EffectSetGameResult(DrawnGameBothRoyalsDead())]
                    : [EffectInvalidateMove()]);
          },
        );
}

class CheckRoyalsAliveAdapter
    extends BishopTypeAdapter<ActionCheckRoyalsAlive> {
  @override
  String get id => 'bishop.action.checkRoyalsAlive';

  @override
  ActionCheckRoyalsAlive build(Map<String, dynamic>? params) =>
      ActionCheckRoyalsAlive(
        event: ActionEvent.import(params?['event']),
        allowDraw: params?['allowDraw'] ?? false,
      );

  @override
  Map<String, dynamic> export(ActionCheckRoyalsAlive e) {
    if (e.condition != null || e.precondition != null) {
      throw BishopException('Unsupported export of condition or precondition');
    }
    return {
      if (e.event != ActionEvent.afterMove) 'event': e.event.export(),
      if (e.allowDraw) 'allowDraw': e.allowDraw,
    };
  }
}

class ActionFlyingGenerals extends Action {
  final bool activeCondition;
  ActionFlyingGenerals({this.activeCondition = false})
      : super(
          event: ActionEvent.afterMove,
          precondition: activeCondition ? null : Conditions.royalsNotFacing,
          condition: activeCondition ? Conditions.royalsNotFacing : null,
          action: ActionDefinitions.invalidateMove,
        );
}

class FlyingGeneralsAdapter extends BishopTypeAdapter<ActionFlyingGenerals> {
  @override
  String get id => 'bishop.action.flyingGenerals';

  @override
  ActionFlyingGenerals build(Map<String, dynamic>? params) =>
      ActionFlyingGenerals(
        activeCondition: params?['activeCondition'] ?? false,
      );

  @override
  Map<String, dynamic> export(ActionFlyingGenerals e) => {
        if (e.activeCondition) 'activeCondition': e.activeCondition,
      };
}
