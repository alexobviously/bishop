part of 'actions.dart';

/// Some common conditions for actions.
class Conditions {
  /// Merges multiple [conditions] into one.
  static ActionCondition merge(List<ActionCondition> conditions) =>
      conditions.length == 1
          ? conditions.first
          : (ActionTrigger trigger) {
              for (final c in conditions) {
                if (!c(trigger)) return false;
              }
              return true;
            };

  /// Inverts the result of a condition.
  static ActionCondition invert(ActionCondition condition) =>
      (ActionTrigger trigger) => !condition(trigger);

  /// Returns true if the move is a capture.
  static ActionCondition get isCapture =>
      (ActionTrigger trigger) => trigger.move.capture;

  /// Returns true if the move is not a capture.
  static ActionCondition get isNotCapture =>
      (ActionTrigger trigger) => !trigger.move.capture;

  /// Returns true if the move is a promotion move.
  static ActionCondition get isPromotion =>
      (ActionTrigger trigger) => trigger.move.promotion;

  /// Returns true if the move is not a promotion move.
  static ActionCondition get isNotPromotion =>
      (ActionTrigger trigger) => !trigger.move.promotion;

  /// Returns true if the moving piece was royal.
  static ActionCondition get movingPieceIsRoyal =>
      (trigger) => trigger.variant.pieces[trigger.piece.type].type.royal;

  /// Returns true if the moving piece is of type [piece].
  static ActionCondition movingPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        if (colour != null && trigger.piece.colour != colour) {
          return false;
        }
        return trigger.variant.pieceIndexLookup[piece] == trigger.piece.type;
      };

  /// Returns true if the captured piece is of type [type].
  /// See `capturedPieceIs` to do this with a string piece type.
  static ActionCondition capturedPieceType(int type, {int? colour}) =>
      (ActionTrigger trigger) {
        if (trigger.move.capturedPiece == null) return false;
        if (colour != null && trigger.move.capturedPiece!.colour != colour) {
          return false;
        }
        return trigger.move.capturedPiece!.type == type;
      };

  /// Returns true if the captured piece is of type [piece].
  static ActionCondition capturedPieceIs(String piece, {int? colour}) =>
      (ActionTrigger trigger) {
        if (trigger.move.capturedPiece == null) return false;
        int sq = trigger.move.capturedPiece!;
        if (colour != null && sq.colour != colour) {
          return false;
        }
        return trigger.variant.pieceIndexLookup[piece] == sq.type;
      };

  /// Returns true if the moving piece is of type [type].
  /// See `movingPieceIs` to do this with a string piece type.
  static ActionCondition movingPieceType(int type, {int? colour}) =>
      (ActionTrigger trigger) {
        if (colour != null && trigger.piece.colour != colour) {
          return false;
        }
        return trigger.piece.type == type;
      };

  /// Returns true if the moving piece has a [flag].
  static ActionCondition movingPieceHasFlag(int flag) =>
      (trigger) => trigger.piece.hasFlag(flag);

  /// Returns true if the captured piece has a [flag]. Returns false if
  static ActionCondition capturedPieceHasFlag(int flag) =>
      (trigger) => trigger.move.capturedPiece?.hasFlag(flag) ?? false;

  /// Returns true if the royal pieces are not facing, or if they are facing
  /// with no pieces between them.
  static ActionCondition get royalsNotFacing => (ActionTrigger trigger) {
        final state = trigger.state;
        final size = trigger.variant.boardSize;
        int whiteSq = state.royalSquares[Bishop.white];
        int blackSq = state.royalSquares[Bishop.black];
        if (!size.squaresOnSameFile(whiteSq, blackSq)) {
          return false;
        }
        int start = min(whiteSq, blackSq);
        int end = max(whiteSq, blackSq);
        for (int i = start + size.north; i < end; i += size.north) {
          if (state.board[i].isNotEmpty) return false;
        }
        return true;
      };

  static ActionCondition playerHasPieceCount({
    required String pieceType,
    required int player,
    int count = 1,
    bool draw = false,
  }) =>
      (ActionTrigger trigger) {
        int piece = trigger.variant.pieceIndexLookup[pieceType]!;
        return trigger.state.pieces[makePiece(piece, player)] >= count;
      };
}

extension ConditionExtension on ActionCondition {
  /// Inverts the result of a condition.
  ActionCondition invert() => (trigger) => !this(trigger);
}
