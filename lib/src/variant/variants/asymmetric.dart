part of '../variant.dart';

class Orda {
  static PieceType kheshig() => PieceType.fromBetza('KN', value: 700);
  static Variant orda() => Variant.standard().copyWith(
        name: 'Orda',
        startPosition: 'lhaykahl/8/pppppppp/8/8/8/PPPPPPPP/RNBQKBNR w KQ - 0 1',
        materialConditions: MaterialConditions.none,
        pieceTypes: {
          'K': PieceType.king(),
          'P': PieceType.pawn(),
          'N': PieceType.knight().withNoPromotion(),
          'B': PieceType.bishop().withNoPromotion(),
          'R': PieceType.rook().withNoPromotion(),
          'Q': PieceType.queen(),
          'L': PieceType.kniroo().withNoPromotion(), // Lancer
          'H': kheshig(),
          'A': PieceType.knibis().withNoPromotion(), // Archer
          'Y': Shogi.silver().withNoPromotion(), // Yurt
        },
        // TODO: set asymmetric castling options when available
        // for now, the fen covers it though
      ).withCampMate();

  static Variant ordaMirror() => Variant.standard().copyWith(
        name: 'Orda Mirror',
        startPosition: 'lhafkahl/8/pppppppp/8/8/PPPPPPPP/8/LHAFKAHL w - - 0 1',
        castlingOptions: CastlingOptions.none,
        materialConditions: MaterialConditions.none,
        pieceTypes: {
          'K': PieceType.king(),
          'P': PieceType.pawn(),
          'L': PieceType.kniroo(), // Lancer
          'H': kheshig(),
          'A': PieceType.knibis(), // Archer
          'F': PieceType.fromBetza('mQcN', value: 500), // Falcon
        },
      ).withCampMate();
}
