import 'package:bishop/bishop.dart';

typedef MoveBuilderFunction = List<Move> Function(MoveParams params);

abstract class MoveBuilder {
  const MoveBuilder();

  MoveBuilderFunction build(BuiltVariant variant);
}

abstract class DropBuilder extends MoveBuilder {
  const DropBuilder();

  @override
  MoveBuilderFunction build(BuiltVariant variant);

  static const standard = StandardDropBuilder();
  static const unrestricted = UnrestrictedDropBuilder();
  factory DropBuilder.region(BoardRegion region) => RegionDropBuilder(region);
}

class StandardDropBuilder extends DropBuilder {
  const StandardDropBuilder();

  @override
  MoveBuilderFunction build(BuiltVariant variant) => Drops.standard();
}

class UnrestrictedDropBuilder extends DropBuilder {
  const UnrestrictedDropBuilder();

  @override
  MoveBuilderFunction build(BuiltVariant variant) =>
      Drops.standard(restrictPromoPieces: false);
}

class RegionDropBuilder extends DropBuilder {
  final BoardRegion region;
  const RegionDropBuilder(this.region);

  @override
  MoveBuilderFunction build(BuiltVariant variant) => Drops.region(region);
}

class MissingPieceDropBuilder extends DropBuilder {
  final String type;
  final int? colour;

  const MissingPieceDropBuilder({
    required this.type,
    this.colour,
  });

  @override
  MoveBuilderFunction build(BuiltVariant variant) => Drops.missingPiece(
        type,
        colour: colour,
      );
}
