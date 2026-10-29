part of '../variant.dart';

/// Common chess variants with different rules.
class CommonVariants {
  static Variant chess960() => Variant.standard().copyWith(
    name: 'Chess960',
    startPosBuilder: Chess960StartPosBuilder(),
    castlingOptions: .chess960,
    outputOptions: .chess960,
  );

  static Variant crazyhouse() => .standard().copyWith(
    name: 'Crazyhouse',
    handOptions: .captures,
  );

  static Variant seirawan() {
    final standard = Variant.standard();
    return standard.copyWith(
      name: 'Seirawan Chess',
      startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[HEhe] w KQkqABCDEFGHabcdefgh - 0 1',
      gatingMode: .flex,
      outputOptions: .seirawan,
      pieceTypes: {
        ...standard.pieceTypes,
        'H': .archbishop(), // hawk
        'E': .chancellor(), // elephant
      },
      materialConditions: .standard.copyWith(
        soloMaters: ['P', 'Q', 'R', 'E', 'H'],
      ),
    );
  }

  static Variant threeCheck() => .standard().copyWith(
    name: 'Three Check',
    gameEndConditions: .threeCheck,
  );

  static Variant kingOfTheHill() => .standard()
      .copyWith(name: 'King of the Hill')
      .withPiece(
        'K',
        .king().withRegionEffect(
          RegionEffect.winGame(white: 'hill', black: 'hill'),
        ),
      )
      .withRegion(
        'hill',
        const RectRegion(
          startFile: Bishop.fileD,
          endFile: Bishop.fileE,
          startRank: Bishop.rank4,
          endRank: Bishop.rank5,
        ),
      );

  static Variant atomic({bool allowExplosionDraw = false}) =>
      .standard().copyWith(
        name: 'Atomic Chess',
        actions: [
          ActionExplosionRadius(1, immunePieces: ['P']),
          ActionCheckRoyalsAlive(allowDraw: allowExplosionDraw),
        ],
      );

  static Variant horde() => Variant.standard().copyWith(
    name: 'Horde Chess',
    startPosition: 'rnbqkbnr/pppppppp/8/1PP2PP1/PPPPPPPP/PPPPPPPP/PPPPPPPP/PPPPPPPP w kq - 0 1',
    firstMoveOptions: .ranks(
      [Bishop.rank1, Bishop.rank2], // white
      [Bishop.rank7, Bishop.rank8], // black
    ),
  );

  static Variant racingKings() => Variant.standard()
      .copyWith(
        name: 'Racing Kings',
        description:
            'The first player to run their king to the finish line wins.',
        startPosition: '8/8/8/8/8/8/krbnNBRK/qrbnNBRQ w - - 0 1',
        castlingOptions: .none,
        materialConditions: .none,
        forbidChecks: true,
      )
      .withCampMate(
        whiteRegionName: 'end',
        blackRegionName: 'end',
        whiteRank: -1,
        blackRank: -1,
      ); // TODO: racing kings should be a draw if black reaches right after white - depends on deferred actions

  static Variant antichess() => Variant.standard()
      .copyWith(
        name: 'Antichess',
        description: 'Lose all your pieces to win.',
        gameEndConditions: .antichess,
        forcedCapture: .any,
        castlingOptions: .none,
        materialConditions: .none,
      )
      .withPiece('K', .fromBetza('K', value: 400))
      .invertPieceValues();

  /// Not production ready yet. Work in progress.
  static Variant duck() => .standard()
      .withPieces({
        '*': .duck(),
        'K': .commoner(),
      })
      .withAction(ActionCheckPieceCount(pieceType: 'K'))
      .copyWith(
        name: 'Duck Chess',
        materialConditions: .none,
      );

  /// https://en.wikipedia.org/wiki/Shatranj
  static Variant shatranj() => .standard()
      .withPieces({
        'B': .alfil(),
        'Q': .ferz(),
        'P': .simplePawn().copyWith(
          promoOptions: .promotesToOne('Q'),
        ),
      })
      .copyWith(
        name: 'Shatranj',
        castlingOptions: .none,
        materialConditions: .none,
        enPassant: false,
        gameEndConditions: const GameEndConditions(stalemate: .lose)
            .symmetric(),
      );

  // TODO: makruk counting (https://github.com/alexobviously/bishop/issues/35)

  /// Traditional Thai chess variant.
  /// Currently doesn't include the counting rules!
  /// https://en.wikipedia.org/wiki/Makruk
  static Variant makruk() => .standard()
      .withPieces({
        'B': .fromBetza('FfW'), // Khon (Nobleman / Silver)
        'S': .fromBetza('FfW'), // Khon alias
        'Q': .ferz().copyWith(promoOptions: .promoPiece), // Met (Seed / Ferz)
        'M': .ferz().copyWith(promoOptions: .promoPiece), // Met alias
        'P': .simplePawn().copyWith(promoOptions: .promotesToOne('Q')),
      })
      .copyWith(
        name: 'Makruk',
        description: 'Traditional Thai chess.',
        startPosition: 'rnbkqbnr/8/pppppppp/8/8/PPPPPPPP/8/RNBKQBNR w - - 0 1',
        castlingOptions: .none,
        materialConditions: .none,
        enPassant: false,
        promotionOptions: .ranks([Bishop.rank6, Bishop.rank3]),
        gameEndConditions: const GameEndConditions(
          stalemate: .draw,
        ).symmetric(),
      );
}
