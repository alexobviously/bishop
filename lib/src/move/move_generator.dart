import 'package:bishop/bishop.dart';

typedef MoveGenFunction<T extends Move> = List<T> Function({
  required BishopState state,
  required int player,
  MoveGenParams params,
});

abstract class MoveGenerator {
  MoveGenFunction build(BuiltVariant variant);
}
