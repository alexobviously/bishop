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
    this.event = ActionEvent.afterMove,
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
}

/// Some common actions.
class ActionDefinitions {
  /// Merges several [actions] into a single definition.
  static ActionDefinition merge(List<ActionDefinition> actions) =>
      (ActionTrigger trigger) =>
          actions.map((e) => e(trigger)).expand((e) => e).toList();

  /// Tranforms a [condition] into an action definition.
  static ActionDefinition transformCondition(
    ActionCondition condition,
    List<ActionEffect> Function(bool result) transformer,
  ) =>
      (ActionTrigger trigger) => transformer(condition(trigger));

  /// An action that removes every piece in [area] around the destination
  /// square of a move.
  static ActionDefinition explosion(Area area) =>
      (ActionTrigger trigger) => trigger.variant.boardSize
          .squaresForArea(trigger.move.to, area)
          .where((e) => trigger.state.board[e] != Bishop.empty)
          .map((e) => EffectModifySquare(e, Bishop.empty))
          .toList();

  /// An action that adds a piece of [type] to the moving player's hand.
  static ActionDefinition addToHand(
    String type, {
    bool forOpponent = false,
    int count = 1,
  }) =>
      (ActionTrigger trigger) => [
            ...List.filled(
              count,
              EffectAddToHand(
                forOpponent
                    ? trigger.piece.colour.opponent
                    : trigger.piece.colour,
                trigger.variant.pieceIndexLookup[type]!,
              ),
            )
          ];

  /// An action that removes a piece of [type] from the moving player's hand.
  static ActionDefinition removeFromHand(
    String type, {
    bool forOpponent = false,
    int count = 1,
  }) =>
      (ActionTrigger trigger) => [
            ...List.filled(
              count,
              EffectRemoveFromHand(
                forOpponent
                    ? trigger.piece.colour.opponent
                    : trigger.piece.colour,
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

/// Some common conditions for actions.
class Conditions {
  /// Merges multiple [conditions] into one.
  static ActionCondition merge(List<ActionCondition> conditions) =>
      (ActionTrigger trigger) {
        for (final c in conditions) {
          if (!c(trigger)) return false;
        }
        return true;
      };

  /// Inverts the result of a condition.
  static ActionCondition invert(ActionCondition condition) =>
      (ActionTrigger trigger) => !condition(trigger);

  /// Returns true if the move is a capture.
  static ActionCondition get isCapture =>
      (ActionTrigger trigger) => trigger.move.capture;

  /// Returns true if the move is not a capture.
  static ActionCondition get isNotCapture =>
      (ActionTrigger trigger) => !trigger.move.capture;

  /// Returns true if the move is a promotion move.
  static ActionCondition get isPromotion =>
      (ActionTrigger trigger) => trigger.move.promotion;

  /// Returns true if the move is not a promotion move.
  static ActionCondition get isNotPromotion =>
      (ActionTrigger trigger) => !trigger.move.promotion;

  /// Returns true if the moving piece is of type [piece].
  static ActionCondition movingPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        if (colour != null && trigger.piece.colour != colour) {
          return false;
        }
        return trigger.variant.pieceIndexLookup[piece] == trigger.piece.type;
      };

  /// Returns true if the captured piece is of type [piece].
  static ActionCondition capturedPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        if (trigger.move.capturedPiece == null) return false;
        int sq = trigger.move.capturedPiece!;
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return trigger.variant.pieceIndexLookup[piece] == sq.type;
      };

  /// Returns true if the moving piece is of type [type].
  /// See `movingPieceIs` to do this with a string piece type.
  static ActionCondition movingPieceType(int type, {int? colour}) =>
      (ActionTrigger trigger) {
        if (colour != null && trigger.piece.colour != colour) {
          return false;
        }
        return trigger.piece.type == type;
      };

  /// Returns true if the royal pieces are not facing, or if they are facing
  /// with no pieces between them.
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

/// The type of event that triggers an action.
enum ActionEvent {
  /// Actions with this event type are triggered in `makeMove` before the
  /// logic of a move is applied. Useful for custom validation logic.
  beforeMove,

  /// Actions with this event are applied directly after the logic of a move
  /// is applied, and are typically used to add custom move logic, or to
  /// validate that the move would not put the game in an illegal state.
  /// If you don't know which event to use, you probably want this one.
  afterMove;
}

abstract class ActionEffect {
  const ActionEffect();
}

/// Causes [square] to be set to [content].
class EffectModifySquare extends ActionEffect {
  final int square;
  final int content;
  const EffectModifySquare(this.square, this.content);
}

/// Causes [piece] to be added to [player]'s hand.
class EffectAddToHand extends ActionEffect {
  final int player;
  final int piece;
  const EffectAddToHand(this.player, this.piece);
}

/// Causes [piece] to be removed from [player]'s hand.
/// If such a piece doesn't exist to be removed, nothing will happen.
class EffectRemoveFromHand extends ActionEffect {
  final int player;
  final int piece;
  const EffectRemoveFromHand(this.player, this.piece);
}

/// Sets the result of the game to [result]. This will end the game.
class EffectSetGameResult extends ActionEffect {
  final GameResult? result;
  const EffectSetGameResult(this.result);
}

/// This effect will cause the move being processed to be marked as invalid,
/// meaning that it won't appear in a legal moves list.
class EffectInvalidateMove extends EffectSetGameResult {
  const EffectInvalidateMove() : super(const InvalidMoveResult());
}

/// A class that contains all the data relevant to the action being triggered.
class ActionTrigger {
  /// The event type triggering the action.
  final ActionEvent event;

  /// The state of the game at the time of the trigger. If the event is not
  /// `ActionEvent.beforeMove`, then this will reflect the state after the
  /// basic parts of the move have been made. This includes the turn.
  final BishopState state;

  /// The variant being played.
  final BuiltVariant variant;

  /// The move that is being made to trigger this action.
  final Move move;

  /// The piece moved in the last move, for convenience.
  final int piece;

  const ActionTrigger({
    required this.event,
    required this.variant,
    required this.state,
    required this.move,
    required this.piece,
  });

  ActionTrigger copyWith({
    ActionEvent? event,
    BishopState? state,
    BuiltVariant? variant,
    Move? move,
    int? piece,
  }) =>
      ActionTrigger(
        event: event ?? this.event,
        variant: variant ?? this.variant,
        state: state ?? this.state,
        move: move ?? this.move,
        piece: piece ?? this.piece,
      );
}
