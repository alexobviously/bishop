part of 'variant.dart';

/// Allows output options (FEN, PGN) to be specified for variants.
/// This will become more significant when we support variants with more complex FENs.
class OutputOptions {
  /// Define the format to be used when outputting castling rights.
  final CastlingFormat castlingFormat;

  /// If true, a tilde (~) will be placed after promoted piece symbols.
  final bool showPromoted;

  /// If true, the castling field in the FEN string will be combined with a list
  /// of files where the starting pieces haven't moved from them.
  /// For example, to be used with Seirawan gates.
  final bool showVirginFiles;

  OutputOptions({
    required this.castlingFormat,
    this.showPromoted = false,
    this.showVirginFiles = false,
  });

  factory OutputOptions.standard() => OutputOptions(castlingFormat: CastlingFormat.Standard);
  factory OutputOptions.chess960() => OutputOptions(castlingFormat: CastlingFormat.Shredder);
  factory OutputOptions.crazyhouse() => OutputOptions(castlingFormat: CastlingFormat.Standard, showPromoted: true);
}

/// Determines how castling rights are represented in FEN strings.
/// There are certain positions in variants such as Chess960, in which the
/// standard 'KQkq' format could present an ambiguity.
/// See [this link](https://en.wikipedia.org/wiki/Fischer_random_chess#Coding_games_and_positions)
/// for more details.
enum CastlingFormat {
  /// The standard castling format labels rights as 'KQkq', regardless of the
  /// position of the rooks.
  Standard,

  /// Uses the letters for the files that the rooks start on to represent
  /// castling rights. For example, the default chess position's castling rights
  /// would be rendered as 'HAha'.
  Shredder,

  /// Currently unsupported for output. Coming soon!
  /// A middle ground between Standard and Shredder notation.
  /// Uses the standard format ('KQkq') unless there is an ambiguity, in which
  /// case the ambiguous rook's file will be used.
  Xfen,
}
