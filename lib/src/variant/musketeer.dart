part of 'variant.dart';

class Musketeer {
  static const String defaultFen =
      '8/rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/8 w KQkq - 0 1';
  static PieceType leopard() => PieceType.fromBetza('F2N');
  static PieceType hawk() => PieceType.fromBetza('ADGH');
  static PieceType unicorn() => PieceType.fromBetza('NC');
  static PieceType spider() => PieceType.fromBetza('B2ND');
  static PieceType fortress() => PieceType.fromBetza('B3vND');
  static PieceType elephant() => PieceType.fromBetza('FWDA');
  static PieceType cannon() => PieceType.fromBetza('FWDsN');

  static Variant variant() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Musketeer Chess',
      startPosition: defaultFen,
      gatingMode: GatingMode.fixed,
      pieceTypes: standard.pieceTypes
        ..addAll(
          {
            'A': PieceType.archbishop(),
            'C': PieceType.chancellor(),
            'D': PieceType.amazon(), // dragon
            'L': leopard(),
            'H': hawk(),
            'U': unicorn(),
            'S': spider(),
            'F': fortress(),
            'E': elephant(),
            'O': cannon(),
          },
        ),
    );
  }
}
