part of 'variant.dart';

class CastlingOptionSet {
  final List<CastlingOptions> options;
  late bool enabled;

  CastlingOptionSet(this.options) {
    if (options.length == 1) options.add(options.first);
    assert(options.length == 2);
    enabled = options[0].enabled || options[1].enabled;
  }
  factory CastlingOptionSet.symmetrical(CastlingOptions options) => CastlingOptionSet([options, options]);

  factory CastlingOptionSet.none() => CastlingOptionSet.symmetrical(CastlingOptions.none());
  factory CastlingOptionSet.standard() => CastlingOptionSet.symmetrical(CastlingOptions.standard());
  factory CastlingOptionSet.chess960() => CastlingOptionSet.symmetrical(CastlingOptions.chess960());
  factory CastlingOptionSet.capablanca() => CastlingOptionSet.symmetrical(CastlingOptions.capablanca());
  factory CastlingOptionSet.mini() => CastlingOptionSet.symmetrical(CastlingOptions.mini());
  factory CastlingOptionSet.micro() => CastlingOptionSet([CastlingOptions.micro(true), CastlingOptions.micro(false)]);

  CastlingOptions operator [](int index) => options[index];
}

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

  factory CastlingOptions.mini() => CastlingOptions(
        enabled: true,
        qTarget: FILE_B,
        qRook: FILE_A,
        fixedRooks: true, // might need to be false with diff start fens
      );

  factory CastlingOptions.micro(bool white) => CastlingOptions(
        enabled: true,
        kTarget: !white ? FILE_C : null,
        kRook: !white ? FILE_D : null,
        qTarget: white ? FILE_B : null,
        qRook: white ? FILE_A : null,
        fixedRooks: true,
      );
}
