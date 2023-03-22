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
}
