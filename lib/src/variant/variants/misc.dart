part of '../variant.dart';

class MiscVariants {
  static Variant spawn() => .standard().copyWith(
    name: 'Spawn Chess',
    description: 'Moving the exposed king adds a pawn to the player\'s hand.',
    startPosition: 'rnb1nbnr/8/3k4/8/8/4K3/8/RNBN1BNR[PPpp] w - - 0 1',
    handOptions: .enabledOnly,
    castlingOptions: .none,
    pieceTypes: {
      'P': .pawn(),
      'N': .knight(),
      'B': .fromBetza('B2'),
      'R': .fromBetza('R3'),
      'Q': .queen(),
      'K': .king().withAction(ActionAddToHand('P')),
    },
  );

  /// https://www.chessvariants.org/winning.dir/kinglet.html
  static Variant kinglet() => .standard().copyWith(
    name: 'Kinglet Chess',
    description: 'The first player to capture all the opponent\'s pawns wins.',
    pieceTypes: {
      'P': .pawn(),
      'N': .knight().withNoPromotion(),
      'B': .bishop().withNoPromotion(),
      'R': .rook().withNoPromotion(),
      'Q': .queen().withNoPromotion(),
      'K': .fromBetza('K', castling: true),
    },
    actions: [ActionCheckPieceCount(pieceType: 'P')],
  );

  /// https://www.chessvariants.org/winning.dir/extinction.html
  static Variant extinction() => .standard().copyWith(
    name: 'Extinction Chess',
    description:
        'The first player that does not have pieces of all '
        'types loses the game.',
    pieceTypes: {
      'P': .pawn(),
      'N': .knight(),
      'B': .bishop(),
      'R': .rook(),
      'Q': .queen(),
      'K': .fromBetza('K', castling: true),
    },
    actions: [
      ActionCheckPieceCount(pieceType: 'P'),
      ActionCheckPieceCount(pieceType: 'N'),
      ActionCheckPieceCount(pieceType: 'B'),
      ActionCheckPieceCount(pieceType: 'R'),
      ActionCheckPieceCount(pieceType: 'Q'),
      ActionCheckPieceCount(pieceType: 'K'),
    ],
  );

  static Variant threeKings() => .standard()
      .copyWith(
        name: 'Three Kings Chess',
        description:
            'Each player has three kings, but only one has to '
            'be captured for them to win.',
        startPosition: 'knbqkbnk/pppppppp/8/8/8/8/PPPPPPPP/KNBQKBNK w - - 0 1',
        castlingOptions: .none,
        actions: [ActionCheckPieceCount(pieceType: 'K', count: 3)],
      )
      .withPieces({
        'K': .fromBetza('K', promoOptions: .none),
      });

  // https://www.chessvariants.com/diffobjective.dir/utchess.html#domination
  // todo: make this serialisable, break action down
  static Variant domination({int scoreLimit = 15}) {
    final region = const RectRegion(
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

    return .standard().copyWith(
      name: 'Domination',
      actions: [
        action,
        ActionPointsEnding(limits: [scoreLimit, scoreLimit]),
      ],
    );
  }

  static Variant dart() {
    final dropRegion = const RectRegion(
      startFile: Bishop.fileB,
      endFile: Bishop.fileE,
      startRank: Bishop.rank2,
      endRank: Bishop.rank5,
    );
    return .standard().copyWith(
      name: 'Dart',
      boardSize: const BoardSize(6, 6),
      startPosition: 'knrppp/nbp3/rp3P/p3PR/3PBN/PPPRNK[XXXxxx] w - - 0 1',
      enPassant: false,
      handOptions: HandOptions(
        enableHands: true,
        dropBuilder: RegionDropBuilder.single(dropRegion),
      ),
      pieceTypes: {
        'P': .simplePawn(),
        'N': .knight(),
        'B': .bishop(),
        'R': .rook(),
        'K': .king(),
        'X': .blocker(), // a 'dart'
      },
      halfMoveDraw: 100,
    );
  }

  /// Capturing pieces, except for kings, change colour.
  /// https://en.wikipedia.org/wiki/Andernach_chess
  static Variant andernach() => .standard()
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
      'P': .fromBetza('mlfFcflW', noSanSymbol: true).promotable(),
    },
    promotionOptions: const RegionPromotion(whiteId: 'wp', blackId: 'bp'),
    regions: {
      'wp': RectRegion.lrbt(0, 0, 4, 7) + RectRegion.lrbt(0, 3, 7, 7),
      'bp': RectRegion.lrbt(7, 7, 0, 3) + RectRegion.lrbt(4, 7, 0, 0),
    },
    halfMoveDraw: 100,
  );

  /// https://www.chessvariants.com/diffobjective.dir/knightmate.html
  static Variant knightmate() => .standard()
      .withPieces({
        'K': .commoner(),
        'N': .knight().withRoyal(),
      })
      .copyWith(
        name: 'Knightmate',
        startPosition:
            'rkbqnbkr/pppppppp/8/8/8/8/PPPPPPPP/RKBQNBKR w KQkq - 0 1',
        materialConditions: .none, // it's different
      );

  /// https://www.chessvariants.com/other.dir/pocket.html
  static Variant pocketKnight() => .standard().copyWith(
    name: 'Pocket Knight',
    startPosition:
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[Nn] w KQkq - 0 1',
    handOptions: .enabledOnly,
  );
}
