part of '../variant.dart';

class MiscVariants {
  @Deprecated('Use FairyVariants.hoppelPoppel()')
  static Variant hoppelPoppel() => FairyVariants.hoppelPoppel();

  static Variant spawn() => Variant.standard().copyWith(
        name: 'Spawn Chess',
        description:
            'Moving the exposed king adds a pawn to the player\'s hand.',
        startPosition: 'rnb1nbnr/8/3k4/8/8/4K3/8/RNBN1BNR[PPpp] w - - 0 1',
        handOptions: HandOptions.enabledOnly,
        castlingOptions: CastlingOptions.none,
        pieceTypes: {
          'P': PieceType.pawn(),
          'N': PieceType.knight(),
          'B': PieceType.fromBetza('B2'),
          'R': PieceType.fromBetza('R3'),
          'Q': PieceType.queen(),
          'K': PieceType.king().withAction(ActionAddToHand('P')),
        },
      );

  static Variant kinglet() => Variant.standard().copyWith(
        name: 'Kinglet Chess',
        description:
            'The first player to capture all the opponent\'s pawns wins.',
        pieceTypes: {
          'P': PieceType.pawn(),
          'N': PieceType.knight().withNoPromotion(),
          'B': PieceType.bishop().withNoPromotion(),
          'R': PieceType.rook().withNoPromotion(),
          'Q': PieceType.queen().withNoPromotion(),
          'K': PieceType.fromBetza('K', castling: true),
        },
        actions: [ActionCheckPieceCount(pieceType: 'P')],
      );

  static Variant threeKings() => Variant.standard().copyWith(
        name: 'Three Kings Chess',
        description:
            'Each player has three kings, but only one has to be captured for them to win.',
        startPosition: 'knbqkbnk/pppppppp/8/8/8/8/PPPPPPPP/KNBQKBNK w - - 0 1',
        castlingOptions: CastlingOptions.none,
        actions: [ActionCheckPieceCount(pieceType: 'K', count: 3)],
      ).withPieces({
        'K': PieceType.fromBetza('K', promoOptions: PiecePromoOptions.none),
      });

  // https://www.chessvariants.com/diffobjective.dir/utchess.html#domination
  // todo: make this serialisable, break action down
  static Variant domination({int scoreLimit = 15}) {
    final region = RectRegion(
      startFile: Bishop.fileD,
      endFile: Bishop.fileE,
      startRank: Bishop.rank4,
      endRank: Bishop.rank5,
    );
    final action = Action(
      action: (trigger) {
        List<ActionEffect> effects = [];
        List<int> incs = [0, 0];
        for (int sq in trigger.size.squaresForRegion(region)) {
          int content = trigger.board[sq];
          if (content.isNotEmpty) {
            incs[content.colour]++;
          }
        }
        for (int i = 0; i < incs.length; i++) {
          if (incs[i] > 0) {
            int value = trigger.getCustomState(i) + incs[i];
            effects.add(EffectSetCustomState(i, value));
          }
        }
        return effects;
      },
    );
    return Variant.standard().copyWith(
      name: 'Domination',
      actions: [
        action,
        ActionPointsEnding(limits: [scoreLimit, scoreLimit]),
      ],
    );
  }

  static Variant dart() {
    final dropRegion = RectRegion(
      startFile: Bishop.fileB,
      endFile: Bishop.fileE,
      startRank: Bishop.rank2,
      endRank: Bishop.rank5,
    );
    return Variant(
      name: 'Dart',
      boardSize: BoardSize(6, 6),
      startPosition: 'knrppp/nbp3/rp3P/p3PR/3PBN/PPPRNK[XXXxxx] w - - 0 1',
      enPassant: false,
      handOptions: HandOptions(
        enableHands: true,
        dropBuilder: RegionDropBuilder.single(dropRegion),
      ),
      pieceTypes: {
        'P': PieceType.simplePawn(),
        'N': PieceType.knight(),
        'B': PieceType.bishop(),
        'R': PieceType.rook(),
        'K': PieceType.king(),
        'X': PieceType.blocker(), // a 'dart'
      },
      halfMoveDraw: 100,
    );
  }

  /// Capturing pieces, except for kings, change colour.
  /// https://en.wikipedia.org/wiki/Andernach_chess
  static Variant andernach() => Variant.standard()
      .copyWith(
        name: 'Andernach Chess',
        description: 'Capturing pieces, except for kings, change colour.',
      )
      .withAction(ActionTransferOwnership(quiet: false));

  static Variant legan() => Variant(
        name: 'Legan Chess',
        startPosition:
            'knbrp3/bqpp4/npp5/rp1p3P/p3P1PR/5PPN/4PPQB/3PRBNK w - - 0 1',
        pieceTypes: {
          ...Variant.standard().pieceTypes,
          'P': PieceType.fromBetza('mlfFcflW', noSanSymbol: true).promotable(),
        },
        promotionOptions: RegionPromotion(whiteId: 'wp', blackId: 'bp'),
        regions: {
          'wp': RectRegion.lrbt(0, 0, 4, 7) + RectRegion.lrbt(0, 3, 7, 7),
          'bp': RectRegion.lrbt(7, 7, 0, 3) + RectRegion.lrbt(4, 7, 0, 0),
        },
        halfMoveDraw: 100,
      );

  /// https://www.chessvariants.com/diffobjective.dir/knightmate.html
  static Variant knightmate() => Variant.standard().withPieces({
        'K': PieceType.commoner(),
        'N': PieceType.knight().withRoyal(),
      }).copyWith(
        name: 'Knightmate',
        startPosition:
            'rkbqnbkr/pppppppp/8/8/8/8/PPPPPPPP/RKBQNBKR w KQkq - 0 1',
        materialConditions: MaterialConditions.none, // it's different
      );

  /// https://www.chessvariants.com/other.dir/pocket.html
  static Variant pocketKnight() => Variant.standard().copyWith(
        name: 'Pocket Knight',
        startPosition:
            'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[Nn] w KQkq - 0 1',
        handOptions: HandOptions.enabledOnly,
      );
}
