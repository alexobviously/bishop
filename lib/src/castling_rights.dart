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
