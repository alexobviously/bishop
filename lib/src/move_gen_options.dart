class MoveGenOptions {
  final bool captures;
  final bool quiet;
  final bool castling;
  final bool legal;
  final bool ignorePieces;
  final int? pieceType;
  final int? onlySquare;

  bool get onlyPiece => pieceType != null;

  const MoveGenOptions({
    required this.captures,
    required this.quiet,
    required this.castling,
    required this.legal,
    this.ignorePieces = false,
    this.pieceType,
    this.onlySquare,
  });
  static const normal = MoveGenOptions(
    captures: true,
    quiet: true,
    castling: true,
    legal: true,
  );
  static const onlyQuiet = MoveGenOptions(
    captures: false,
    quiet: true,
    castling: true,
    legal: true,
  );
  static const onlyCaptures = MoveGenOptions(
    captures: true,
    quiet: false,
    castling: false,
    legal: true,
  );
  static const attacks = MoveGenOptions(
    captures: true,
    quiet: false,
    castling: false,
    legal: false,
  );
  factory MoveGenOptions.pieceCaptures(int pieceType) => MoveGenOptions(
        captures: true,
        quiet: false,
        castling: false,
        legal: false,
        pieceType: pieceType,
      );
  factory MoveGenOptions.squareAttacks(int square) => MoveGenOptions(
        captures: true,
        quiet: false,
        castling: false,
        legal: false,
        onlySquare: square,
      );
  static const premoves = MoveGenOptions(
    captures: true,
    quiet: true,
    castling: true,
    legal: false,
    ignorePieces: true,
  );
}
