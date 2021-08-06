part of 'variant.dart';

class CastlingOptions {
  final bool enabled;
  final int? kTarget;
  final int? qTarget;
  final bool fixedRooks;
  final int? kRook;
  final int? qRook;
  final String? rookPiece;

  bool get kingside => kTarget != null;
  bool get queenside => qTarget != null;

  CastlingOptions({
    required this.enabled,
    this.kTarget,
    this.qTarget,
    this.fixedRooks = true,
    this.kRook,
    this.qRook,
    this.rookPiece,
  }) {
    if (enabled) assert(kTarget != null || qTarget != null);
    if (fixedRooks == true)
      assert(kRook != null || qRook != null);
    else
      assert(rookPiece != null);
  }

  factory CastlingOptions.none() => CastlingOptions(enabled: false);

  factory CastlingOptions.standard([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: FILE_G,
        qTarget: FILE_C,
        fixedRooks: true,
        kRook: FILE_H,
        qRook: FILE_A,
        rookPiece: rookPiece,
      );

  factory CastlingOptions.chess960([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: FILE_G,
        qTarget: FILE_C,
        fixedRooks: false,
        rookPiece: rookPiece,
      );

  factory CastlingOptions.capablanca([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: FILE_I,
        qTarget: FILE_C,
        fixedRooks: true,
        kRook: FILE_J,
        qRook: FILE_A,
        rookPiece: rookPiece,
      );
}
