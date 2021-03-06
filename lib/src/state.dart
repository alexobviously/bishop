import 'castling_rights.dart';
import 'constants.dart';
import 'move.dart';

/// A record of the game's state at a particular move.
/// Doesn't include the board state.
class State {
  /// The previous move that was played. If null, the game has just started.
  final Move? move;

  /// The player who can make the next move.
  final Colour turn;

  /// How many half moves have been played since the last capture or pawn move.
  final int halfMoves;

  /// How many full moves have been played in the entire game.
  final int fullMoves;

  /// The current castling rights of both players.
  final CastlingRights castlingRights;

  /// The en passant square, if one is available.
  final int? epSquare;

  /// The squares the kings (or equivalent) currently reside on.
  /// Index 0 - white, index 1 - black.
  final List<int> royalSquares;

  /// A list of files that have been untouched for each player.
  /// For use with e.g. Seirawan chess, where pieces can only be gated on files
  /// that haven't had their pieces move yet.
  /// Only works for variants where all non-pawn pieces start on the back rank.
  final List<List<int>> virginFiles;

  /// Two lists of pieces, for each player's hand.
  /// Index 0 - white, index 1 - black.
  final List<Hand>? hands;

  /// Two lists of pieces, for each player's gate.
  /// Index 0 - white, index 1 - black.
  final List<Hand>? gates;

  /// A list of pieces each player has.
  final List<int> pieces;

  /// The number of times each player has been checked.
  /// For use with variants such as three-check.
  final List<int> checks;

  /// The Zobrist hash of the game state.
  /// Needs to be set after construction of the first hash, but otherwise is
  /// updated in `Game.makeMove()`.
  int hash;

  @override
  String toString() => 'State(turn: $turn, moves: $fullMoves, hash: $hash)';

  State({
    this.move,
    required this.turn,
    required this.halfMoves,
    required this.fullMoves,
    required this.castlingRights,
    this.epSquare,
    required this.royalSquares,
    required this.virginFiles,
    this.hands,
    this.gates,
    required this.pieces,
    this.checks = const [0, 0],
    this.hash = 0,
  });

  State copyWith({
    Move? move,
    Colour? turn,
    int? halfMoves,
    int? fullMoves,
    CastlingRights? castlingRights,
    int? epSquare,
    List<int>? royalSquares,
    List<List<int>>? virginFiles,
    List<Hand>? hands,
    List<Hand>? gates,
    List<int>? pieces,
    List<int>? checks,
    int? hash,
  }) =>
      State(
        move: move ?? this.move,
        turn: turn ?? this.turn,
        halfMoves: halfMoves ?? this.halfMoves,
        fullMoves: fullMoves ?? this.fullMoves,
        castlingRights: castlingRights ?? this.castlingRights,
        epSquare: epSquare ?? this.epSquare,
        royalSquares: royalSquares ?? this.royalSquares,
        virginFiles: virginFiles ?? this.virginFiles,
        hands: hands ?? this.hands,
        gates: gates ?? this.gates,
        pieces: pieces ?? this.pieces,
        checks: checks ?? this.checks,
        hash: hash ?? this.hash,
      );
}
