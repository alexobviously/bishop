part of '../variant.dart';

/// Variants of chess played on larger boards.
class LargeVariants {
  static Variant capablanca() {
    final standard = Variant.standard();
    return standard.copyWith(
      name: 'Capablanca Chess',
      boardSize: BoardSize(10, 8),
      startPosition:
          'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1',
      castlingOptions: CastlingOptions.capablanca,
      pieceTypes: {
        ...standard.pieceTypes,
        'A': PieceType.archbishop(),
        'C': PieceType.chancellor(),
      },
    );
  }

  static Variant grand() {
    final standard = Variant.standard();
    return standard.copyWith(
      name: 'Grand Chess',
      boardSize: BoardSize(10, 10),
      startPosition:
          'r8r/1nbqkcabn1/pppppppppp/10/10/10/10/PPPPPPPPPP/1NBQKCABN1/R8R w - - 0 1',
      castlingOptions: CastlingOptions.none,
      promotionOptions: PromotionOptions.optional(
        ranks: [Bishop.rank8, Bishop.rank3],
        pieceLimits: {
          'Q': 1, 'A': 1, 'C': 1, //
          'R': 2, 'N': 2, 'B': 2, //
        },
      ),
      pieceTypes: {
        ...standard.pieceTypes,
        'C': PieceType.chancellor(), // marshal
        'A': PieceType.archbishop(), // cardinal
      },
    );
  }

  static Variant shako() {
    final standard = Variant.standard();
    return standard.copyWith(
      name: 'Shako',
      boardSize: BoardSize(10, 10),
      startPosition:
          'c8c/ernbqkbnre/pppppppppp/10/10/10/10/PPPPPPPPPP/ERNBQKBNRE/C8C w KQkq - 0 1',
      pieceTypes: {
        ...standard.pieceTypes,
        'E': PieceType.fromBetza('FA'),
        'C': Xiangqi.cannon(),
      },
      castlingOptions: CastlingOptions(
        enabled: true,
        kTarget: Bishop.fileH,
        qTarget: Bishop.fileD,
        fixedRooks: true,
        kRook: Bishop.fileI,
        qRook: Bishop.fileB,
        rookPiece: 'R',
      ),
    );
  }

  /// https://www.chessvariants.com/contests/10/tencubedchess.html
  static Variant tenCubed() => Variant(
        name: 'TenCubed',
        boardSize: BoardSize(10, 10),
        startPosition: '2cwamwc2/1rnbqkbnr1/pppppppppp/10/10/10/10/'
            'PPPPPPPPPP/1RNBQKBNR1/2CWAMWC2 w - - 0 1',
        pieceTypes: {
          ...Bishop.chessPieces,
          'A': PieceType.archbishop(),
          'M': PieceType.chancellor(), // Marshall
          'C': PieceType.fromBetza('DAW'), // Champion
          'W': PieceType.fromBetza('CF') // Wizard
        },
      );

  /// Not fully working yet - en passant is broken in most cases.
  static Variant omega() => Variant(
        name: 'Omega Chess',
        boardSize: BoardSize(12, 12),
        startPosition: 'w**********w/*crnbqkbnrc*/*pppppppppp*/*10*/*10*/*10*/'
            '*10*/*10*/*10*/*PPPPPPPPPP*/*CRNBQKBNRC*/W**********W w - - 0 1',
        pieceTypes: {
          ...Bishop.chessPieces,
          'P': PieceType.longMovePawn(3),
          'C': PieceType.fromBetza('DAW'), // Champion
          'W': PieceType.fromBetza('FC'), // Wizard
        },
        enPassant: true,
        castlingOptions: CastlingOptions(
          enabled: true,
          kTarget: Bishop.fileI,
          qTarget: Bishop.fileE,
          kRook: Bishop.fileJ,
          qRook: Bishop.fileC,
        ),
      ).withBlocker();
}
