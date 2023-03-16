part of '../variant.dart';

class MiscVariants {
  static Variant hoppelPoppel() => Variant.standard()
      .copyWith(name: 'Hoppel-Poppel')
      .withPieces({'N': PieceType.knibis(), 'B': PieceType.biskni()});

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
    final region = BoardRegion(
      startFile: Bishop.fileD,
      endFile: Bishop.fileE,
      startRank: Bishop.rank4,
      endRank: Bishop.rank5,
    );
    final action = Action(
      action: (trigger) {
        List<ActionEffect> effects = [];
        List<int> incs = [0, 0];
        for (int sq in trigger.size.squaresForBoardRegion(region)) {
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
    final dropRegion = BoardRegion(
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
      castlingOptions: CastlingOptions.none,
      handOptions: HandOptions(
        enableHands: true,
        dropBuilder: DropBuilder.region(dropRegion),
      ),
      pieceTypes: {
        'P': PieceType.simplePawn(),
        'N': PieceType.knight(),
        'B': PieceType.bishop(),
        'R': PieceType.rook(),
        'K': PieceType.king(),
        'X': PieceType.blocker(), // a 'dart'
      },
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
        castlingOptions: CastlingOptions.none,
        promotionOptions: PromotionOptions.none,
        actions: [
          ActionExitRegionEnding(
            region: BoardRegion.square(Bishop.fileE, Bishop.rank5),
          )
        ],
      );
}
