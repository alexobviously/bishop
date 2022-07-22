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

  const CastlingOptions({
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

  static const none = CastlingOptions(enabled: false);

  factory CastlingOptions.standard([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: Bishop.fileG,
        qTarget: Bishop.fileC,
        fixedRooks: true,
        kRook: Bishop.fileH,
        qRook: Bishop.fileA,
        rookPiece: rookPiece,
      );

  factory CastlingOptions.chess960([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: Bishop.fileG,
        qTarget: Bishop.fileC,
        fixedRooks: false,
        rookPiece: rookPiece,
        useRookAsTarget: true,
      );

  factory CastlingOptions.capablanca([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: Bishop.fileI,
        qTarget: Bishop.fileC,
        fixedRooks: true,
        kRook: Bishop.fileJ,
        qRook: Bishop.fileA,
        rookPiece: rookPiece,
      );

  factory CastlingOptions.mini() => CastlingOptions(
        enabled: true,
        kTarget: Bishop.fileE,
        qTarget: Bishop.fileB,
        fixedRooks: true,
        kRook: Bishop.fileF,
        qRook: Bishop.fileA,
        useRookAsTarget: true,
      );

  factory CastlingOptions.miniRandom([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: Bishop.fileE,
        qTarget: Bishop.fileB,
        fixedRooks: false,
        rookPiece: rookPiece,
        useRookAsTarget: true,
      );

  factory CastlingOptions.micro() => CastlingOptions(
        enabled: true,
        qTarget: Bishop.fileB,
        qRook: Bishop.fileA,
        fixedRooks: true, // might need to be false with diff start fens
      );

  factory CastlingOptions.nano([String rookPiece = 'R']) => CastlingOptions(
        enabled: true,
        kTarget: Bishop.fileC,
        kRook: Bishop.fileD,
        qTarget: Bishop.fileB,
        qRook: Bishop.fileA,
        rookPiece: rookPiece,
        fixedRooks: true,
      );
}
