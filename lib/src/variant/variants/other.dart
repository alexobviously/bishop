part of '../variant.dart';

/// Games that don't really resemble Chess or any of the other main variants.
abstract class OtherGames {
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
        promotionOptions: PromotionOptions.none,
        actions: [
          ActionExitRegionEnding(
            region: RectRegion.square(Bishop.fileE, Bishop.rank5),
          ),
        ],
        halfMoveDraw: 100,
      );

  /// https://en.wikipedia.org/wiki/Clobber
  static Variant clobber() => Variant(
        name: 'Clobber',
        startPosition: 'PpPpP/pPpPp/PpPpP/pPpPp/PpPpP/pPpPp w - - 0 1',
        boardSize: BoardSize(5, 6),
        pieceTypes: {'P': PieceType.fromBetza('cW')},
        gameEndConditions:
            GameEndConditions(stalemate: EndType.lose).symmetric(),
        promotionOptions: PromotionOptions.none,
      );

  /// https://en.wikipedia.org/wiki/Clobber#Variants
  static Variant clobber10() => clobber().copyWith(
        name: 'Clobber10',
        boardSize: BoardSize(10, 10),
        startPosition: 'PpPpPpPpPp/pPpPpPpPpP/PpPpPpPpPp/pPpPpPpPpP/PpPpPpPpPp/'
            'pPpPpPpPpP/PpPpPpPpPp/pPpPpPpPpP'
            '/PpPpPpPpPp/pPpPpPpPpP w - - 0 1',
      );

  /// https://en.wikipedia.org/wiki/Breakthrough_(board_game)
  static Variant breakthrough() => Variant(
        name: 'Breakthrough',
        startPosition: 'pppppppp/pppppppp/8/8/8/8/PPPPPPPP/PPPPPPPP w - - 0 1',
        pieceTypes: {'P': PieceType.fromBetza('fmWfF')},
      ).withCampMate(winPieces: ['P']);

  /// https://en.wikipedia.org/wiki/Five_Field_Kono
  static Variant kono() => Variant(
        name: 'Five Field Kono',
        boardSize: BoardSize(5, 5),
        startPosition: 'ppppp/p3p/5/P3P/PPPPP w - - 0 1',
        // startPosition: 'PPPPP/4P/1P3/5/4p w - - 0 1',
        pieceTypes: {'P': PieceType.fromBetza('mF')},
        regions: {
          'w': SetRegion(['a5', 'b5', 'c5', 'd5', 'e5', 'a4', 'e4']),
          'b': SetRegion(['a1', 'b1', 'c1', 'd1', 'e1', 'a2', 'e2']),
        },
        promotionOptions: PromotionOptions.none,
      ).withAction(ActionFillRegionEnding('w', 'b'));

  /// https://www.chessvariants.com/programs.dir/joust.html
  static Variant joust() => Variant(
        name: 'Joust',
        description: 'The square a piece moves from is removed from the board'
            'after each move.',
        startPosition: '8/8/8/4n3/3N4/8/8/8 w - - 0 1',
        pieceTypes: {'N': PieceType.fromBetza('mN')},
        gameEndConditions:
            GameEndConditions(stalemate: EndType.lose).symmetric(),
        promotionOptions: PromotionOptions.none,
      ).withBlocker().withAction(ActionBlockOrigin());
}
