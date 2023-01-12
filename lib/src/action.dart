import 'package:bishop/bishop.dart';

typedef ActionDefinition = List<ActionEffect> Function(ActionTrigger trigger);
typedef ActionCondition = bool Function(ActionTrigger trigger);

class Action {
  final ActionEvent event;
  final ActionCondition? precondition;
  final ActionCondition? condition;
  final ActionDefinition action;

  const Action({
    required this.event,
    this.precondition,
    this.condition,
    required this.action,
  });

  factory Action.kamikaze(Area area) => Action(
        event: ActionEvent.afterMove,
        precondition: Conditions.isCapture,
        action: ActionDefinitions.explosion(area),
      );

  factory Action.checkRoyalsAlive({
    ActionEvent event = ActionEvent.afterMove,
    ActionCondition? precondition,
    ActionCondition? condition,
  }) =>
      Action(
        event: event,
        precondition: precondition,
        condition: condition,
        action: (ActionTrigger trigger) {
          int king = trigger.variant.royalPiece;
          List<bool> kingsAlive = Bishop.colours
              .map(
                (e) =>
                    trigger.state.board[trigger.state.royalSquares[e].piece] ==
                    makePiece(king, e),
              )
              .toList();
          if (kingsAlive[Bishop.white]) {
            return kingsAlive[Bishop.black]
                ? []
                : [EffectSetGameResult(WonGameRoyalDead(winner: Bishop.white))];
          }
          return kingsAlive[Bishop.black]
              ? [EffectSetGameResult(WonGameRoyalDead(winner: Bishop.black))]
              : [EffectSetGameResult(DrawnGameBothRoyalsDead())];
        },
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

class ActionDefinitions {
  static ActionDefinition merge(List<ActionDefinition> actions) =>
      (ActionTrigger trigger) =>
          actions.map((e) => e(trigger)).expand((e) => e).toList();

  static ActionDefinition explosion(Area area) =>
      (ActionTrigger trigger) => trigger.variant.boardSize
          .squaresForArea(trigger.move.to, area)
          .where((e) => trigger.state.board[e] != Bishop.empty)
          .map((e) => EffectModifySquare(e, Bishop.empty))
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
  afterMove;
}

abstract class ActionEffect {
  const ActionEffect();
}

class EffectModifySquare extends ActionEffect {
  final int square;
  final int content;
  const EffectModifySquare(this.square, this.content);
}

class EffectAddToHand extends ActionEffect {
  final int player;
  final int piece;
  const EffectAddToHand(this.player, this.piece);
}

class EffectRemoveFromHand extends ActionEffect {
  final int player;
  final int piece;
  const EffectRemoveFromHand(this.player, this.piece);
}

class EffectSetGameResult extends ActionEffect {
  final GameResult? result;
  const EffectSetGameResult(this.result);
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

  ActionTrigger copyWith({
    ActionEvent? event,
    BishopState? state,
    BuiltVariant? variant,
    Move? move,
  }) =>
      ActionTrigger(
        event: event ?? this.event,
        variant: variant ?? this.variant,
        state: state ?? this.state,
        move: move ?? this.move,
      );
}
