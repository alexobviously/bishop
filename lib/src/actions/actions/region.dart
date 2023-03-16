part of '../base_actions.dart';

class ActionExitRegionEnding extends Action {
  final BoardRegion region;
  final EndType endType;

  ActionExitRegionEnding({
    required this.region,
    this.endType = EndType.win,
    super.precondition,
    super.condition,
  }) : super(
          action: (trigger) {
            if (!trigger.variant.boardSize
                .inRegion(trigger.move.from, region)) {
              return [];
            }
            List<ActionEffect> effect(GameResult res) =>
                [EffectSetGameResult(res)];

            if (endType.isWinLose) {
              return effect(
                WonGameExitedRegion(
                  winner: endType.isWin
                      ? trigger.piece.colour
                      : trigger.piece.colour.opponent,
                  square: trigger.move.from,
                ),
              );
            }

            if (endType.isDraw) {
              return effect(
                DrawnGameExitedRegion(
                  player: trigger.piece.colour,
                  square: trigger.move.from,
                ),
              );
            }
            return [];
          },
        );
}

class ExitRegionEndingAdapter
    extends BishopTypeAdapter<ActionExitRegionEnding> {
  @override
  String get id => 'bishop.action.exitRegionEnding';

  @override
  ActionExitRegionEnding build(Map<String, dynamic>? params) =>
      ActionExitRegionEnding(
        region: BoardRegion.fromJson(params!['region']),
        endType: EndType.fromName(params['endType'] ?? 'win'),
      );

  @override
  Map<String, dynamic> export(ActionExitRegionEnding e) {
    if (e.condition != null || e.precondition != null) {
      throw BishopException('Unsupported export of condition or precondition');
    }
    return {
      'region': e.region.toJson(),
      if (e.endType != EndType.win) 'endType': e.endType.name,
    };
  }
}
