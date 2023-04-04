
part of 'state.dart';

typedef StateTransformFunction<T extends BishopState> = T? Function(
  BishopState state, [
  int? player,
]);

abstract class StateTransformer {
  StateTransformFunction? build(BuiltVariant variant);
}

class StateTransformerPair implements StateTransformer {
  final StateTransformer? white;
  final StateTransformer? black;

  const StateTransformerPair(this.white, this.black);

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

class MaskStateTransformer implements StateTransformer {
  final List<int> Function(BishopState state) maskBuilder;
  const MaskStateTransformer(this.maskBuilder);

  @override
  StateTransformFunction build(BuiltVariant variant) => (state, [player]) =>
      MaskedState.mask(mask: maskBuilder(state), state: state);
}

class VisionAreaStateTransformer implements StateTransformer {
  final Area area;
  const VisionAreaStateTransformer({this.area = Area.radius1});

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
