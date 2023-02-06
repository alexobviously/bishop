part of '../variant.dart';

/// This is a work in progress.
/// Many rules, specifically those related to dropping, are not implemented yet.
class Shogi {
  static const defaultFen =
      'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL[] w - - 0 1';

  static PieceType pawn() =>
      PieceType.fromBetza('fW', promoOptions: promotesToGold);
  static PieceType silver() =>
      PieceType.fromBetza('FfW', promoOptions: promotesToGold);
  static PieceType lance() =>
      PieceType.fromBetza('fR', promoOptions: promotesToGold);
  static PieceType knight() =>
      PieceType.fromBetza('fN', promoOptions: promotesToGold);
  static PieceType gold() => PieceType.fromBetza('WfF');

  static PieceType bishop() => PieceType.fromBetza(
        'B',
        promoOptions: PiecePromoOptions.promotesToOne('H'),
      );
  static PieceType dragonHorse() => PieceType.fromBetza('WB');

  static PieceType rook() => PieceType.fromBetza(
        'R',
        promoOptions: PiecePromoOptions.promotesToOne('D'),
      );
  static PieceType dragonKing() => PieceType.fromBetza('FR');

  static PiecePromoOptions get promotesToGold =>
      PiecePromoOptions.promotesToOne('G');

  static Variant variant() => shogi();

  static Variant shogi() => Variant(
        name: 'Shogi',
        boardSize: BoardSize(9, 9),
        pieceTypes: {
          'K': PieceType.king(),
          'N': knight(),
          'S': silver(),
          'L': lance(),
          'P': pawn(),
          'G': gold(),
          'R': rook(),
          'D': dragonKing(),
          'B': bishop(),
          'H': dragonHorse(),
        },
        startPosition: defaultFen,
        handOptions: HandOptions.captures,
        promotionOptions: PromotionOptions.optional(
          ranks: [Bishop.rank7, Bishop.rank3],
        ),
      );
}

class Dobutsu {
  static const defaultFen = 'gle/1c1/1C1/ELG[-] w - - 0 1';

  static PieceType giraffe() =>
      PieceType.fromBetza('W', promoOptions: PiecePromoOptions.none);
  static PieceType elephant() =>
      PieceType.fromBetza('F', promoOptions: PiecePromoOptions.none);
  static PieceType chick() =>
      PieceType.fromBetza('fW', promoOptions: PiecePromoOptions.promotable);
  static PieceType hen() => Shogi.gold();
  static PieceType lion() => PieceType.king();

  static Variant variant() => dobutsu();

  static Variant dobutsu() => Variant(
        name: 'Dobutsu Shogi',
        description: 'A simple Shogi variant aimed at children.',
        boardSize: BoardSize(3, 4),
        startPosition: defaultFen,
        pieceTypes: {
          'L': lion(),
          'G': giraffe(),
          'E': elephant(),
          'C': chick(),
          'H': hen(),
        },
        handOptions: HandOptions(
          enableHands: true,
          addCapturesToHand: true,
          dropBuilder: DropBuilder.unrestricted,
        ),
      ).withCampMate();
}
