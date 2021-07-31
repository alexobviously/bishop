part of 'variant.dart';

// Allows output options (FEN, PGN) to be specified for variants.
// This will become more significant when we support variants with more complex FENs.
class OutputOptions {
  final CastlingFormat castlingFormat;

  OutputOptions({required this.castlingFormat});

  factory OutputOptions.standard() => OutputOptions(castlingFormat: CastlingFormat.Standard);
  factory OutputOptions.chess960() => OutputOptions(castlingFormat: CastlingFormat.Shredder);
}

enum CastlingFormat {
  Standard,
  Shredder,
}
