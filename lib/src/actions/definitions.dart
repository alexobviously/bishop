part of 'actions.dart';

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
