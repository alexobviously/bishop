import 'package:bishop/bishop.dart';

typedef ActionDefinition = List<ActionEffect> Function(ActionTrigger trigger);
typedef ActionCondition = bool Function(ActionTrigger trigger);

class Action {
  final ActionEvent event;
  final ActionCondition? condition;
  final ActionDefinition action;

  const Action({required this.event, this.condition, required this.action});

  static Action kamikaze(Area area) => Action(
        event: ActionEvent.duringMove,
        condition: Conditions.isCapture,
        action: Actions.explosion(area),
      );

  /// Copies the Action with the added condition that the piece type is [type].
  /// Used internally when building variants, to enable convenience actions on
  /// piece type definitions.
  Action forPieceType(int type) => Action(
        event: event,
        action: action,
        condition: condition != null
            ? Conditions.merge([condition!, Conditions.movingPieceType(type)])
            : Conditions.movingPieceType(type),
      );
}

class Actions {
  static ActionDefinition merge(List<ActionDefinition> actions) =>
      (ActionTrigger trigger) =>
          actions.map((e) => e(trigger)).expand((e) => e).toList();

  static ActionDefinition explosion(Area area) =>
      (ActionTrigger trigger) => trigger.state.size
          .squaresForArea(trigger.move.to, area)
          .where((e) => trigger.state.board[e] != Bishop.empty)
          .map((e) => AbilityEffectModifySquare(e, Bishop.empty))
          .toList();
}

class Conditions {
  static ActionCondition merge(List<ActionCondition> conditions) =>
      (ActionTrigger trigger) {
        for (final c in conditions) {
          if (!c(trigger)) return false;
        }
        return true;
      };
  static ActionCondition isCapture =
      (ActionTrigger trigger) => trigger.move.capture;
  static ActionCondition isNotCapture =
      (ActionTrigger trigger) => !trigger.move.capture;
  static ActionCondition isPromotion =
      (ActionTrigger trigger) => trigger.move.promotion;
  static ActionCondition isNotPromotion =
      (ActionTrigger trigger) => !trigger.move.promotion;
  static ActionCondition movingPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        int sq = trigger.state.board[trigger.move.from];
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return trigger.state.variant.pieceIndexLookup[piece] == sq.piece;
      };
  static ActionCondition capturedPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        if (trigger.move.capturedPiece == null) return false;
        int sq = trigger.move.capturedPiece!;
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return trigger.state.variant.pieceIndexLookup[piece] == sq.piece;
      };
  static ActionCondition movingPieceType(int type, {int? colour}) =>
      (ActionTrigger trigger) {
        int sq = trigger.state.board[trigger.move.from];
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return sq.type == type;
      };
}

enum ActionEvent {
  beforeMove,
  duringMove,
  afterMove;
}

abstract class ActionEffect {
  const ActionEffect();
}

class AbilityEffectModifySquare extends ActionEffect {
  final int square;
  final int content;
  const AbilityEffectModifySquare(this.square, this.content);
}

class AbilityEffectAddToHand extends ActionEffect {
  final int player;
  final int piece;
  const AbilityEffectAddToHand(this.player, this.piece);
}

class AbilityEffectRemoveFromHand extends ActionEffect {
  final int player;
  final int piece;
  const AbilityEffectRemoveFromHand(this.player, this.piece);
}

class ActionTrigger {
  final ActionEvent event;
  final BishopState state;
  final Move move;

  const ActionTrigger({
    required this.event,
    required this.state,
    required this.move,
  });
}
