part of '../variant.dart';

/// This is a work in progress.
/// Many rules, specifically those related to dropping, are not implemented yet.
abstract class Shogi {
  static const defaultFen =
      'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL[] w - - 0 1';

  static PieceType pawn() => .fromBetza('fW', promoOptions: promotesToGold);
  static PieceType silver() => .fromBetza('FfW', promoOptions: promotesToGold);
  static PieceType lance() => .fromBetza('fR', promoOptions: promotesToGold);
  static PieceType knight() => .fromBetza('fN', promoOptions: promotesToGold);
  static PieceType gold() => .fromBetza('WfF');

  static PieceType bishop() => .fromBetza(
    'B',
    promoOptions: .promotesToOne('H'),
  );
  static PieceType dragonHorse() => .fromBetza('WB');

  static PieceType rook() => .fromBetza(
    'R',
    promoOptions: .promotesToOne('D'),
  );
  static PieceType dragonKing() => .fromBetza('FR');

  static PiecePromoOptions get promotesToGold => .promotesToOne('G');

  static Variant variant() => shogi();

  static Variant shogi() => Variant(
    name: 'Shogi',
    boardSize: const BoardSize(9, 9),
    pieceTypes: {
      'K': .king(),
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
    handOptions: .captures,
    promotionOptions: .optional(
      ranks: [Bishop.rank7, Bishop.rank3],
    ),
  );
}

abstract class Dobutsu {
  static const defaultFen = 'gle/1c1/1C1/ELG[-] w - - 0 1';

  static PieceType giraffe() => .fromBetza('W', promoOptions: .none);
  static PieceType elephant() => .fromBetza('F', promoOptions: .none);
  static PieceType chick() => .fromBetza('fW', promoOptions: .promotable);
  static PieceType hen() => Shogi.gold();
  static PieceType lion() => .king();

  static Variant variant() => dobutsu();

  static Variant dobutsu() => Variant(
    name: 'Dobutsu Shogi',
    description: 'A simple Shogi variant aimed at children.',
    boardSize: const BoardSize(3, 4),
    startPosition: defaultFen,
    pieceTypes: {
      'L': lion(),
      'G': giraffe(),
      'E': elephant(),
      'C': chick(),
      'H': hen(),
    },
    handOptions: const HandOptions(
      enableHands: true,
      addCapturesToHand: true,
      dropBuilder: .unrestricted,
    ),
  ).withCampMate();
}
