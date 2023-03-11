import 'package:bishop/bishop.dart';

/// The information parsed from a PGN file.
/// This format is quite subject to change, since branch parsing support is coming.
class PgnData {
  final Map<String, String> metadata;
  final List<String> moves;
  final Map<int, String> comments;

  Variant? get variant => metadata.containsKey('Variant')
      ? variantFromString(metadata['Variant']!)
      : null;

  String? get fen => metadata['FEN'];

  const PgnData({
    required this.metadata,
    required this.moves,
    required this.comments,
  });

  Game buildGame() => gameFromPgnData(this);
}

/// Parses a [pgn].
/// Supports metadata tags and comments, but not sub-lines (yet).
PgnData parsePgn(String pgn) {
  Map<String, String> metadata = {};
  final r = RegExp(r'(\[(.+)\s"(.+)"\])+');
  final matches = r.allMatches(pgn);
  for (final m in matches) {
    String key = m.group(2)!;
    String value = m.group(3)!;
    metadata[key] = value;
  }
  int metaEnd = matches.last.end;
  String game = pgn.substring(metaEnd).replaceAll('\n', ' ');
  int i = 0;
  List<String> moves = [];
  Map<int, String> comments = {};
  final numRegex = RegExp(r'([0-9]+\.+ )');
  while (i < game.length) {
    String substr = game.substring(i);
    if (substr[0] == ' ') {
      i++;
      continue;
    }
    final numMatch = numRegex.firstMatch(substr);
    if (numMatch?.start == 0) {
      i += numMatch!.end;
      continue;
    }
    if (substr[0] == '{') {
      int commentEnd = substr.indexOf('}');
      String comment = substr.substring(1, commentEnd - 1).trim();
      comments[moves.length] = comment;
      i += commentEnd + 1;
      continue;
    }
    int end = substr.indexOf(' ');
    if (end == -1) {
      end = substr.length;
    }
    String move = substr.substring(0, end);
    moves.add(move);
    i += end + 1;
  }

  return PgnData(metadata: metadata, moves: moves, comments: comments);
}

/// Builds a game from already parsed [data].
/// If [variant] or [startPosition] are not supplied, tags will be used, if
/// they exist.
Game gameFromPgnData(PgnData data, {Variant? variant, String? startPosition}) {
  variant ??= data.variant;
  startPosition ??= data.fen;
  final g = Game(variant: variant, fen: startPosition);
  for (String move in data.moves) {
    g.makeMoveSan(move);
  }
  return g;
}

/// Parses a [pgn] and builds a game from it.
/// If [variant] is not supplied, the parser will look for a variant tag.
Game gameFromPgn(String pgn, {Variant? variant, String? startPosition}) =>
    gameFromPgnData(
      parsePgn(pgn),
      variant: variant,
      startPosition: startPosition,
    );
