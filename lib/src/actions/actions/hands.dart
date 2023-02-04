part of '../base_actions.dart';

class ActionAddToHand extends Action {
  final String piece;
  final int count;
  final bool forOpponent;

  ActionAddToHand(
    this.piece, {
    this.count = 1,
    this.forOpponent = false,
    super.event = ActionEvent.afterMove,
    super.precondition,
    super.condition,
  }) : super(
          action: ActionDefinitions.addToHand(
            piece,
            count: count,
            forOpponent: forOpponent,
          ),
        );
}

class ActionRemoveFromHand extends Action {
  final String piece;
  final int count;
  final bool forOpponent;

  ActionRemoveFromHand(
    this.piece, {
    this.count = 1,
    this.forOpponent = false,
    super.event = ActionEvent.afterMove,
    super.precondition,
    super.condition,
  }) : super(
          action: ActionDefinitions.removeFromHand(
            piece,
            count: count,
            forOpponent: forOpponent,
          ),
        );
}

class AddToHandAdapter extends BishopTypeAdapter<ActionAddToHand> {
  @override
  String get id => 'bishop.action.addToHand';

  @override
  ActionAddToHand build(Map<String, dynamic>? params) => ActionAddToHand(
        params!['piece'],
        forOpponent: params['forOpponent'] ?? false,
        count: params['count'] ?? 1,
        event: ActionEvent.import(params['event']),
      );

  @override
  Map<String, dynamic> export(ActionAddToHand e) {
    if (e.condition != null || e.precondition != null) {
      throw BishopException('Unsupported export of condition or precondition');
    }
    return {
      'piece': e.piece,
      if (e.forOpponent) 'forOpponent': e.forOpponent,
      if (e.count != 1) 'count': e.count,
      if (e.event != ActionEvent.afterMove) 'event': e.event.export(),
    };
  }
}

class RemoveFromHandAdapter extends BishopTypeAdapter<ActionRemoveFromHand> {
  @override
  String get id => 'bishop.action.addToHand';

  @override
  ActionRemoveFromHand build(Map<String, dynamic>? params) =>
      ActionRemoveFromHand(
        params!['piece'],
        forOpponent: params['forOpponent'] ?? false,
        count: params['count'] ?? 1,
        event: ActionEvent.import(params['event']),
      );

  @override
  Map<String, dynamic> export(ActionRemoveFromHand e) {
    if (e.condition != null || e.precondition != null) {
      throw BishopException('Unsupported export of condition or precondition');
    }
    return {
      'piece': e.piece,
      if (e.forOpponent) 'forOpponent': e.forOpponent,
      if (e.count != 1) 'count': e.count,
      if (e.event != ActionEvent.afterMove) 'event': e.event.export(),
    };
  }
}
