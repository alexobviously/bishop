import 'package:bishop/bishop.dart';

typedef AbilityDefinition = List<AbilityEffect> Function(
  BishopState state,
  Move move,
);

class Ability {
  final AbilityTrigger trigger;
  final AbilityDefinition action;

  const Ability({required this.trigger, required this.action});

  static Ability kamikaze(Area area) => Ability(
        trigger: AbilityTrigger.captureMove,
        action: Abilities.explosion(area),
      );
}

class Abilities {
  static AbilityDefinition explosion(Area area) =>
      (BishopState state, Move move) => state.size
          .squaresForArea(move.to, area)
          .map((e) => AbilityEffectModifySquare(e, Bishop.empty))
          .toList();
}

enum AbilityTrigger {
  anyMove,
  quietMove,
  captureMove,
  captured;
}

class AbilityEffect {
  const AbilityEffect();
}

class AbilityEffectModifySquare extends AbilityEffect {
  final int square;
  final int content;
  const AbilityEffectModifySquare(this.square, this.content);
}

class AbilityEffectAddToHand extends AbilityEffect {
  final int piece;
  const AbilityEffectAddToHand(this.piece);
}
