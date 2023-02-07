import 'package:bishop/bishop.dart';

/// Defines whether a piece can promote or be promoted to.
class PiecePromoOptions {
  /// Whether this piece can be promoted.
  final bool canPromote;

  /// Whether this piece can be promoted to.
  final bool canPromoteTo;

  /// If this is specified then only pieces in this list will be available as
  /// promotion options for this piece.
  final List<String>? promotesTo;

  const PiecePromoOptions({
    this.canPromote = false,
    this.canPromoteTo = false,
    this.promotesTo,
  });

  factory PiecePromoOptions.fromJson(Map<String, dynamic> json) =>
      PiecePromoOptions(
        canPromote: json['canPromote'] ?? false,
        canPromoteTo: json['canPromoteTo'] ?? false,
        promotesTo: json['promotesTo']?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'canPromote': canPromote,
        'canPromoteTo': canPromoteTo,
        if (promotesTo != null) 'promotesTo': promotesTo,
      };

  /// A piece that cannot be promoted and isn't a promotion option.
  static const none = PiecePromoOptions(canPromote: false, canPromoteTo: false);

  /// A piece that is a promotion option (but cannot be promoted).
  static const promoPiece = PiecePromoOptions(canPromoteTo: true);

  /// A piece that can be promoted (but isn't a promotion option).
  static const promotable = PiecePromoOptions(canPromote: true);

  /// A piece that can be promoted, but its only options are [pieces].
  factory PiecePromoOptions.promotesTo(List<String> pieces) =>
      PiecePromoOptions(
        canPromote: true,
        promotesTo: pieces,
      );

  /// A piece that can be promoted, but only to [piece].
  factory PiecePromoOptions.promotesToOne(String piece) =>
      PiecePromoOptions.promotesTo([piece]);

  @override
  int get hashCode =>
      canPromote.hashCode ^
      canPromoteTo.hashCode << 1 ^
      (promotesTo?.join('').hashCode ?? 0) << 2;

  @override
  bool operator ==(Object other) =>
      other is PiecePromoOptions && hashCode == other.hashCode;
}

typedef PromotionSetup = PromotionBuilder Function(BuiltVariant variant);
typedef PromotionBuilder = List<NormalMove>? Function(PromotionParams params);

class PromotionParams {
  final NormalMove move;
  final BishopState state;
  final BuiltVariant variant;
  final PieceType pieceType;
  final List<int> promoPieces;

  const PromotionParams({
    required this.move,
    required this.state,
    required this.variant,
    required this.pieceType,
    required this.promoPieces,
  });
}

class Promotion {
  /// Generates a move for each piece in [variant.promotionPieces] for the [move] move.
  static PromotionBuilder standard({
    required List<int> ranks,
    bool includeBaseMove = false,
  }) =>
      (PromotionParams params) {
        if (!params.pieceType.promoOptions.canPromote) return null;

        Square piece = params.state.board[params.move.from];
        if (piece.isEmpty) return null;
        Colour colour = piece.colour;

        int toRank = params.variant.boardSize.rank(params.move.to);
        bool promo = colour == Bishop.white
            ? toRank >= ranks[Bishop.white]
            : toRank <= ranks[Bishop.black];

        if (!promo) return null;

        List<NormalMove> moves = [];
        for (int p in params.promoPieces) {
          NormalMove m = params.move.copyWith(
            promoSource: params.state.board[params.move.from].type,
            promoPiece: p,
          );
          moves.add(m);
        }
        if (includeBaseMove) moves.add(params.move);
        return moves;
      };

  static PromotionBuilder optional({
    required List<int> ranks,
    List<int>? forcedRanks,
  }) =>
      (PromotionParams params) {
        if (!params.pieceType.promoOptions.canPromote) return null;

        Square piece = params.state.board[params.move.from];
        if (piece.isEmpty) return null;
        Colour colour = piece.colour;

        int toRank = params.variant.boardSize.rank(params.move.to);
        bool optPromo = colour == Bishop.white
            ? toRank >= ranks[Bishop.white]
            : toRank <= ranks[Bishop.black];
        if (!optPromo) return null;

        bool forcedPromo = false;
        if (forcedRanks != null) {
          forcedPromo = colour == Bishop.white
              ? toRank >= forcedRanks[Bishop.white]
              : toRank <= forcedRanks[Bishop.black];
        }

        List<NormalMove> moves = [];
        for (int p in params.promoPieces) {
          NormalMove m = params.move.copyWith(
            promoSource: params.state.board[params.move.from].type,
            promoPiece: p,
          );
          moves.add(m);
        }
        if (!forcedPromo) moves.add(params.move);
        return moves;
      };
}
