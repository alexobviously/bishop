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
          'K': PieceType.fromBetza('K'),
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

  /// Knights only. Move a knight onto the central square and off it again
  /// to win.
  /// https://en.wikipedia.org/wiki/Jeson_Mor
  static Variant jesonMor() => Variant(
        name: 'Jeson Mor',
        description:
            'Knights only. Move a knight onto the central square and off'
            ' it again to win.',
        boardSize: BoardSize(9, 9),
        startPosition: 'nnnnnnnnn/9/9/9/9/9/9/9/NNNNNNNNN w - - 0 1',
        pieceTypes: {'N': PieceType.knight()},
        promotionOptions: PromotionOptions.none,
        actions: [
          ActionExitRegionEnding(
            region: RectRegion.square(Bishop.fileE, Bishop.rank5),
          ),
        ],
        halfMoveDraw: 100,
      );

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

  /// https://en.wikipedia.org/wiki/Clobber
  static Variant clobber() => Variant(
        name: 'Clobber',
        startPosition: 'PpPpP/pPpPp/PpPpP/pPpPp/PpPpP/pPpPp w - - 0 1',
        boardSize: BoardSize(5, 6),
        pieceTypes: {'P': PieceType.fromBetza('cW')},
        gameEndConditions: GameEndConditionSet.symmetric(
          GameEndConditions(stalemate: EndType.lose),
        ),
        promotionOptions: PromotionOptions.none,
      );

  /// https://en.wikipedia.org/wiki/Clobber#Variants
  static Variant clobber10() => clobber().copyWith(
        name: 'Clobber10',
        boardSize: BoardSize(10, 10),
        startPosition: 'PpPpPpPpPp/pPpPpPpPpP/PpPpPpPpPp/pPpPpPpPpP/PpPpPpPpPp/'
            'pPpPpPpPpP/PpPpPpPpPp/pPpPpPpPpP'
            '/PpPpPpPpPp/pPpPpPpPpP w - - 0 1',
      );

  /// https://en.wikipedia.org/wiki/Five_Field_Kono
  static Variant kono() => Variant(
        name: 'Five Field Kono',
        boardSize: BoardSize(5, 5),
        startPosition: 'ppppp/p3p/5/P3P/PPPPP w - - 0 1',
        // startPosition: 'PPPPP/4P/1P3/5/4p w - - 0 1',
        pieceTypes: {'P': PieceType.fromBetza('mF')},
        regions: {
          'w': SetRegion(['a5', 'b5', 'c5', 'd5', 'e5', 'a4', 'e4']),
          'b': SetRegion(['a1', 'b1', 'c1', 'd1', 'e1', 'a2', 'e2']),
        },
        promotionOptions: PromotionOptions.none,
      ).withAction(ActionFillRegionEnding('w', 'b'));
}
