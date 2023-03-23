part of '../variant.dart';

/// Variants of chess played on smaller boards.
class SmallVariants {
  static Variant mini() {
    Variant standard = Variant.standard();
    return standard
        .copyWith(
          name: 'Mini Chess',
          boardSize: BoardSize.mini,
          startPosition: 'rbnkbr/pppppp/6/6/PPPPPP/RBNKBR w KQkq - 0 1',
          castlingOptions: CastlingOptions.mini,
          enPassant: false,
          firstMoveOptions: FirstMoveOptions.none(),
        )
        .withPiece('P', PieceType.simplePawn());
  }

  static Variant miniRandom() {
    Variant mini = Variant.mini();
    return mini.copyWith(
      name: 'Mini Random',
      startPosBuilder: RandomChessStartPosBuilder(size: BoardSize.mini),
      castlingOptions: CastlingOptions.miniRandom,
      outputOptions: OutputOptions.chess960,
    );
  }

  static Variant micro() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Micro Chess',
      boardSize: BoardSize(5, 5),
      startPosition: 'rnbqk/ppppp/5/PPPPP/RNBQK w Qq - 0 1',
      castlingOptions: CastlingOptions.micro,
      firstMoveOptions: FirstMoveOptions.ranks(
        [Bishop.rank2],
        [Bishop.rank4],
      ),
    );
  }

  static Variant nano() {
    Variant standard = Variant.standard();
    return standard.copyWith(
      name: 'Nano Chess',
      boardSize: BoardSize(4, 5),
      startPosition: 'knbr/p3/4/3P/RBNK w Qk - 0 1',
      castlingOptions: CastlingOptions.nano,
      firstMoveOptions: FirstMoveOptions.ranks(
        [Bishop.rank2],
        [Bishop.rank4],
      ),
    );
  }
}
