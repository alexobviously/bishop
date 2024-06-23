part of '../variant.dart';

/// Variants that have an unusual board shape.
abstract class ShapeVariants {
  /// Variant with a circular shaped board.
  static Variant troitzky() => Variant(
        name: 'Troitzky Chess',
        boardSize: const BoardSize(10, 10),
        startPosition: '****qk****/**rnbbnr**/*pppppppp*/*8*/10'
            '/10/*8*/*PPPPPPPP*/**RNBBNR**/****QK**** w - - 0 1',
        pieceTypes: Bishop.chessPieces,
        promotionOptions: const RegionPromotion(whiteId: 'wp', blackId: 'bp'),
        regions: {
          'wp': SetRegion(
            ['a6', 'b8', 'c9', 'd9', 'e10', 'f10', 'g9', 'h9', 'i8', 'j6'],
          ),
          'bp': SetRegion(
            ['a5', 'b3', 'c2', 'd2', 'e1', 'f1', 'g2', 'h2', 'i3', 'j5'],
          ),
        },
        enPassant: true,
      ).withBlocker();

  /// Not fully working yet - en passant is broken in most cases.
  static Variant omega() => Variant(
        name: 'Omega Chess',
        boardSize: const BoardSize(12, 12),
        startPosition: 'w**********w/*crnbqkbnrc*/*pppppppppp*/*10*/*10*/*10*'
            '/*10*/*10*/*10*/*PPPPPPPPPP*/*CRNBQKBNRC*/W**********W w - - 0 1',
        pieceTypes: {
          ...Bishop.chessPieces,
          'P': PieceType.longMovePawn(3),
          'C': PieceType.fromBetza('DAW', value: 400), // Champion
          'W': PieceType.fromBetza('FC', value: 400), // Wizard
        },
        enPassant: true,
        castlingOptions: const CastlingOptions(
          enabled: true,
          kTarget: Bishop.fileI,
          qTarget: Bishop.fileE,
          kRook: Bishop.fileJ,
          qRook: Bishop.fileC,
        ),
      ).withBlocker();
}
