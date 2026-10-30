part of 'state.dart';

typedef StateTransformFunction<T extends BishopState> = T? Function(
  BishopState state, [
  Colour? player,
]);

abstract class StateTransformer {
  StateTransformFunction? build(BuiltVariant variant);
}

class const StateTransformerPair(
  final StateTransformer? white,
  final StateTransformer? black,
) implements StateTransformer {
  @override
  StateTransformFunction? build(BuiltVariant variant) {
    final List<StateTransformFunction?> built = [
      white?.build(variant),
      black?.build(variant),
    ];
    return (state, [player]) =>
        player == null ? null : built[player]?.call(state, player);
  }
}

class const MaskStateTransformer(
  final List<int> Function(BishopState state) maskBuilder,
) implements StateTransformer {
  @override
  StateTransformFunction build(BuiltVariant variant) =>
      (state, [player]) =>
          MaskedState.mask(mask: maskBuilder(state), state: state);
}

class const VisionAreaStateTransformer({
  final Area area = Area.radius1,
}) implements StateTransformer {
  @override
  StateTransformFunction<MaskedState> build(BuiltVariant variant) =>
      (state, [player]) => player == null
      ? null
      : MaskedState.mask(
          mask: buildMask(
            variant.boardSize,
            visibleSquares(
              board: state.board,
              size: variant.boardSize,
              player: player,
              area: area,
            ),
          ),
          state: state,
        );
}

class const HideFlagsStateTransformer({
  final bool forSelf = false,
  final bool forOpponent = true,
}) implements StateTransformer {
  @override
  StateTransformFunction build(BuiltVariant variant) =>
      (state, [player]) => player == null
      ? null
      : state.copyWith(
          board: state.board.map((e) {
            if (e.isEmpty) return e;
            if ((forSelf && e.colour == player) ||
                (forOpponent && e.colour == player.opponent)) {
              return e.removeFlags();
            }
            return e;
          }).toList(),
        );
}
