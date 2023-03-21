part of 'regions.dart';

/// A region on a board used to define area-specific piece behaviour.
class RectRegion implements BoardRegion {
  /// The rank the region starts at, inclusive.
  /// If null, the first rank will be used.
  final int? startRank;

  /// The rank the region ends at, inclusive.
  /// If null, the last rank will be used.
  final int? endRank;

  /// The file the region starts at, inclusive.
  /// If null, the first file will be used.
  final int? startFile;

  /// The file the region ends at, inclusive.
  /// If null, the last file will be used.
  final int? endFile;

  const RectRegion({
    this.startRank,
    this.endRank,
    this.startFile,
    this.endFile,
  });

  factory RectRegion.lrbt(int? l, int? r, int? b, int? t) =>
      RectRegion(startFile: l, endFile: r, startRank: b, endRank: t);

  /// A board region consisting of the entirety of a single rank.
  factory RectRegion.rank(int rank) =>
      RectRegion(startRank: rank, endRank: rank);

  /// A board region consisting of the entirety of a single file.
  factory RectRegion.file(int file) =>
      RectRegion(startFile: file, endFile: file);

  /// A board region consisting of a single square.
  factory RectRegion.square(int file, int rank) => RectRegion(
        startFile: file,
        endFile: file,
        startRank: rank,
        endRank: rank,
      );

  factory RectRegion.fromJson(Map<String, dynamic> json) => RectRegion(
        startRank: json['b'] ?? json['startRank'],
        endRank: json['t'] ?? json['endRank'],
        startFile: json['l'] ?? json['startFile'],
        endFile: json['r'] ?? json['endFile'],
      );

  @override
  Map<String, dynamic> toJson() => {
        if (startRank != null) 'b': startRank,
        if (endRank != null) 't': endRank,
        if (startFile != null) 'l': startFile,
        if (endFile != null) 'r': endFile,
      };

  RectRegion finalise(BoardSize size) => RectRegion(
        startRank: startRank ?? 0,
        endRank: endRank ?? size.maxRank,
        startFile: startFile ?? 0,
        endFile: endFile ?? size.maxFile,
      );

  @override
  String toString() => 'RectRegion($startFile-$endFile, $startRank-$endRank)';

  @override
  bool contains(int file, int rank) {
    if (startFile != null && file < startFile!) {
      return false;
    }
    if (endFile != null && file > endFile!) {
      return false;
    }
    if (startRank != null && rank < startRank!) {
      return false;
    }
    if (endRank != null && rank > endRank!) {
      return false;
    }
    return true;
  }

  @override
  Set<int> squares(BoardSize size) {
    int startFile = this.startFile ?? 0;
    int startRank = this.startRank ?? 0;
    int endFile = this.endFile ?? size.maxFile;
    int endRank = this.endRank ?? size.maxRank;
    int width = (endFile - startFile) + 1;
    int height = (endRank - startRank) + 1;
    return List.generate(
      width,
      (x) =>
          List.generate(height, (y) => Direction(x + startFile, y + startRank)),
    ).expand((e) => e).map((e) => size.square(e.h, e.v)).toSet();
  }

  @override
  RectRegion translate(int x, int y) => RectRegion(
        startRank: startRank != null ? startRank! + y : null,
        endRank: endRank != null ? endRank! + y : null,
        startFile: startFile != null ? startFile! + x : null,
        endFile: endFile != null ? endFile! + x : null,
      );
}
