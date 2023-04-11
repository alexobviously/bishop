import 'package:bishop/bishop.dart';

const List<MoveFormatter> defaultMoveFormatters = [
  PassMoveFormatter(),
  DropMoveFormatter(),
  GatingMoveFormatter(),
];

enum CheckType {
  none(''),
  check('+'),
  checkmate('#');

  final String symbol;
  const CheckType(this.symbol);
}

typedef MoveFormatterFunction<T extends Move> = String Function(
  T move,
  MoveFormatterCallback formatter,
  CheckType? checkType,
);

typedef MoveFormatterCallback = String Function(
  Move move,
  CheckType? checkType,
);

abstract class MoveFormatter<T extends Move> {
  const MoveFormatter();
  MoveFormatterFunction<T> algebraic(BuiltVariant variant);
  MoveFormatterFunction<T> pretty(BuiltVariant variant);
  Type get type => T;
}

class PassMoveFormatter extends MoveFormatter<PassMove> {
  const PassMoveFormatter();

  @override
  MoveFormatterFunction<PassMove> algebraic(BuiltVariant variant) =>
      (_, __, ___) => 'pass';

  @override
  MoveFormatterFunction<PassMove> pretty(BuiltVariant variant) =>
      algebraic(variant);
}

class DropMoveFormatter extends MoveFormatter<DropMove> {
  const DropMoveFormatter();

  @override
  MoveFormatterFunction<DropMove> algebraic(BuiltVariant variant) =>
      (move, _, __) => formatDropMoveAlgebraic(move: move, variant: variant);

  @override
  MoveFormatterFunction<DropMove> pretty(BuiltVariant variant) =>
      (move, _, checkType) => formatDropMovePretty(
            move: move,
            variant: variant,
            checkType: checkType,
          );
}

class GatingMoveFormatter extends MoveFormatter<GatingMove> {
  const GatingMoveFormatter();

  @override
  MoveFormatterFunction<GatingMove> algebraic(BuiltVariant variant) =>
      (move, formatter, checkType) => formatGatingMoveAlgebraic(
            move: move,
            formatter: formatter,
            variant: variant,
          );

  @override
  MoveFormatterFunction<GatingMove> pretty(BuiltVariant variant) =>
      (move, formatter, checkType) => formatGatingMovePretty(
            move: move,
            formatter: formatter,
            variant: variant,
          );
}

String formatGatingMoveAlgebraic({
  required GatingMove move,
  required MoveFormatterCallback formatter,
  CheckType? checkType,
  required BuiltVariant variant,
  bool simplifyFixedGating = true,
}) {
  String alg = formatter(move.child, checkType);
  if (variant.gatingMode == GatingMode.fixed && simplifyFixedGating) {
    return alg;
  }
  alg = '$alg/${variant.pieces[move.dropPiece].symbol.toLowerCase()}';
  if (move.child.castling) {
    String dropSq = move.dropOnRookSquare
        ? variant.boardSize.squareName(move.child.castlingPieceSquare!)
        : variant.boardSize.squareName(move.from);
    alg = '$alg$dropSq';
  }
  return alg;
}

String formatGatingMovePretty({
  required GatingMove move,
  required MoveFormatterCallback formatter,
  CheckType? checkType,
  required BuiltVariant variant,
}) {
  String san = '${formatter(move.child, checkType)}/'
      '${variant.pieces[move.dropPiece].symbol}';
  if (move.castling) {
    String dropSq = move.dropOnRookSquare
        ? variant.boardSize.squareName(move.child.castlingPieceSquare!)
        : variant.boardSize.squareName(move.from);
    san = '$san$dropSq';
  }
  // a hack, will be reworked eventually
  if (san.contains('+')) {
    san = '${san.replaceAll('+', '')}+';
  }
  if (san.contains('#')) {
    san = '${san.replaceAll('#', '')}#';
  }
  return san;
}

String formatDropMoveAlgebraic({
  required DropMove move,
  required BuiltVariant variant,
}) =>
    '${variant.pieces[move.piece].symbol.toLowerCase()}${move.algebraic(variant.boardSize)}';

String formatDropMovePretty({
  required DropMove move,
  required BuiltVariant variant,
  CheckType? checkType,
}) {
  PieceDefinition pieceDef = variant.pieces[move.piece];
  String san = '@${variant.boardSize.squareName(move.to)}';
  if (!pieceDef.type.noSanSymbol) {
    san = '${pieceDef.symbol.toUpperCase()}$san';
  }
  if (checkType != null) {
    san = '$san${checkType.symbol}';
  }
  return san;
}
