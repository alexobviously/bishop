part of '../variant.dart';

/// Common chess variants with different rules.
class CommonVariants {
  static Variant chess960() => Variant.standard().copyWith(
        name: 'Chess960',
        startPosBuilder: Chess960StartPosBuilder(),
        castlingOptions: CastlingOptions.chess960,
        outputOptions: OutputOptions.chess960,
      );

  static Variant crazyhouse() => Variant.standard().copyWith(
        name: 'Crazyhouse',
        handOptions: HandOptions.captures,
      );

  static Variant seirawan() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Seirawan Chess',
      startPosition:
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[HEhe] w KQkqABCDEFGHabcdefgh - 0 1',
      gatingMode: GatingMode.flex,
      outputOptions: OutputOptions.seirawan,
      pieceTypes: {
        ...standard.pieceTypes,
        'H': PieceType.archbishop(), // hawk
        'E': PieceType.chancellor(), // elephant
      },
    );
  }

  static Variant threeCheck() => Variant.standard().copyWith(
        name: 'Three Check',
        gameEndConditions: GameEndConditionSet.threeCheck,
      );

  static Variant kingOfTheHill() => Variant.standard()
      .copyWith(name: 'King of the Hill')
      .withPiece(
        'K',
        PieceType.king().withRegionEffect(
          RegionEffect.winGame(white: 'hill', black: 'hill'),
        ),
      )
      .withRegion(
        'hill',
        RectRegion(
          startFile: Bishop.fileD,
          endFile: Bishop.fileE,
          startRank: Bishop.rank4,
          endRank: Bishop.rank5,
        ),
      );

  static Variant atomic({bool allowExplosionDraw = false}) =>
      Variant.standard().copyWith(
        name: 'Atomic Chess',
        actions: [
          ActionExplosionRadius(1, immunePieces: ['P']),
          ActionCheckRoyalsAlive(allowDraw: allowExplosionDraw),
        ],
      );

  static Variant horde() => Variant.standard().copyWith(
        name: 'Horde Chess',
        startPosition:
            'rnbqkbnr/pppppppp/8/1PP2PP1/PPPPPPPP/PPPPPPPP/PPPPPPPP/PPPPPPPP w kq - 0 1',
        firstMoveOptions: FirstMoveOptions.ranks(
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
        castlingOptions: CastlingOptions.none,
        materialConditions: MaterialConditions.none,
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
        gameEndConditions: GameEndConditionSet.antichess,
        forcedCapture: ForcedCapture.any,
        castlingOptions: CastlingOptions.none,
        materialConditions: MaterialConditions.none,
      )
      .withPiece('K', PieceType.fromBetza('K', value: 400))
      .invertPieceValues();

  /// Not production ready yet. Work in progress.
  static Variant duck() => Variant.standard()
      .withPieces({
        '*': PieceType.duck(),
        'K': PieceType.commoner(),
      })
      .withAction(ActionCheckPieceCount(pieceType: 'K'))
      .copyWith(
        name: 'Duck Chess',
        materialConditions: MaterialConditions.none,
      );

  /// https://en.wikipedia.org/wiki/Shatranj
  static Variant shatranj() => Variant.standard().withPieces({
        'B': PieceType.alfil(),
        'Q': PieceType.ferz(),
        'P': PieceType.simplePawn()
            .copyWith(promoOptions: PiecePromoOptions.promotesToOne('Q')),
      }).copyWith(
        name: 'Shatranj',
        castlingOptions: CastlingOptions.none,
        materialConditions: MaterialConditions.none,
        enPassant: false,
        gameEndConditions:
            GameEndConditions(stalemate: EndType.lose).symmetric(),
      );

  static Variant marseillais({bool balanced = true}) =>
      Variant.standard().copyWith(
        name: 'Marseillais Chess',
        turnEndCondition: TurnEndOr([
          balanced ? TurnEndCondition.marseillais : TurnEndCondition.doubleMove,
          // TurnEndCondition.check,
          // ^ doesn't work yet because checks are calculated after turn conds
        ]),
      );

  static Variant progressive() => Variant.standard().copyWith(
        name: 'Progressive Chess',
        turnEndCondition: TurnEndCondition.progressive,
      );
}
