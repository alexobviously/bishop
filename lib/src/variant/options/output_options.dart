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
  final bool virginFiles;

  const OutputOptions({
    this.castlingFormat = CastlingFormat.standard,
    this.showPromoted = false,
    this.virginFiles = false,
  });

  factory OutputOptions.fromJson(Map<String, dynamic> json) => OutputOptions(
        castlingFormat: CastlingFormat.values
            .firstWhere((e) => e.name == json['castlingFormat']),
        showPromoted: json['showPromoted'],
        virginFiles: json['virginFiles'],
      );

  Map<String, dynamic> toJson() => {
        'castlingFormat': castlingFormat.name,
        'showPromoted': showPromoted,
        'virginFiles': virginFiles,
      };

  static const standard =
      OutputOptions(castlingFormat: CastlingFormat.standard);
  static const chess960 =
      OutputOptions(castlingFormat: CastlingFormat.shredder);
  static const crazyhouse = OutputOptions(
    castlingFormat: CastlingFormat.standard,
    showPromoted: true,
  );
  static const seirawan = OutputOptions(
    castlingFormat: CastlingFormat.standard,
    virginFiles: true,
  );

  @override
  int get hashCode =>
      castlingFormat.hashCode ^
      showPromoted.hashCode << 1 ^
      virginFiles.hashCode << 2;

  @override
  bool operator ==(Object other) =>
      other is OutputOptions && hashCode == other.hashCode;
}

/// Determines how castling rights are represented in FEN strings.
/// There are certain positions in variants such as Chess960, in which the
/// standard 'KQkq' format could present an ambiguity.
/// See [this link](https://en.wikipedia.org/wiki/Fischer_random_chess#Coding_games_and_positions)
/// for more details.
enum CastlingFormat {
  /// The standard castling format labels rights as 'KQkq', regardless of the
  /// position of the rooks.
  standard,

  /// Uses the letters for the files that the rooks start on to represent
  /// castling rights. For example, the default chess position's castling rights
  /// would be rendered as 'HAha'.
  shredder,
}
