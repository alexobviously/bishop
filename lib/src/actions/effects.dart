part of 'actions.dart';

abstract class const ActionEffect();

/// Causes [square] to be set to [content].
class const EffectModifySquare(
  final int square,
  final int content,
) extends ActionEffect;

/// Sets the custom state variable at index [variable] to [value].
/// You can set a number of variables equal to the size of your board, so on an
/// 8x8 board, the highest [variable] is 63.
/// [value] can be up to 8191, or 2^45 if you assume your code will never
/// execute on a 32-bit vm.
class const EffectSetCustomState(
  final int variable,
  final int value,
) extends ActionEffect;

/// Causes [piece] to be added to [player]'s hand.
class const EffectAddToHand(
  final int player,
  final int piece,
) extends ActionEffect;

/// Causes [piece] to be removed from [player]'s hand.
/// If such a piece doesn't exist to be removed, nothing will happen.
class const EffectRemoveFromHand(
  final int player,
  final int piece,
) extends ActionEffect;

/// Sets the result of the game to [result]. This will end the game.
class const EffectSetGameResult(
  final GameResult? result,
) extends ActionEffect;

/// This effect will cause the move being processed to be marked as invalid,
/// meaning that it won't appear in a legal moves list.
class const EffectInvalidateMove() extends EffectSetGameResult {
  this : super(const InvalidMoveResult());
}
