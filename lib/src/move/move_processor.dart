import 'package:bishop/bishop.dart';

class const MoveProcessorParams<T extends Move>({
  required final BishopState state,
  required final T move,
  required final Zobrist zobrist,
});

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

/// A move processor that modifies the state using the effects system.
/// You should probably use this or [ActionMoveProcessor] unless you have
/// a complex special case
class const EffectMoveProcessor<T extends Move>(
  final EffectMoveFunction<T> Function(BuiltVariant variant) builder,
) implements MoveProcessor<T> {
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

/// A move processor that modifies the state using an [action].
class ActionMoveProcessor<T extends Move>(
  final ActionDefinition action,
) extends EffectMoveProcessor<T> {
  this : super(
        (variant) =>
            (params) => action(
              ActionTrigger(
                event: ActionEvent.beforeMove,
                variant: variant,
                state: params.state,
                move: params.move,
                piece:
                    params.move.promoPiece ??
                    params.move.dropPiece ??
                    params.state.board[params.move.from],
              ),
            ),
      );
}

/// A move processor that handles a `StaticMove`.
/// On moving, the piece will be detonated, destroying all pieces in [area]
/// around it. Essentially this is like an atomic move without moving.
/// Used for Beirut Chess.
class DetonateMoveProcessor({
  final Area area = Area.radius1,
  final List<String>? immunePieces,
  final bool alwaysSuicide = true,
}) extends ActionMoveProcessor<StaticMove> {
  this : super(
         ActionDefinitions.explosion(
           area,
           immunePieces: immunePieces,
           alwaysSuicide: alwaysSuicide,
         ),
       );
}
