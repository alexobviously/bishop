import 'constants.dart';

typedef CastlingRights = int;

extension Castling on CastlingRights {
  bool get wk => this & CASTLING_K != 0;
  bool get wq => this & CASTLING_Q != 0;
  bool get bk => this & CASTLING_BK != 0;
  bool get bq => this & CASTLING_BQ != 0;
  String get formatted => '${wk ? 'K' : ''}${wq ? 'Q' : ''}${bk ? 'k' : ''}${bq ? 'q' : ''}';

  CastlingRights flip(int right) => this ^ right;
  CastlingRights remove(Colour colour) => this & (colour == WHITE ? CASTLING_WHITE_MASK : CASTLING_BLACK_MASK);
}

const int CASTLING_K = 1;
const int CASTLING_Q = 2;
const int CASTLING_BLACK = 4;
const int CASTLING_BK = 4;
const int CASTLING_BQ = 8;
const int CASTLING_WHITE_MASK = 12;
const int CASTLING_BLACK_MASK = 3;
const int CASTLING_MASK = 15;
