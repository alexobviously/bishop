part of '../base_actions.dart';

class ActionBlockOrigin extends Action {
  ActionBlockOrigin()
      : super(
          action: (trigger) => [
            EffectModifySquare(
              trigger.move.from,
              makePiece(
                trigger.variant.pieceIndexLookup['*']!,
                Bishop.neutralPassive,
              ),
            ),
          ],
        );
}

class BlockOriginAdapter extends BasicAdapter<ActionBlockOrigin> {
  BlockOriginAdapter()
      : super('bishop.action.blockOrigin', ActionBlockOrigin.new);
}
