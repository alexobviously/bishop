part of 'variant.dart';

class Xiangqi {
  static const String defaultFen =
      'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR w - - 0 1';
  static PieceType general() => PieceType.fromBetza(
        'W',
        royal: true,
        canPromoteTo: false,
        regionEffects: [palaceMovement()],
      );
  static PieceType advisor() =>
      PieceType.fromBetza('F', regionEffects: [palaceMovement()]);
  static PieceType elephant() =>
      PieceType.fromBetza('nA', regionEffects: [sideMovement()]);
  static PieceType horse() => PieceType.fromBetza('nN');
  static PieceType chariot() => PieceType.fromBetza('R');
  static PieceType cannon() => PieceType.fromBetza('mRcpR');
  static PieceType soldier() => PieceType.fromBetza(
        'fsW',
        regionEffects: [
          RegionEffect.changePiece(
            whiteRegion: 'redSide',
            blackRegion: 'blackSide',
            pieceType: weakSoldier(),
          ),
        ],
      );
  static PieceType weakSoldier() => PieceType.fromBetza('fW');

  static Variant variant() => Variant(
        name: 'Xiangqi',
        boardSize: BoardSize.xiangqi,
        pieceTypes: {
          'K': general(),
          'A': advisor(),
          'E': elephant(),
          'H': horse(),
          'R': chariot(),
          'C': cannon(),
          'P': soldier(),
        },
        castlingOptions: CastlingOptions.none,
        materialConditions: MaterialConditions.none,
        startPosition: defaultFen,
        flyingGenerals: false, // TODO: account for other pieces, lol
        regions: [
          const BoardRegion(
            id: 'redSide',
            startRank: Bishop.rank1,
            endRank: Bishop.rank5,
          ),
          const BoardRegion(
            id: 'blackSide',
            startRank: Bishop.rank6,
            endRank: Bishop.rank10,
          ),
          const BoardRegion(
            id: 'redPalace',
            startRank: Bishop.rank1,
            endRank: Bishop.rank3,
            startFile: Bishop.fileD,
            endFile: Bishop.fileF,
          ),
          const BoardRegion(
            id: 'blackPalace',
            startRank: Bishop.rank8,
            endRank: Bishop.rank10,
            startFile: Bishop.fileD,
            endFile: Bishop.fileF,
          ),
        ],
      );
  static RegionEffect palaceMovement() =>
      RegionEffect.movement(white: 'redPalace', black: 'blackPalace');
  static RegionEffect sideMovement() =>
      RegionEffect.movement(white: 'redSide', black: 'blackSide');
}
