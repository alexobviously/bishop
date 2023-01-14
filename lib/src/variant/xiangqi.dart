part of 'variant.dart';

/// Xiangqi / Cờ Tướng / Chinese Chess defintions.
/// Still a work in progress, some things are incomplete.
class Xiangqi {
  static const String defaultFen =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';
  static PieceType general() => PieceType.fromBetza(
        'W',
        royal: true,
        canPromoteTo: false,
        regionEffects: [palaceMovement()],
      );
  static PieceType advisor() =>
      PieceType.fromBetza('F', value: 200, regionEffects: [palaceMovement()]);
  static PieceType elephant() =>
      PieceType.fromBetza('nA', value: 200, regionEffects: [sideMovement()]);
  static PieceType horse() => PieceType.fromBetza('nN', value: 400);
  static PieceType chariot() => PieceType.fromBetza('R', value: 900);
  static PieceType cannon() => PieceType.fromBetza('mRcpR', value: 450);
  static PieceType soldier() => PieceType.fromBetza(
        'fsW',
        value:
            100, // TODO: this should be 200 but multi-value pieces aren't supported
        regionEffects: [
          RegionEffect.changePiece(
            whiteRegion: 'redSide',
            blackRegion: 'blackSide',
            pieceType: weakSoldier(),
          ),
        ],
      );
  static PieceType weakSoldier() => PieceType.fromBetza('fW', value: 100);

  static Variant variant() => Variant(
        name: 'Xiangqi',
        boardSize: BoardSize.xiangqi,
        pieceTypes: {
          'K': general(),
          'A': advisor(),
          'B': elephant(),
          'N': horse(),
          'R': chariot(),
          'C': cannon(),
          'P': soldier(),
        },
        castlingOptions: CastlingOptions.none,
        materialConditions: MaterialConditions.none,
        promotionOptions: PromotionOptions.none,
        startPosition: defaultFen,
        regions: {
          'redSide': const BoardRegion(
            startRank: Bishop.rank1,
            endRank: Bishop.rank5,
          ),
          'blackSide': const BoardRegion(
            startRank: Bishop.rank6,
            endRank: Bishop.rank10,
          ),
          'redPalace': const BoardRegion(
            startRank: Bishop.rank1,
            endRank: Bishop.rank3,
            startFile: Bishop.fileD,
            endFile: Bishop.fileF,
          ),
          'blackPalace': const BoardRegion(
            startRank: Bishop.rank8,
            endRank: Bishop.rank10,
            startFile: Bishop.fileD,
            endFile: Bishop.fileF,
          ),
        },
        actions: [Action.flyingGenerals()],
      );
  static RegionEffect palaceMovement() =>
      RegionEffect.movement(white: 'redPalace', black: 'blackPalace');
  static RegionEffect sideMovement() =>
      RegionEffect.movement(white: 'redSide', black: 'blackSide');
}
