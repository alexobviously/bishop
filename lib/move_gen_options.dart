class MoveGenOptions {
  final bool captures;
  final bool quiet;
  final bool castling;
  final bool legal;
  final int? pieceType;

  bool get onlyPiece => pieceType != null;

  const MoveGenOptions({
    required this.captures,
    required this.quiet,
    required this.castling,
    required this.legal,
    this.pieceType,
  });
  factory MoveGenOptions.normal() => MoveGenOptions(
        captures: true,
        quiet: true,
        castling: true,
        legal: true,
      );
  factory MoveGenOptions.onlyQuiet() => MoveGenOptions(
        captures: false,
        quiet: true,
        castling: true,
        legal: true,
      );
  factory MoveGenOptions.onlyCaptures() => MoveGenOptions(
        captures: true,
        quiet: false,
        castling: false,
        legal: true,
      );
  factory MoveGenOptions.pieceCaptures(int pieceType) => MoveGenOptions(
        captures: true,
        quiet: false,
        castling: false,
        legal: false,
        pieceType: pieceType,
      );
}
