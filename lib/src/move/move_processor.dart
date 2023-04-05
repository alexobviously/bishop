import 'package:bishop/bishop.dart';

class MoveProcessorParams<T extends Move> {
  final BishopState state;
  final T move;
  final Zobrist zobrist;
  const MoveProcessorParams({
    required this.state,
    required this.move,
    required this.zobrist,
  });
}

typedef MoveProcessorFunction<T extends Move> = BishopState? Function(
  MoveProcessorParams params,
);

typedef EffectMoveFunction<T extends Move> = List<ActionEffect> Function(
  MoveProcessorParams params,
);

abstract class MoveProcessor<T extends Move> {
  MoveProcessorFunction<T> build(BuiltVariant variant);

  Type get type => T;
}

class EffectMoveProcessor<T extends Move> implements MoveProcessor<T> {
  final EffectMoveFunction<T> Function(BuiltVariant variant) builder;
  const EffectMoveProcessor(this.builder);
  @override
  Type get type => T;

  @override
  MoveProcessorFunction<T> build(BuiltVariant variant) => (params) {
        final effects = builder(variant)(params);
        return params.state.applyEffects(
          effects: effects,
          size: variant.boardSize,
          zobrist: params.zobrist,
        );
      };
}

class ActionMoveProcessor<T extends Move> extends EffectMoveProcessor<T> {
  final ActionDefinition action;
  ActionMoveProcessor(this.action)
      : super(
          (variant) => (params) => action(
                ActionTrigger(
                  event: ActionEvent.beforeMove,
                  variant: variant,
                  state: params.state,
                  move: params.move,
                  piece: params.move.promoPiece ??
                      params.move.dropPiece ??
                      params.state.board[params.move.from],
                ),
              ),
        );
}

class DetonateMoveProcessor extends ActionMoveProcessor<StaticMove> {
  final Area area;
  final List<String>? immunePieces;
  final bool alwaysSuicide;

  DetonateMoveProcessor({
    this.area = Area.radius1,
    this.immunePieces,
    this.alwaysSuicide = true,
  }) : super(
          ActionDefinitions.explosion(
            area,
            immunePieces: immunePieces,
            alwaysSuicide: alwaysSuicide,
          ),
        );
}
