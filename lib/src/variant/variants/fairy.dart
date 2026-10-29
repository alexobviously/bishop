part of '../variant.dart';

/// Variants where the focus is on novel piece types.
class FairyVariants {
  /// Knights capture like bishops, bishops capture like knights.
  static Variant hoppelPoppel() => .standard()
      .withPieces({
        'N': .knibis(),
        'B': .biskni(),
      })
      .copyWith(
        name: 'Hoppel-Poppel',
        materialConditions: .none,
      );

  /// Rooks capture like knights, knights capture like rooks.
  static Variant newZealand() => .standard()
      .withPieces({
        'R': .rookni(),
        'N': .kniroo(),
      })
      .copyWith(
        name: 'New Zealand Chess',
        materialConditions: .none,
      );

  /// https://en.wikipedia.org/wiki/Grasshopper_chess
  static Variant grasshopper() => Variant.standard()
      .withPiece('G', .grasshopper())
      .copyWith(
        name: 'Grasshopper Chess',
        startPosition:
            'rnbqkbnr/gggggggg/pppppppp/8/8/PPPPPPPP/GGGGGGGG/RNBQKBNR'
            ' w KQkq - 0 1',
        materialConditions: .none,
      );

  /// Knights are replaced with nightriders.
  static Variant nightrider() => .standard()
      .copyWith(
        name: 'Nightrider Chess',
        materialConditions: .none,
      )
      .withPiece('N', .nightrider());

  /// https://en.wikipedia.org/wiki/Berolina_pawn#Berolina_chess
  static Variant berolina() => .standard()
      .withPiece('P', .berolinaPawn())
      .copyWith(name: 'Berolina Chess');

  /// https://en.wikipedia.org/wiki/Wolf_chess
  static Variant wolf() => Variant(
    name: 'Wolf Chess',
    boardSize: const BoardSize(8, 10),
    startPosition:
        'qwfrbbnk/pssppssp/1pp2pp1/8/8'
        '/8/8/1PP2PP1/PSSPPSSP/KNBBRFWQ w - - 0 1',
    pieceTypes: {
      ...Bishop.chessPieces,
      'W': .chancellor(), // Wolf
      'F': .archbishop(), // Fox
      'S': .fromBetza(
        'fKifmnD',
        enPassantable: true,
        promoOptions: .promotesTo(['B', 'N', 'R', 'Q', 'W', 'F']),
      ), // Sergeant
      'N': .nightrider(),
      'E': .fromBetza('QN0', value: 1400), // Elephant
    },
    enPassant: true,
  );
}
