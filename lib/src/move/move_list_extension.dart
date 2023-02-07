import 'package:bishop/bishop.dart';

extension MoveListExtension<T extends Move> on Iterable<T> {
  /// All moves that involve a promotion.
  List<Move> get promoMoves => where((e) => e.promotion).toList();

  /// All moves that involve castling.
  List<Move> get castlingMoves => where((e) => e.castling).toList();

  /// All moves that involve gating.
  List<Move> get gatingMoves => where((e) => e.gate).toList();

  /// All moves that involve a hand drop.
  List<Move> get handDropMoves => where((e) => e.handDrop).toList();

  /// Moves that are a pass. Usually should only be 0 or 1 of these.
  List<PassMove> get passMoves =>
      where((e) => e is PassMove).map((e) => e as PassMove).toList();

  /// All moves from [square].
  List<Move> from(int square) => where((e) => e.from == square).toList();

  /// All moves to [square].
  List<Move> to(int square) => where((e) => e.to == square).toList();

  List<String> toAlgebraic(
    Game g, {
    bool simplifyFixedGating = true,
  }) =>
      map((e) => g.toAlgebraic(e, simplifyFixedGating: simplifyFixedGating))
          .toList();
}

extension NormalMoveListExtenion on Iterable<NormalMove> {
  /// All moves that involve a promotion.
  List<Move> get promoMoves => where((e) => e.promotion).toList();

  /// All moves that involve castling.
  List<Move> get castlingMoves => where((e) => e.castling).toList();

  /// All moves that involve gating.
  List<Move> get gatingMoves => where((e) => e.gate).toList();

  /// All moves that involve a hand drop.
  List<Move> get handDropMoves => where((e) => e.handDrop).toList();
}
