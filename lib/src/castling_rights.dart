// ignore_for_file: constant_identifier_names

import 'constants.dart';

typedef CastlingRights = int;

extension CastlingExtension on CastlingRights {
  bool get wk => this & Castling.k != 0;
  bool get wq => this & Castling.q != 0;
  bool get bk => this & Castling.bk != 0;
  bool get bq => this & Castling.bq != 0;
  String get formatted =>
      '${this == 0 ? '-' : ''}${wk ? 'K' : ''}${wq ? 'Q' : ''}${bk ? 'k' : ''}${bq ? 'q' : ''}';

  CastlingRights flip(int right) => this ^ right;
  CastlingRights remove(Colour colour) =>
      this & (colour == Bishop.white ? Castling.whiteMask : Castling.blackMask);
  bool hasRight(int right) => this & right != 0;
}

CastlingRights castlingRights(String crString) {
  CastlingRights cr = 0;
  Castling.symbols.forEach((k, v) {
    if (crString.contains(k)) cr += v;
  });
  return cr;
}

class Castling {
  static const int k = 1;
  static const int q = 2;
  static const int black = 4;
  static const int bk = 4;
  static const int bq = 8;
  static const int whiteMask = 12;
  static const int blackMask = 3;
  static const int mask = 15;
  static const int bothK = 5;
  static const int bothQ = 10;
  static const Map<String, int> symbols = {
    'K': k,
    'Q': q,
    'k': bk,
    'q': bq,
  };
}

@Deprecated('Use Castling.k')
const int CASTLING_K = 1;
@Deprecated('Use Castling.q')
const int CASTLING_Q = 2;
@Deprecated('Use Castling.black')
const int CASTLING_BLACK = 4;
@Deprecated('Use Castling.bk')
const int CASTLING_BK = 4;
@Deprecated('Use Castling.bq')
const int CASTLING_BQ = 8;
@Deprecated('Use Castling.whiteMask')
const int CASTLING_WHITE_MASK = 12;
@Deprecated('Use Castling.blackMask')
const int CASTLING_BLACK_MASK = 3;
@Deprecated('Use Castling.mask')
const int CASTLING_MASK = 15;
@Deprecated('Use Castling.bothK')
const int CASTLING_BOTH_K = 5;
@Deprecated('Use Castling.bothQ')
const int CASTLING_BOTH_Q = 10;

@Deprecated('Use Castling.symbols')
const Map<String, int> CASTLING_SYMBOLS = {
  'K': CASTLING_K,
  'Q': CASTLING_Q,
  'k': CASTLING_BK,
  'q': CASTLING_BQ,
};
