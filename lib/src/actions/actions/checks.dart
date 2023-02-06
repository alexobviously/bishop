part of '../base_actions.dart';

class ActionCheckRoyalsAlive extends Action {
  final bool allowDraw;

  ActionCheckRoyalsAlive({
    super.event = ActionEvent.afterMove,
    super.precondition,
    super.condition,
    this.allowDraw = false,
  }) : super(
          action: (ActionTrigger trigger) {
            int king = trigger.variant.royalPiece;
            List<bool> kingsAlive = Bishop.colours
                .map(
                  (e) =>
                      trigger
                          .state.board[trigger.state.royalSquares[e].piece] ==
                      makePiece(king, e),
                )
                .toList();
            if (kingsAlive[Bishop.white]) {
              return kingsAlive[Bishop.black]
                  ? []
                  : [
                      EffectSetGameResult(
                        WonGameRoyalDead(winner: Bishop.white),
                      )
                    ];
            }
            return kingsAlive[Bishop.black]
                ? [EffectSetGameResult(WonGameRoyalDead(winner: Bishop.black))]
                : (allowDraw
                    ? [EffectSetGameResult(DrawnGameBothRoyalsDead())]
                    : [EffectInvalidateMove()]);
          },
        );
}

class CheckRoyalsAliveAdapter
    extends BishopTypeAdapter<ActionCheckRoyalsAlive> {
  @override
  String get id => 'bishop.action.checkRoyalsAlive';

  @override
  ActionCheckRoyalsAlive build(Map<String, dynamic>? params) =>
      ActionCheckRoyalsAlive(
        event: ActionEvent.import(params?['event']),
        allowDraw: params?['allowDraw'] ?? false,
      );

  @override
  Map<String, dynamic> export(ActionCheckRoyalsAlive e) {
    if (e.condition != null || e.precondition != null) {
      throw BishopException('Unsupported export of condition or precondition');
    }
    return {
      if (e.event != ActionEvent.afterMove) 'event': e.event.export(),
      if (e.allowDraw) 'allowDraw': e.allowDraw,
    };
  }
}

/// Checks if at least [count] pieces of type [pieceType] are present for [player].
/// If [player] is null, then both players will be checked.
/// If both players have less than [count], it will be a draw.
/// If one player has less, then it will be a win for their opponent, unless
/// [draw] is true in which case it will be a draw.
/// If [drawsInvalidate] is true (default), then any drawn result will invalidate
/// the move. In other words, moves that cause both players to not have enough
/// pieces will not be allowed.
class ActionCheckPieceCount extends Action {
  final String pieceType;
  final int count;
  final bool draw;
  final bool drawsInvalidate;
  final int? player;

  ActionCheckPieceCount({
    required this.pieceType,
    this.count = 1,
    this.draw = false,
    this.drawsInvalidate = true,
    this.player,
    super.event = ActionEvent.afterMove,
    super.precondition,
    super.condition,
  }) : super(
          action: (ActionTrigger trigger) {
            int piece = trigger.variant.pieceIndexLookup[pieceType]!;
            bool white = player == Bishop.black ||
                trigger.state.pieces[makePiece(piece, Bishop.white)] >= count;
            bool black = player == Bishop.white ||
                trigger.state.pieces[makePiece(piece, Bishop.black)] >= count;
            if (white && black) return [];
            if (draw || (!white && !black)) {
              return drawsInvalidate
                  ? [EffectInvalidateMove()]
                  : [EffectSetGameResult(DrawnGameElimination())];
            }
            return [
              EffectSetGameResult(
                WonGameElimination(winner: white ? Bishop.white : Bishop.black),
              ),
            ];
          },
        );
}

class CheckPieceCountAdapter extends BishopTypeAdapter<ActionCheckPieceCount> {
  @override
  String get id => 'bishop.action.checkPieceCount';

  @override
  ActionCheckPieceCount build(Map<String, dynamic>? params) =>
      ActionCheckPieceCount(
        pieceType: params!['pieceType'],
        count: params['count'] ?? 1,
        draw: params['draw'] ?? false,
        drawsInvalidate: params['drawsInvalidate'] ?? true,
        player: params['player'],
        event: ActionEvent.import(params['event']),
      );

  @override
  Map<String, dynamic>? export(ActionCheckPieceCount e) {
    if (e.condition != null || e.precondition != null) {
      throw BishopException('Unsupported export of condition or precondition');
    }
    return {
      'pieceType': e.pieceType,
      if (e.count != 1) 'count': e.count,
      if (e.draw) 'draw': e.draw,
      if (!e.drawsInvalidate) 'drawsInvalidate': e.drawsInvalidate,
      if (e.player != null) 'player': e.player,
      if (e.event != ActionEvent.afterMove) 'event': e.event.export(),
    };
  }
}

class ActionFlyingGenerals extends Action {
  final bool activeCondition;
  ActionFlyingGenerals({this.activeCondition = false})
      : super(
          event: ActionEvent.afterMove,
          precondition: activeCondition ? null : Conditions.royalsNotFacing,
          condition: activeCondition ? Conditions.royalsNotFacing : null,
          action: ActionDefinitions.invalidateMove,
        );
}

class FlyingGeneralsAdapter extends BishopTypeAdapter<ActionFlyingGenerals> {
  @override
  String get id => 'bishop.action.flyingGenerals';

  @override
  ActionFlyingGenerals build(Map<String, dynamic>? params) =>
      ActionFlyingGenerals(
        activeCondition: params?['activeCondition'] ?? false,
      );

  @override
  Map<String, dynamic> export(ActionFlyingGenerals e) => {
        if (e.activeCondition) 'activeCondition': e.activeCondition,
      };
}
