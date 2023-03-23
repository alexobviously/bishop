part of '../variant.dart';

/// Xiangqi / Cờ Tướng / Chinese Chess defintions.
/// All rules are implemented and working, except for chasing restrictions.
class Xiangqi {
  static const String defaultFen =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';
  static const String defaultFenMini =
      'rcnkncr/p1ppp1p/7/7/7/P1PPP1P/RCNKNCR w - - 0 1';
  static const defaultFenManchu =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/9/9/M1BAKAB2 w - - 0 1';
  static PieceType general() => PieceType.fromBetza(
        'W',
        royal: true,
        promoOptions: PiecePromoOptions.none,
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
  static PieceType strongSoldier() => PieceType.fromBetza('fsW');
  static PieceType manchuSuperPiece() =>
      PieceType.fromBetza('RcpRnN', value: 1500);

  static Variant variant() => xiangqi();

  static Variant xiangqi() => Variant(
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
        materialConditions: MaterialConditions.none,
        promotionOptions: PromotionOptions.none,
        startPosition: defaultFen,
        regions: {
          'redSide': const RectRegion(
            startRank: Bishop.rank1,
            endRank: Bishop.rank5,
          ),
          'blackSide': const RectRegion(
            startRank: Bishop.rank6,
            endRank: Bishop.rank10,
          ),
          'redPalace': const RectRegion(
            startRank: Bishop.rank1,
            endRank: Bishop.rank3,
            startFile: Bishop.fileD,
            endFile: Bishop.fileF,
          ),
          'blackPalace': const RectRegion(
            startRank: Bishop.rank8,
            endRank: Bishop.rank10,
            startFile: Bishop.fileD,
            endFile: Bishop.fileF,
          ),
        },
        actions: [Action.flyingGenerals()],
      );

  static Variant mini() => Variant(
        name: 'Mini Xiangqi',
        description:
            'A miniature variant of Xiangqi, played on a 7x7 board with no river.',
        boardSize: BoardSize(7, 7),
        pieceTypes: {
          'K': general(),
          'N': horse(),
          'R': chariot(),
          'C': cannon(),
          'P': strongSoldier(),
        },
        startPosition: defaultFenMini,
        castlingOptions: CastlingOptions.none,
        materialConditions: MaterialConditions.none,
        promotionOptions: PromotionOptions.none,
        regions: {
          'redPalace': const RectRegion(
            startRank: Bishop.rank1,
            endRank: Bishop.rank3,
            startFile: Bishop.fileC,
            endFile: Bishop.fileE,
          ),
          'blackPalace': const RectRegion(
            startRank: Bishop.rank5,
            endRank: Bishop.rank7,
            startFile: Bishop.fileC,
            endFile: Bishop.fileE,
          ),
        },
        actions: [Action.flyingGenerals()],
      );

  static Variant manchu() {
    final x = xiangqi();
    return xiangqi().copyWith(
      name: 'Manchu',
      description:
          '''An asymmetric variant of Xiangqi, where red exchanges most of'''
          '''their pieces for one very powerful piece.''',
      startPosition: defaultFenManchu,
      pieceTypes: {
        ...x.pieceTypes,
        'M': manchuSuperPiece(),
      },
    );
  }

  static RegionEffect palaceMovement() =>
      RegionEffect.movement(white: 'redPalace', black: 'blackPalace');
  static RegionEffect sideMovement() =>
      RegionEffect.movement(white: 'redSide', black: 'blackSide');
}
