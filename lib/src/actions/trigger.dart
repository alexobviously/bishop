part of 'actions.dart';

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
