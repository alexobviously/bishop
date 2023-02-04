part of 'actions.dart';

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

  factory ActionEvent.import(String? name) =>
      values.firstWhereOrNull((e) => e.name == name) ?? ActionEvent.afterMove;
  String export() => name;
}
