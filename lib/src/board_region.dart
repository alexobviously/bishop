import 'dart:math';

import 'package:bishop/bishop.dart';

abstract class Region {
  bool contains(int file, int rank);
  List<int> squares(BoardSize size);
  Region translate(int x, int y);
}

/// A region on a board used to define area-specific piece behaviour.
class BoardRegion implements Region {
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

  const BoardRegion({
    this.startRank,
    this.endRank,
    this.startFile,
    this.endFile,
  });

  BoardRegion finalise(BoardSize size) => BoardRegion(
        startRank: startRank ?? 0,
        endRank: endRank ?? size.maxRank,
        startFile: startFile ?? 0,
        endFile: endFile ?? size.maxFile,
      );

  @override
  String toString() => 'BoardRegion($startFile-$endFile, $startRank-$endRank)';

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
  List<int> squares(BoardSize size) {
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
    ).expand((e) => e).map((e) => size.square(e.h, e.v)).toList();
  }

  @override
  BoardRegion translate(int x, int y) => BoardRegion(
        startRank: startRank != null ? startRank! + y : null,
        endRank: endRank != null ? endRank! + y : null,
        startFile: startFile != null ? startFile! + x : null,
        endFile: endFile != null ? endFile! + x : null,
      );
}

class Area implements Region {
  final List<Direction> directions;

  int get minX => directions.map((e) => e.h).reduce(min);
  int get minY => directions.map((e) => e.v).reduce(min);
  int get maxX => directions.map((e) => e.h).reduce(max);
  int get maxY => directions.map((e) => e.v).reduce(max);

  const Area({required this.directions});

  factory Area.filled({
    required int width,
    required int height,
    int xOffset = 0,
    int yOffset = 0,
    bool omitCentre = false,
  }) {
    int xStart = -(width ~/ 2) + xOffset;
    int yStart = -(height ~/ 2) + yOffset;
    List<Direction> dirs = List.generate(
      width,
      (x) => List.generate(height, (y) => Direction(x + xStart, y + yStart)),
    ).expand((e) => e).toList();
    if (omitCentre) {
      dirs.remove(Direction(0, 0));
    }
    return Area(directions: dirs);
  }

  factory Area.radius(int size, {bool omitCentre = false}) => Area.filled(
        width: size * 2 + 1,
        height: size * 2 + 1,
        omitCentre: omitCentre,
      );

  @override
  Area translate(int x, int y) =>
      Area(directions: directions.map((e) => e.translate(x, y)).toList());

  @override
  bool contains(int file, int rank) =>
      directions.contains(Direction(file, rank));

  @override
  List<int> squares(BoardSize size) {
    List<Direction> dirs = [...directions];
    dirs.removeWhere(
      (e) => e.h < 0 || e.v < 0 || e.h > size.maxFile || e.v > size.maxRank,
    );
    return dirs.map((e) => size.square(e.h, e.v)).toList();
  }
}

/// Defines an effect that a region will have on a piece type.
class RegionEffect {
  /// Corresponds to a `BoardRegion.id`.
  final String? whiteRegion;

  /// Corresponds to a `BoardRegion.id`.
  final String? blackRegion;

  /// If a piece type is provided, it will replace the piece this effect
  /// belongs to whenever the piece is in the region.
  final PieceType? pieceType;

  /// If true, pieces with this region effect applied to them will not be
  /// able to leave the region.
  final bool restrictMovement;

  /// If true, a piece with this region effect entering this region will
  /// win the game.
  final bool winGame;

  /// Returns [whiteRegion] for white and [blackRegion] for black.
  String? regionForPlayer(int player) => player == Bishop.white
      ? whiteRegion
      : player == Bishop.black
          ? blackRegion
          : null;

  const RegionEffect({
    this.whiteRegion,
    this.blackRegion,
    this.pieceType,
    this.restrictMovement = false,
    this.winGame = false,
  });

  RegionEffect copyWith({
    String? whiteRegion,
    String? blackRegion,
    PieceType? pieceType,
    bool? restrictMovement,
    bool? winGame,
  }) =>
      RegionEffect(
        whiteRegion: whiteRegion ?? this.whiteRegion,
        blackRegion: blackRegion ?? this.blackRegion,
        pieceType: pieceType ?? this.pieceType,
        restrictMovement: restrictMovement ?? this.restrictMovement,
        winGame: winGame ?? this.winGame,
      );

  RegionEffect normalise(BoardSize size) => pieceType == null
      ? this
      : copyWith(pieceType: pieceType!.normalise(size));

  /// An effect that restricts the movement of the piece to within the region.
  factory RegionEffect.movement({String? white, String? black}) => RegionEffect(
        whiteRegion: white,
        blackRegion: black,
        restrictMovement: true,
      );

  /// An effect that causes the piece to change to a different type when within
  /// the region.
  factory RegionEffect.changePiece({
    String? whiteRegion,
    String? blackRegion,
    required PieceType pieceType,
  }) =>
      RegionEffect(
        whiteRegion: whiteRegion,
        blackRegion: blackRegion,
        pieceType: pieceType,
      );

  factory RegionEffect.winGame({String? white, String? black}) => RegionEffect(
        whiteRegion: white,
        blackRegion: black,
        winGame: true,
      );
}
