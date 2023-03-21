part of 'regions.dart';

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

  factory RegionEffect.fromJson(Map<String, dynamic> json) => RegionEffect(
        whiteRegion: json['whiteRegion'],
        blackRegion: json['blackRegion'],
        pieceType: json.containsKey('pieceType')
            ? PieceType.fromJson(json['pieceType'])
            : null,
        restrictMovement: json['restrictMovement'] ?? false,
        winGame: json['winGame'] ?? false,
      );

  Map<String, dynamic> toJson({bool verbose = false}) => {
        if (whiteRegion != null) 'whiteRegion': whiteRegion,
        if (blackRegion != null) 'blackRegion': blackRegion,
        if (pieceType != null) 'pieceType': pieceType!.toJson(verbose: verbose),
        if (verbose || restrictMovement) 'restrictMovement': restrictMovement,
        if (verbose || winGame) 'winGame': winGame,
      };

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
