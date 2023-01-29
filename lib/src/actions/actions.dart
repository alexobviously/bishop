import 'dart:math';
import 'package:bishop/bishop.dart';

part 'conditions.dart';
part 'definitions.dart';
part 'effects.dart';
part 'events.dart';
part 'trigger.dart';

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
    this.event = ActionEvent.afterMove,
    this.precondition,
    this.condition,
    required this.action,
  });

  Action copyWith({
    ActionEvent? event,
    ActionCondition? precondition,
    ActionCondition? condition,
    ActionDefinition? action,
  }) =>
      Action(
        event: event ?? this.event,
        precondition: precondition ?? this.precondition,
        condition: condition ?? this.condition,
        action: action ?? this.action,
      );

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
  /// Set [activeCondition] to true if you have other actions that might modify
  /// the board before this.
  factory Action.flyingGenerals({bool activeCondition = false}) => Action(
        event: ActionEvent.afterMove,
        precondition: activeCondition ? null : Conditions.royalsNotFacing,
        condition: activeCondition ? Conditions.royalsNotFacing : null,
        action: ActionDefinitions.invalidateMove,
      );

  /// Copies the Action with the added condition that the piece type is [type].
  /// Used internally when building variants, to enable convenience actions on
  /// piece type definitions.
  Action forPieceType(int type) => Action(
        event: event,
        action: action,
        precondition: precondition != null
            ? Conditions.merge(
                [Conditions.movingPieceType(type), precondition!],
              )
            : Conditions.movingPieceType(type),
        condition: condition,
      );

  /// Swaps [precondition] and [condition].
  Action swapConditions() => Action(
        event: event,
        precondition: condition,
        condition: precondition,
        action: action,
      );
}
