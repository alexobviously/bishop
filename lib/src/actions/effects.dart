part of 'actions.dart';

abstract class ActionEffect {
  const ActionEffect();
}

/// Causes [square] to be set to [content].
class EffectModifySquare extends ActionEffect {
  final int square;
  final int content;
  const EffectModifySquare(this.square, this.content);
}

/// Sets the custom state variable at index [variable] to [value].
/// You can set a number of variables equal to the size of your board, so on an
/// 8x8 board, the highest [variable] is 63.
/// [value] can be up to 8191, or 2^45 if you assume your code will never
/// execute on a 32-bit vm.
class EffectSetCustomState extends ActionEffect {
  final int variable;
  final int value;
  const EffectSetCustomState(this.variable, this.value);
}

/// Causes [piece] to be added to [player]'s hand.
class EffectAddToHand extends ActionEffect {
  final int player;
  final int piece;
  const EffectAddToHand(this.player, this.piece);
}

/// Causes [piece] to be removed from [player]'s hand.
/// If such a piece doesn't exist to be removed, nothing will happen.
class EffectRemoveFromHand extends ActionEffect {
  final int player;
  final int piece;
  const EffectRemoveFromHand(this.player, this.piece);
}

/// Sets the result of the game to [result]. This will end the game.
class EffectSetGameResult extends ActionEffect {
  final GameResult? result;
  const EffectSetGameResult(this.result);
}

/// This effect will cause the move being processed to be marked as invalid,
/// meaning that it won't appear in a legal moves list.
class EffectInvalidateMove extends EffectSetGameResult {
  const EffectInvalidateMove() : super(const InvalidMoveResult());
}
