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
      (ActionTrigger trigger) => trigger.variant.boardSize
          .squaresForArea(trigger.move.to, area)
          .where((e) => trigger.state.board[e] != Bishop.empty)
          .map((e) => ActionEffectModifySquare(e, Bishop.empty))
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
        return trigger.variant.pieceIndexLookup[piece] == sq.piece;
      };
  static ActionCondition capturedPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        if (trigger.move.capturedPiece == null) return false;
        int sq = trigger.move.capturedPiece!;
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return trigger.variant.pieceIndexLookup[piece] == sq.piece;
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

class ActionEffectModifySquare extends ActionEffect {
  final int square;
  final int content;
  const ActionEffectModifySquare(this.square, this.content);
}

class ActionEffectAddToHand extends ActionEffect {
  final int player;
  final int piece;
  const ActionEffectAddToHand(this.player, this.piece);
}

class ActionEffectRemoveFromHand extends ActionEffect {
  final int player;
  final int piece;
  const ActionEffectRemoveFromHand(this.player, this.piece);
}

class ActionTrigger {
  final ActionEvent event;
  final BishopState state;
  final BuiltVariant variant;
  final Move move;

  const ActionTrigger({
    required this.event,
    required this.variant,
    required this.state,
    required this.move,
  });
}
