class MoveGenParams {
  final bool captures;
  final bool quiet;
  final bool castling;
  final bool legal;
  final bool ignorePieces;
  final int? pieceType;
  final int? onlySquare;
  final bool onlyOne;

  bool get onlyPiece => pieceType != null;

  const MoveGenParams({
    required this.captures,
    required this.quiet,
    required this.castling,
    required this.legal,
    this.ignorePieces = false,
    this.pieceType,
    this.onlySquare,
    this.onlyOne = false,
  });
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
  factory MoveGenParams.pieceCaptures(int pieceType) => MoveGenParams(
        captures: true,
        quiet: false,
        castling: false,
        legal: false,
        pieceType: pieceType,
      );
  factory MoveGenParams.squareAttacks(int square, [bool onlyOne = true]) =>
      MoveGenParams(
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
  String toString() => 'MoveGenOptions($captures, $quiet, $castling, $legal'
      ' $ignorePieces, $pieceType, $onlySquare)';
}
