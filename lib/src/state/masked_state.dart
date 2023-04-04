part of 'state.dart';

class MaskedState extends BishopState {
  final List<int> mask;
  final bool maskedHands;
  final bool maskedGates;

  Iterable<int> get visibleSquares =>
      mask.asMap().entries.where((e) => e.value > 0).map((e) => e.key);
  Iterable<int> get invisibleSquares =>
      mask.asMap().entries.where((e) => e.value < 1).map((e) => e.key);

  const MaskedState({
    required this.mask,
    this.maskedHands = false,
    this.maskedGates = false,
    required super.board,
    super.move,
    super.meta,
    required super.turn,
    required super.halfMoves,
    required super.fullMoves,
    required super.castlingRights,
    super.epSquare,
    required super.royalSquares,
    required super.virginFiles,
    super.hands,
    super.gates,
    required super.pieces,
    super.checks = const [0, 0],
    super.result,
    super.hash = 0,
  });

  factory MaskedState.mask({
    required List<int> mask,
    required BishopState state,
  }) {
    final board = maskBoard(state.board, mask);
    // todo: count pieces
    return MaskedState(
      mask: mask,
      board: board,
      move: state.move,
      meta: state.meta,
      turn: state.turn,
      halfMoves: state.halfMoves,
      fullMoves: state.fullMoves,
      castlingRights: state.castlingRights,
      epSquare: state.epSquare,
      royalSquares: state.royalSquares,
      virginFiles: state.virginFiles,
      hands: state.hands,
      gates: state.gates,
      pieces: state.pieces,
      checks: state.checks,
      result: state.result,
      hash: state.hash,
    );
  }

  factory MaskedState.fromBishopState(
    BishopState state,
    List<int> mask, {
    List<int>? board,
    List<Hand>? hands,
    List<Hand>? gates,
    List<int>? pieces,
  }) {
    return MaskedState(
      mask: mask,
      board: board ?? state.board,
      move: state.move,
      meta: state.meta,
      turn: state.turn,
      halfMoves: state.halfMoves,
      fullMoves: state.fullMoves,
      castlingRights: state.castlingRights,
      epSquare: state.epSquare,
      royalSquares: state.royalSquares,
      virginFiles: state.virginFiles,
      hands: hands ?? state.hands,
      gates: gates ?? state.gates,
      pieces: pieces ?? state.pieces,
      checks: state.checks,
      result: state.result,
      hash: state.hash,
    );
  }

  @override
  MaskedState copyWith({
    List<int>? mask,
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
  }) {
    return MaskedState(
      mask: mask ?? this.mask,
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
      hash: hash ?? this.hash,
    );
  }
}
