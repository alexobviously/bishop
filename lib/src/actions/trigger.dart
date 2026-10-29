part of 'actions.dart';

/// A class that contains all the data relevant to the action being triggered.
class const ActionTrigger({
  /// The event type triggering the action.
  required final ActionEvent event,

  /// The variant being played.
  required final BuiltVariant variant,

  /// The state of the game at the time of the trigger. If the event is not
  /// `ActionEvent.beforeMove`, then this will reflect the state after the
  /// basic parts of the move have been made. This includes the turn.
  required final BishopState state,

  /// The move that is being made to trigger this action.
  required final Move move,

  /// The piece moved in the last move, for convenience.
  required final int piece,
}) {

  ActionTrigger copyWith({
    ActionEvent? event,
    BishopState? state,
    BuiltVariant? variant,
    Move? move,
    int? piece,
  }) => ActionTrigger(
    event: event ?? this.event,
    variant: variant ?? this.variant,
    state: state ?? this.state,
    move: move ?? this.move,
    piece: piece ?? this.piece,
  );

  BoardSize get size => variant.boardSize;
  List<int> get board => state.board;

  /// Retrieves the value of the custom state variable [i].
  int getCustomState(int i) =>
      state.board[variant.boardSize.secretSquare(i)] >> Bishop.flagsStartBit;
}
