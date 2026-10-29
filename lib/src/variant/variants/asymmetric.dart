part of '../variant.dart';

class Orda {
  static PieceType kheshig() => .fromBetza('KN', value: 700);

  static Variant orda() => .standard()
      .copyWith(
        name: 'Orda',
        startPosition: 'lhaykahl/8/pppppppp/8/8/8/PPPPPPPP/RNBQKBNR w KQ - 0 1',
        materialConditions: .none,
        pieceTypes: {
          'K': .king(),
          'P': .pawn(),
          'N': .knight().withNoPromotion(),
          'B': .bishop().withNoPromotion(),
          'R': .rook().withNoPromotion(),
          'Q': .queen(),
          'L': .kniroo().withNoPromotion(), // Lancer
          'H': kheshig(),
          'A': .knibis().withNoPromotion(), // Archer
          'Y': Shogi.silver().withNoPromotion(), // Yurt
        },
        // TODO: set asymmetric castling options when available
        // for now, the fen covers it though
      )
      .withCampMate();

  static Variant ordaMirror() => .standard()
      .copyWith(
        name: 'Orda Mirror',
        startPosition: 'lhafkahl/8/pppppppp/8/8/PPPPPPPP/8/LHAFKAHL w - - 0 1',
        castlingOptions: .none,
        materialConditions: .none,
        pieceTypes: {
          'K': .king(),
          'P': .pawn(),
          'L': .kniroo(), // Lancer
          'H': kheshig(),
          'A': .knibis(), // Archer
          'F': .fromBetza('mQcN', value: 500), // Falcon
        },
      )
      .withCampMate();
}
