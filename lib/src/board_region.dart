import 'package:bishop/bishop.dart';

/// A region on a board used to define area-specific piece behaviour.
class BoardRegion {
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

  @override
  String toString() => 'BoardRegion($startFile-$endFile, $startRank-$endRank)';
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
