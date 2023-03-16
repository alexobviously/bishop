import 'package:bishop/bishop.dart';

/// A record of the game's state at a particular move.
class BishopState {
  /// The contents of each square on the board.
  final List<int> board;

  /// The previous move that was played. If null, the game has just started.
  final Move? move;

  /// Contains the string representations of [move], and the variant.
  /// Since these can be expensive to calculate, this will only be present in
  /// mainline moves, i.e. moves actually made by a player, rather than ones
  /// being generated for move legalisation.
  final StateMeta? meta;

  /// The player who can make the next move.
  final Colour turn;

  /// How many half moves have been played since the last capture or pawn move.
  final int halfMoves;

  // todo: refactor so we store number of half moves instead
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

  /// This should be null most of the time. Used to indicate special case
  /// win conditions that have been met by a preceding move.
  final GameResult? result;

  /// The Zobrist hash of the game state.
  /// Needs to be set after construction of the first hash, but otherwise is
  /// updated in `Game.makeMove()`.
  final int hash;

  int get moveNumber => fullMoves - (turn == Bishop.white ? 1 : 0);
  bool get invalidMove => result is InvalidMoveResult;

  /// The total number of pieces currently in play belonging to [player].
  int pieceCount(int player) {
    // super ugly but efficient
    int count = 0;
    for (int i = player; i < pieces.length; i += 2) {
      count += pieces[i];
    }
    return count;
  }

  int get whitePieceCount => pieceCount(Bishop.white);
  int get blackPieceCount => pieceCount(Bishop.black);
  Set<int> handPieceTypes(int colour) =>
      hands != null ? hands![colour].toSet() : {};

  @override
  String toString() => 'State(turn: $turn, moves: $fullMoves, hash: $hash)';

  const BishopState({
    required this.board,
    this.move,
    this.meta,
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
    this.result,
    this.hash = 0,
  });

  BishopState copyWith({
    List<int>? board,
    Move? move,
    StateMeta? meta,
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
    GameResult? result,
    int? hash,
  }) =>
      BishopState(
        board: board ?? this.board,
        move: move ?? this.move,
        meta: meta ?? this.meta,
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
        result: result ?? this.result,
        hash: hash ?? this.hash,
      );

  BishopState executeActions({
    required ActionTrigger trigger,
    Iterable<Action>? actions,
    Zobrist? zobrist,
  }) {
    if (invalidMove) return this;
    actions ??= trigger.variant.actionsForTrigger(trigger);
    if (actions.isEmpty) return this;
    final action = actions.first;
    BishopState state = this;
    if (action.condition?.call(trigger) ?? true) {
      state = applyEffects(
        effects: action.action(trigger),
        size: trigger.variant.boardSize,
        zobrist: zobrist,
      );
    }
    return actions.length > 1
        ? state.executeActions(
            trigger: trigger.copyWith(state: state),
            actions: actions.skip(1),
            zobrist: zobrist,
          )
        : state;
  }

  BishopState applyEffects({
    required Iterable<ActionEffect> effects,
    required BoardSize size,
    Zobrist? zobrist,
  }) {
    if (invalidMove) return this;
    if (effects.isEmpty) return this;
    int hash = this.hash;
    List<int> board = [...this.board];
    List<int> pieces = [...this.pieces];
    GameResult? result = this.result;
    List<Hand>? hands = this.hands != null
        ? List.generate(this.hands!.length, (i) => List.from(this.hands![i]))
        : null;

    for (ActionEffect effect in effects) {
      if (effect is EffectModifySquare) {
        if (zobrist != null) {
          hash ^= zobrist.table[effect.square][effect.content.piece];
        }
        bool capture = board[effect.square].isNotEmpty;
        if (capture) {
          int piece = board[effect.square].piece;
          if (zobrist != null) hash ^= zobrist.table[effect.square][piece];
          pieces[piece]--;
        }

        board[effect.square] = effect.content;
        if (effect.content.isNotEmpty) {
          pieces[effect.content.piece]++;
        }
      } else if (effect is EffectSetCustomState) {
        board[effect.variable + size.h] = effect.value << Bishop.flagsStartBit;
      } else if (effect is EffectSetGameResult) {
        result = effect.result;
      } else if (effect is EffectAddToHand) {
        if (hands != null) {
          hands[effect.player].add(effect.piece);
          pieces[makePiece(effect.piece, effect.player)]++;
        }
      } else if (effect is EffectRemoveFromHand) {
        if (hands != null) {
          if (hands[effect.player].contains(effect.piece)) {
            hands[effect.player].remove(effect.piece);
            pieces[makePiece(effect.piece, effect.player)]--;
          }
        }
      }
    }

    return copyWith(
      board: board,
      hash: hash,
      result: result,
      pieces: pieces,
      hands: hands,
    );
  }

  /// Generates an ASCII representation of the board.
  String ascii({bool unicode = false, BuiltVariant? variant}) =>
      boardToAscii(board, variant: variant ?? meta?.variant);

  /// Returns a map of all captured pieces.
  /// This assumes that the game started with the same number of pieces as
  /// are present in the start position of the variant.
  /// NOTE: this function will crash for states with no [meta], so only use
  /// this on the mainline.
  Map<String, int> capturedPieces() => meta!.variant.capturedPiecesStr(this);

  /// Returns a list of all captured pieces.
  /// /// This assumes that the game started with the same number of pieces as
  /// are present in the start position of the variant.
  /// NOTE: this function will crash for states with no [meta], so only use
  /// this on the mainline.
  List<String> capturedPiecesList() => expandCountMap(capturedPieces());

  String pieceOnSquare(String square) {
    int sq = meta!.variant.boardSize.squareNumber(square);
    return meta!.variant.pieceSymbol(board[sq].type, board[sq].colour);
  }
}

class StateMeta {
  final BuiltVariant variant;
  final MoveMeta? moveMeta;
  const StateMeta({required this.variant, this.moveMeta});

  String? get algebraic => moveMeta?.algebraic;
  String? get prettyName => moveMeta?.formatted;
}
