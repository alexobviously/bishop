part of 'variant.dart';

class Xiangqi {
  static const String defaultFen =
      'rheakaehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAKAEHR w - - 0 1';
  static PieceType general() =>
      PieceType.fromBetza('W', royal: true, canPromoteTo: false);
  static PieceType advisor() => PieceType.fromBetza('F');
  static PieceType elephant() => PieceType.fromBetza('nA');
  static PieceType horse() => PieceType.fromBetza('nN');
  static PieceType chariot() => PieceType.fromBetza('R');
  static PieceType cannon() => PieceType.fromBetza('mRcpR');
  // TODO: implement 'promotion' on crossing river - fsW
  static PieceType soldier() => PieceType.fromBetza('fW');

  static Variant variant() => Variant(
        name: 'Xiangqi',
        boardSize: BoardSize.xiangqi,
        pieceTypes: {
          'K': general(),
          'A': advisor(),
          'E': elephant(),
          'H': horse(),
          'R': chariot(),
          'C': cannon(),
          'P': soldier(),
        },
        castlingOptions: CastlingOptions.none,
        startPosition: defaultFen,
        flyingGenerals: true,
      );
}
