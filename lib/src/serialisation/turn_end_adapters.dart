part of 'serialisation.dart';

class MoveCountTurnAdapter extends BishopTypeAdapter<TurnEndMoveCount> {
  @override
  String get id => 'bishop.turn.moveCount';

  @override
  TurnEndMoveCount build(Map<String, dynamic>? params) => TurnEndMoveCount(
        params!['count'],
        firstMoveCount: params['firstMoveCount'],
      );

  @override
  Map<String, dynamic> export(TurnEndMoveCount e) => {
        'count': e.count,
        if (e.firstMoveCount != null) 'firstMoveCount': e.firstMoveCount,
      };
}

class MoveCountIncTurnAdapter
    extends BishopTypeAdapter<TurnEndIncrementingMoveCount> {
  @override
  String get id => 'bishop.turn.moveCountInc';

  @override
  TurnEndIncrementingMoveCount build(Map<String, dynamic>? params) =>
      TurnEndIncrementingMoveCount(
        initial: params?['initial'] ?? 1,
        increment: params?['increment'] ?? 1,
      );

  @override
  Map<String, dynamic> export(TurnEndIncrementingMoveCount e) => {
        if (e.initial != 1) 'initial': e.initial,
        if (e.increment != 1) 'increment': e.increment,
      };
}
