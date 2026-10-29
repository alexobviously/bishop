// ignore_for_file: constant_identifier_names

import 'constants.dart';

/// Bitmask of castling rights.
/// Represents the set of active castling rights at once.
/// Each of the base rights (wk, wq, bk, bq) have a bit, 0 = off, 1 = on.
extension type const CastlingRights(int value) {
  // Individual single-bit rights
  static const CastlingRights none = CastlingRights(0);
  static const CastlingRights wk = CastlingRights(1);
  static const CastlingRights wq = CastlingRights(2);
  static const CastlingRights bk = CastlingRights(4);
  static const CastlingRights bq = CastlingRights(8);

  // Compound masks
  static const CastlingRights whiteMask = CastlingRights(12); // bk | bq
  static const CastlingRights blackMask = CastlingRights(3); // k | q
  static const CastlingRights mask = CastlingRights(15);
  static const CastlingRights all = mask;
  static const CastlingRights bothK = CastlingRights(5); // k | bk
  static const CastlingRights bothQ = CastlingRights(10); // q | bq

  // Lookup table
  static const Map<String, CastlingRights> symbols = {
    'K': wk,
    'Q': wq,
    'k': bk,
    'q': bq,
  };

  // Factory / Parser
  factory CastlingRights.fromString(String crString) {
    CastlingRights cr = .none;
    for (final entry in symbols.entries) {
      if (crString.contains(entry.key)) cr |= entry.value;
    }
    return cr;
  }

  // Bitwise operators
  CastlingRights operator |(CastlingRights other) =>
      CastlingRights(value | other.value);
  CastlingRights operator &(CastlingRights other) =>
      CastlingRights(value & other.value);
  CastlingRights operator ^(CastlingRights other) =>
      CastlingRights(value ^ other.value);
  CastlingRights operator ~() => CastlingRights(~value & mask.value);

  /// Whether [right] is enabled in this set of rights.
  bool has(CastlingRights right) => (value & right.value) != 0;

  CastlingRights flip(CastlingRights right) => this ^ right;
  CastlingRights remove(Colour colour) =>
      this & (colour == Bishop.white ? whiteMask : blackMask);
  String get formatted => [
    if (this == .none) '-',
    if (has(wk)) 'K',
    if (has(wq)) 'Q',
    if (has(bk)) 'k',
    if (has(bq)) 'q',
  ].join('');
}

enum CastlingDirection { kingside, queenside }
