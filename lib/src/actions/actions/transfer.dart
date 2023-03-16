part of '../base_actions.dart';

/// Transfers the ownership of the moving piece to the opponent.
/// Royal pieces will not be transferred.
/// The default behaviour is for this to be executed for any move, but
/// [capture] or [quiet] can be set to false.
class ActionTransferOwnership extends Action {
  final bool capture;
  final bool quiet;

  ActionTransferOwnership({
    this.capture = true,
    this.quiet = true,
    super.condition,
  }) : super(
          event: ActionEvent.afterMove,
          precondition: Conditions.merge([
            Conditions.movingPieceIsRoyal.invert(),
            if (capture && !quiet) Conditions.isCapture,
            if (quiet && !capture) Conditions.isNotCapture,
          ]),
          action: (trigger) {
            final piece = trigger.board[trigger.move.to];
            return [EffectModifySquare(trigger.move.to, piece.flipColour)];
          },
        );
}

class TransferOwnershipAdapter
    extends BishopTypeAdapter<ActionTransferOwnership> {
  @override
  String get id => 'bishop.action.transferOwnership';

  @override
  ActionTransferOwnership build(Map<String, dynamic>? params) =>
      ActionTransferOwnership(
        capture: params?['capture'] ?? true,
        quiet: params?['quiet'] ?? true,
      );

  @override
  Map<String, dynamic>? export(ActionTransferOwnership e) => {
        if (!e.capture) 'capture': e.capture,
        if (!e.quiet) 'quiet': e.quiet,
      };
}
