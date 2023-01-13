import 'dart:math';

import 'package:bishop/bishop.dart';

/// A function that generates a `List<ActionEffect>` based on an
/// `ActionTrigger` passed to it.
typedef ActionDefinition = List<ActionEffect> Function(ActionTrigger trigger);

/// A function that validates an `ActionTrigger`.
typedef ActionCondition = bool Function(ActionTrigger trigger);

class Action {
  /// The type of event that will trigger this action.
  final ActionEvent event;

  /// The [precondition] is checked before any action in the group is executed.
  /// In other words, the [precondition] will act on the state of the game,
  /// ignoring any changes that happen as a result of actions executed before
  /// this one, that are triggered by the same event.
  final ActionCondition? precondition;

  /// The [condition] is checked before executing the action in its sequence, i.e.
  /// effects applied by actions occurring before this in the sequence will be
  /// taken into account by the [condition], in contrast with [precondition].
  final ActionCondition? condition;

  /// A function that generates a `List<ActionEffect>` based on an
  /// `ActionTrigger` passed to it.
  final ActionDefinition action;

  const Action({
    required this.event,
    this.precondition,
    this.condition,
    required this.action,
  });

  factory Action.explodeOnCapture(Area area) => Action(
        event: ActionEvent.afterMove,
        precondition: Conditions.isCapture,
        action: ActionDefinitions.explosion(area),
      );

  factory Action.checkRoyalsAlive({
    ActionEvent event = ActionEvent.afterMove,
    bool allowDraw = false,
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
              : (allowDraw
                  ? [EffectSetGameResult(DrawnGameBothRoyalsDead())]
                  : [EffectInvalidateMove()]);
        },
      );

  /// The flying generals rule from Xiangqi. If the generals/kings are facing
  /// each other, with no pieces between, the move will be invalidated.
  factory Action.flyingGenerals() => Action(
        event: ActionEvent.afterMove,
        precondition: Conditions.royalsNotFacing,
        action: ActionDefinitions.invalidateMove,
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

  static ActionDefinition transformCondition(
    ActionCondition condition,
    List<ActionEffect> Function(bool result) transformer,
  ) =>
      (ActionTrigger trigger) => transformer(condition(trigger));

  static ActionDefinition explosion(Area area) =>
      (ActionTrigger trigger) => trigger.variant.boardSize
          .squaresForArea(trigger.move.to, area)
          .where((e) => trigger.state.board[e] != Bishop.empty)
          .map((e) => EffectModifySquare(e, Bishop.empty))
          .toList();

  static ActionDefinition addToHand(
    String type, {
    bool forOpponent = false,
    int count = 1,
  }) =>
      (ActionTrigger trigger) => [
            ...List.filled(
              count,
              EffectAddToHand(
                (forOpponent ^ (trigger.event == ActionEvent.beforeMove))
                    ? trigger.state.turn.opponent
                    : trigger.state.turn,
                trigger.variant.pieceIndexLookup[type]!,
              ),
            )
          ];

  static ActionDefinition removeFromHand(
    String type, {
    bool forOpponent = false,
    int count = 1,
  }) =>
      (ActionTrigger trigger) => [
            ...List.filled(
              count,
              EffectRemoveFromHand(
                (forOpponent ^ (trigger.event == ActionEvent.beforeMove))
                    ? trigger.state.turn.opponent
                    : trigger.state.turn,
                trigger.variant.pieceIndexLookup[type]!,
              ),
            )
          ];

  /// Simply output the effects regardless of the trigger.
  static ActionDefinition pass(List<ActionEffect> effects) => (_) => effects;

  /// Invalidates the move, regardless of the trigger.
  static ActionDefinition get invalidateMove =>
      pass(const [EffectInvalidateMove()]);
}

class Conditions {
  static ActionCondition merge(List<ActionCondition> conditions) =>
      (ActionTrigger trigger) {
        for (final c in conditions) {
          if (!c(trigger)) return false;
        }
        return true;
      };

  static ActionCondition invert(ActionCondition condition) =>
      (ActionTrigger trigger) => !condition(trigger);

  static ActionCondition get isCapture =>
      (ActionTrigger trigger) => trigger.move.capture;
  static ActionCondition get isNotCapture =>
      (ActionTrigger trigger) => !trigger.move.capture;
  static ActionCondition get isPromotion =>
      (ActionTrigger trigger) => trigger.move.promotion;
  static ActionCondition get isNotPromotion =>
      (ActionTrigger trigger) => !trigger.move.promotion;

  static ActionCondition movingPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        int sq = trigger.state.board[trigger.move.from];
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return trigger.variant.pieceIndexLookup[piece] == sq.type;
      };

  static ActionCondition capturedPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        if (trigger.move.capturedPiece == null) return false;
        int sq = trigger.move.capturedPiece!;
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return trigger.variant.pieceIndexLookup[piece] == sq.type;
      };

  static ActionCondition movingPieceType(int type, {int? colour}) =>
      (ActionTrigger trigger) {
        int sq = trigger.move.handDrop
            ? trigger.move.dropPiece!
            : trigger.state.board[trigger.move.from];
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return sq.type == type;
      };

  static ActionCondition get royalsNotFacing => (ActionTrigger trigger) {
        final state = trigger.state;
        final size = trigger.variant.boardSize;
        int whiteSq = state.royalSquares[Bishop.white];
        int blackSq = state.royalSquares[Bishop.black];
        if (!size.squaresOnSameFile(whiteSq, blackSq)) {
          return false;
        }
        int start = min(whiteSq, blackSq);
        int end = max(whiteSq, blackSq);
        for (int i = start + size.north; i < end; i += size.north) {
          if (state.board[i].isNotEmpty) return false;
        }
        return true;
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

class EffectInvalidateMove extends EffectSetGameResult {
  const EffectInvalidateMove() : super(const InvalidMoveResult());
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
