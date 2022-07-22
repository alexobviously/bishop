const int standard = 0;
const int chess960 = 1;

class Positions {
  static const String standardDefault = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  static const String kiwiPete =
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
  static const String ep = 'rnbqkbnr/pp1pppp1/7p/2pP4/8/8/PPP1PPPP/RNBQKBNR w KQkq c6 0 3';
  static const String rookPin = '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1';
  static const String position4 =
      'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1';
  static const String position5 = 'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8';
  static const String position6 =
      'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10';
  static const String standardMicro = 'rnbqk/ppppp/5/PPPPP/RNBQK w Qq - 0 1';
  static const String standardNano = 'knbr/p3/4/3P/RBNK w Qk - 0 1';
  static const String standardMini = 'rbnkbr/pppppp/6/6/PPPPPP/RBNKBR w KQkq - 0 1';
}
