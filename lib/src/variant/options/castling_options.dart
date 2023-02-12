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

  factory CastlingOptions.fromJson(Map<String, dynamic> json) =>
      CastlingOptions(
        enabled: json['enabled'],
        kTarget: json['kTarget'],
        qTarget: json['qTarget'],
        fixedRooks: json['fixedRooks'] ?? true,
        kRook: json['kRook'],
        qRook: json['qRook'],
        rookPiece: json['rookPiece'],
        useRookAsTarget: json['useRookAsTarget'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (kTarget != null) 'kTarget': kTarget,
        if (qTarget != null) 'qTarget': qTarget,
        if (enabled) 'fixedRooks': fixedRooks,
        if (kRook != null) 'kRook': kRook,
        if (qRook != null) 'qRook': qRook,
        if (rookPiece != null) 'rookPiece': rookPiece,
        if (enabled) 'useRookAsTarget': useRookAsTarget,
      };

  CastlingOptions copyWith({
    bool? enabled,
    int? kTarget,
    int? qTarget,
    bool? fixedRooks,
    int? kRook,
    int? qRook,
    String? rookPiece,
    bool? useRookAsTarget,
  }) =>
      CastlingOptions(
        enabled: enabled ?? this.enabled,
        kTarget: kTarget ?? this.kTarget,
        qTarget: qTarget ?? this.qTarget,
        fixedRooks: fixedRooks ?? this.fixedRooks,
        kRook: kRook ?? this.kRook,
        qRook: qRook ?? this.qRook,
        rookPiece: rookPiece ?? this.rookPiece,
        useRookAsTarget: useRookAsTarget ?? this.useRookAsTarget,
      );

  static const none = CastlingOptions(enabled: false);

  static const standard = CastlingOptions(
    enabled: true,
    kTarget: Bishop.fileG,
    qTarget: Bishop.fileC,
    fixedRooks: true,
    kRook: Bishop.fileH,
    qRook: Bishop.fileA,
    rookPiece: 'R',
  );

  static const chess960 = CastlingOptions(
    enabled: true,
    kTarget: Bishop.fileG,
    qTarget: Bishop.fileC,
    fixedRooks: false,
    rookPiece: 'R',
    useRookAsTarget: true,
  );

  static const capablanca = CastlingOptions(
    enabled: true,
    kTarget: Bishop.fileI,
    qTarget: Bishop.fileC,
    fixedRooks: true,
    kRook: Bishop.fileJ,
    qRook: Bishop.fileA,
    rookPiece: 'R',
  );

  static const mini = CastlingOptions(
    enabled: true,
    kTarget: Bishop.fileE,
    qTarget: Bishop.fileB,
    fixedRooks: true,
    kRook: Bishop.fileF,
    qRook: Bishop.fileA,
    useRookAsTarget: true,
  );

  static const miniRandom = CastlingOptions(
    enabled: true,
    kTarget: Bishop.fileE,
    qTarget: Bishop.fileB,
    fixedRooks: false,
    rookPiece: 'R',
    useRookAsTarget: true,
  );

  static const micro = CastlingOptions(
    enabled: true,
    qTarget: Bishop.fileB,
    qRook: Bishop.fileA,
    fixedRooks: true, // might need to be false with diff start fens
  );

  static const nano = CastlingOptions(
    enabled: true,
    kTarget: Bishop.fileC,
    kRook: Bishop.fileD,
    qTarget: Bishop.fileB,
    qRook: Bishop.fileA,
    rookPiece: 'R',
    fixedRooks: true,
  );
}
