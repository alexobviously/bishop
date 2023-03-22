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
typedef PromotionBuilder = List<StandardMove>? Function(PromotionParams params);

class PromotionParams {
  final StandardMove move;
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
    bool optional = false,
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

        List<StandardMove> moves = [];
        for (int p in params.promoPieces) {
          StandardMove m = params.move.copyWith(
            promoSource: params.state.board[params.move.from].type,
            promoPiece: p,
          );
          moves.add(m);
        }
        if (optional) moves.add(params.move);
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

        List<StandardMove> moves = [];
        for (int p in params.promoPieces) {
          StandardMove m = params.move.copyWith(
            promoSource: params.state.board[params.move.from].type,
            promoPiece: p,
          );
          moves.add(m);
        }
        if (!forcedPromo) moves.add(params.move);
        return moves;
      };

  static PromotionBuilder pair(
    PromotionBuilder white,
    PromotionBuilder black,
  ) =>
      (params) {
        int piece = params.state.board[params.move.from];
        if (piece.isEmpty) return null;
        return piece.colour == Bishop.white ? white(params) : black(params);
      };

  /// Promotes only within [region].
  static PromotionBuilder region(Region region, {bool optional = false}) =>
      (params) {
        if (!params.pieceType.promoOptions.canPromote) return null;

        Square piece = params.state.board[params.move.from];
        if (piece.isEmpty) return null;
        if (!params.variant.boardSize.inRegion(params.move.to, region)) {
          return null;
        }

        return [
          ...params.promoPieces.map(
            (e) => params.move.copyWith(
              promoSource: params.state.board[params.move.from].type,
              promoPiece: e,
            ),
          ),
          if (optional) params.move,
        ];
      };

  /// A promotion builder pair for region promotion, where white and black
  /// have different regions.
  static PromotionBuilder regions(
    Region? whiteRegion,
    Region? blackRegion, {
    bool optional = false,
  }) =>
      pair(
        whiteRegion == null ? none() : region(whiteRegion, optional: optional),
        blackRegion == null ? none() : region(blackRegion, optional: optional),
      );

  static PromotionBuilder none() => (_) => null;
}
