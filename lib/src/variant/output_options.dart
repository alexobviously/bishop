part of 'variant.dart';

// Allows output options (FEN, PGN) to be specified for variants.
// This will become more significant when we support variants with more complex FENs.
class OutputOptions {
  final CastlingFormat castlingFormat;
  final bool showPromoted; // if true, a tilde (~) will be placed after promoted piece symbols

  OutputOptions({required this.castlingFormat, this.showPromoted = false});

  factory OutputOptions.standard() => OutputOptions(castlingFormat: CastlingFormat.Standard);
  factory OutputOptions.chess960() => OutputOptions(castlingFormat: CastlingFormat.Shredder);
  factory OutputOptions.crazyhouse() => OutputOptions(castlingFormat: CastlingFormat.Standard, showPromoted: true);
}

enum CastlingFormat {
  Standard,
  Shredder,
}
