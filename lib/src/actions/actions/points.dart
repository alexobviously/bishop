part of '../base_actions.dart';

class ActionPointsEnding extends Action {
  final List<int> stateVariables;
  final List<int> limits;

  ActionPointsEnding({
    required this.limits,
    this.stateVariables = const [0, 1],
    super.event = ActionEvent.afterMove,
    super.precondition,
    super.condition,
  })  : assert(limits.length == 2),
        super(
          action: (trigger) {
            int whitePts = trigger.getCustomState(stateVariables.first);
            int blackPts = trigger.getCustomState(stateVariables.last);
            bool white = whitePts >= limits.first;
            bool black = blackPts >= limits.last;
            if (!white && !black) return [];
            if (white ^ black) {
              return [
                EffectSetGameResult(
                  WonGamePoints(
                    winner: white ? Bishop.white : Bishop.black,
                    points: white ? whitePts : blackPts,
                  ),
                ),
              ];
            }
            bool whiteWins = whitePts > blackPts;
            return [
              EffectSetGameResult(
                whitePts == blackPts
                    ? DrawnGamePoints(whitePts)
                    : WonGamePoints(
                        winner: whiteWins ? Bishop.white : Bishop.black,
                        points: whiteWins ? whitePts : blackPts,
                      ),
              ),
            ];
          },
        );
}
