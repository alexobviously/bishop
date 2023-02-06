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
      firstMoveRanks: [
        [Bishop.rank3],
        [Bishop.rank8],
      ],
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
      firstMoveRanks: [
        [Bishop.rank3], // white
        [Bishop.rank8], // black
      ],
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
}
