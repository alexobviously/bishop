part of '../variant.dart';

/// Variants of chess played on larger boards.
abstract class LargeVariants {
  static Variant capablanca() {
    final standard = Variant.standard();
    return standard.copyWith(
      name: 'Capablanca Chess',
      boardSize: const BoardSize(10, 8),
      startPosition: 'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP'
          '/RNABQKBCNR w KQkq - 0 1',
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
      boardSize: const BoardSize(10, 10),
      startPosition: 'r8r/1nbqkcabn1/pppppppppp/10/10/10/10/PPPPPPPPPP'
          '/1NBQKCABN1/R8R w - - 0 1',
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

  /// A variant of Grand Chess with two extra pieces.
  /// https://www.chessvariants.com/rules/opulent-chess
  static Variant opulent() => grand().withPieces({
        'N': PieceType.fromBetza('NW', value: 400),
        'W': PieceType.fromBetza('FC', value: 400), // Wizard
        'L': PieceType.fromBetza('HFD', value: 400), // Lion
      }).copyWith(
        name: 'Opulent Chess',
        startPosition: 'rw6wr/clbnqknbla/pppppppppp/10/10/10/10'
            '/PPPPPPPPPP/CLBNQKNBLA/RW6WR w - - 0 1',
        promotionOptions: PromotionOptions.optional(
          ranks: [Bishop.rank8, Bishop.rank3],
          pieceLimits: {
            'Q': 1, 'A': 1, 'C': 1,
            'R': 2, 'N': 2, 'B': 2,
            'W': 2, 'L': 2, //
          },
        ),
      );

  static Variant shako() {
    final standard = Variant.standard();
    return standard.copyWith(
      name: 'Shako',
      boardSize: const BoardSize(10, 10),
      startPosition: 'c8c/ernbqkbnre/pppppppppp/10/10/10/10/PPPPPPPPPP'
          '/ERNBQKBNRE/C8C w KQkq - 0 1',
      pieceTypes: {
        ...standard.pieceTypes,
        'E': PieceType.fromBetza('FA'),
        'C': Xiangqi.cannon(),
      },
      castlingOptions: const CastlingOptions(
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
        boardSize: const BoardSize(10, 10),
        startPosition: '2cwamwc2/1rnbqkbnr1/pppppppppp/10/10/10/10'
            '/PPPPPPPPPP/1RNBQKBNR1/2CWAMWC2 w - - 0 1',
        pieceTypes: {
          ...Bishop.chessPieces,
          'A': PieceType.archbishop(),
          'M': PieceType.chancellor(), // Marshall
          'C': PieceType.fromBetza('DAW', value: 400), // Champion
          'W': PieceType.fromBetza('CF', value: 400), // Wizard
        },
      );
}
