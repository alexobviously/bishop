part of 'variant.dart';

class CastlingOptions {
  final bool enabled;
  final int? kTarget;
  final int? qTarget;
  final bool fixedRooks;
  final int? kRook;
  final int? qRook;
  final String? rookPiece;
  final bool useRookAsTarget; // e.g. standard castling is e1h1 instead of e1g1

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
    this.useRookAsTarget = false,
  });
  // these cause problems for some reason, figure it out when you have time
  // {
  //   if (enabled) {
  //     assert(kTarget != null || qTarget != null);
  //     if (fixedRooks)
  //       assert(kRook != null || qRook != null);
  //     else
  //       assert(rookPiece != null);
  //   }
  // }

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
        useRookAsTarget: true,
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

  factory CastlingOptions.mini() => CastlingOptions(
        enabled: true,
        kTarget: FILE_E,
        qTarget: FILE_B,
        fixedRooks: true,
        kRook: FILE_F,
        qRook: FILE_A,
        useRookAsTarget: true,
      );

  factory CastlingOptions.micro() => CastlingOptions(
        enabled: true,
        qTarget: FILE_B,
        qRook: FILE_A,
        fixedRooks: true, // might need to be false with diff start fens
      );

  factory CastlingOptions.nano([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: FILE_C,
        kRook: FILE_D,
        qTarget: FILE_B,
        qRook: FILE_A,
        rookPiece: rookPiece,
        fixedRooks: true,
      );
}
