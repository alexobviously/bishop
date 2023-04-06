part of '../variant.dart';

/// Variants where the focus is on novel piece types.
class FairyVariants {
  static Variant hoppelPoppel() => Variant.standard()
      .copyWith(name: 'Hoppel-Poppel')
      .withPieces({'N': PieceType.knibis(), 'B': PieceType.biskni()});

  static Variant grasshopper() =>
      Variant.standard().withPiece('G', PieceType.grasshopper()).copyWith(
            name: 'Grasshopper Chess',
            startPosition:
                'rnbqkbnr/gggggggg/pppppppp/8/8/PPPPPPPP/GGGGGGGG/RNBQKBNR'
                ' w KQkq - 0 1',
            materialConditions: MaterialConditions.none,
          );

  static Variant berolina() => Variant.standard()
      .withPiece('P', PieceType.berolinaPawn())
      .copyWith(name: 'Berolina Chess');

  /// https://en.wikipedia.org/wiki/Wolf_chess
  static Variant wolf() => Variant(
        name: 'Wolf Chess',
        boardSize: BoardSize(8, 10),
        startPosition: 'qwfrbbnk/pssppssp/1pp2pp1/8/8'
            '/8/8/1PP2PP1/PSSPPSSP/KNBBRFWQ w - - 0 1',
        pieceTypes: {
          ...Bishop.chessPieces,
          'W': PieceType.chancellor(), // Wolf
          'F': PieceType.archbishop(), // Fox
          'S': PieceType.fromBetza(
            'fKifmnD',
            enPassantable: true,
            promoOptions:
                PiecePromoOptions.promotesTo(['B', 'N', 'R', 'Q', 'W', 'F']),
          ), // Sergeant
          'N': PieceType.nightrider(),
          'E': PieceType.fromBetza('QN0', value: 1400), // Elephant
        },
        enPassant: true,
      );
}
