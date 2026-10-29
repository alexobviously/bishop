part of '../variant.dart';

abstract class Musketeer {
  static const String defaultFen =
      '8/rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/8 w KQkq - 0 1';
  static String fen({String whiteGate = '8', String blackGate = '8'}) =>
      '$blackGate/rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/$whiteGate w KQkq - 0 1';
  static PieceType leopard() => .fromBetza('F2N');
  static PieceType hawk() => .fromBetza('ADGH');
  static PieceType unicorn() => .fromBetza('NC');
  static PieceType spider() => .fromBetza('B2ND');
  static PieceType fortress() => .fromBetza('B3vND');
  static PieceType elephant() => .fromBetza('FWDA');
  static PieceType cannon() => .fromBetza('FWDsN');

  static Variant variant() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Musketeer Chess',
      startPosition: defaultFen,
      gatingMode: .fixed,
      pieceTypes: {
        ...standard.pieceTypes,
        'A': .archbishop(),
        'C': .chancellor(),
        'D': .amazon(), // dragon
        'L': leopard(),
        'H': hawk(),
        'U': unicorn(),
        'S': spider(),
        'F': fortress(),
        'E': elephant(),
        'O': cannon(),
      },
    );
  }
}
