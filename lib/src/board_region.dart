import 'package:bishop/bishop.dart';

class BoardRegion {
  final String id;
  final int? startRank;
  final int? endRank;
  final int? startFile;
  final int? endFile;

  const BoardRegion({
    required this.id,
    this.startRank,
    this.endRank,
    this.startFile,
    this.endFile,
  });

  @override
  String toString() =>
      'BoardRegion($id, $startFile-$endFile, $startRank-$endRank)';
}

class RegionEffect {
  final String? whiteRegion;
  final String? blackRegion;
  final PieceType? pieceType;
  final bool restrictMovement;

  const RegionEffect({
    this.whiteRegion,
    this.blackRegion,
    this.pieceType,
    this.restrictMovement = false,
  });

  factory RegionEffect.movement({String? white, String? black}) => RegionEffect(
        whiteRegion: white,
        blackRegion: black,
        restrictMovement: true,
      );

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
}
