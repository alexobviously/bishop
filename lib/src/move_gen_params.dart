class const MoveGenParams({
  required final bool captures,
  required final bool quiet,
  required final bool castling,
  required final bool legal,
  final bool ignorePieces = false,
  final int? pieceType,
  final int? onlySquare,
  final bool onlyOne = false,
}) {
  bool get onlyPiece => pieceType != null;
  static const normal = MoveGenParams(
    captures: true,
    quiet: true,
    castling: true,
    legal: true,
  );
  static const onlyQuiet = MoveGenParams(
    captures: false,
    quiet: true,
    castling: true,
    legal: true,
  );
  static const onlyCaptures = MoveGenParams(
    captures: true,
    quiet: false,
    castling: false,
    legal: true,
  );
  static const attacks = MoveGenParams(
    captures: true,
    quiet: false,
    castling: false,
    legal: false,
  );
  factory pieceCaptures(int pieceType) => MoveGenParams(
    captures: true,
    quiet: false,
    castling: false,
    legal: false,
    pieceType: pieceType,
  );
  factory squareAttacks(int square, [bool onlyOne = true]) => MoveGenParams(
    captures: true,
    quiet: false,
    castling: false,
    legal: false,
    onlySquare: square,
    onlyOne: onlyOne,
  );
  static const premoves = MoveGenParams(
    captures: true,
    quiet: true,
    castling: true,
    legal: false,
    ignorePieces: true,
  );

  @override
  String toString() =>
      'MoveGenParams($captures, $quiet, $castling, $legal'
      ' $ignorePieces, $pieceType, $onlySquare)';
}
