part of 'game.dart';

extension GameMovement on Game {
  /// Make a move and modify the game state. Returns true if the move was valid
  /// and made successfully.
  /// [generateMeta] determines whether to generate the `BishopState.moveMeta`
  /// field. Set this to false for more efficient calculations.
  bool makeMove(Move move, [bool generateMeta = true]) {
    BishopState state = this.state;
    Square fromSq =
        move.from >= Bishop.boardStart ? state.board[move.from] : Bishop.empty;

    if (variant.hasActionsForEvent(ActionEvent.beforeMove)) {
      state = state.executeActions(
        trigger: ActionTrigger(
          event: ActionEvent.beforeMove,
          variant: variant,
          state: state,
          move: move,
          piece: move.dropPiece ?? fromSq,
        ),
        zobrist: zobrist,
      );
    }
    if (move is! StandardMove && move is! DropMove && move is! PassMove) {
      return false;
    }

    if (state.invalidMove) return false;

    BishopState? newState;
    if (move is StandardMove || move is DropMove) {
      newState = makeNormalMove(state, move);
    } else if (move is PassMove) {
      newState = makePassMove(state, move);
    }
    if (newState == null) return false;

    if (variant.hasActionsForEvent(ActionEvent.afterMove)) {
      newState = newState.executeActions(
        trigger: ActionTrigger(
          event: ActionEvent.afterMove,
          variant: variant,
          state: newState,
          move: move,
          piece: move.promoPiece ?? move.dropPiece ?? fromSq,
        ),
        zobrist: zobrist,
      );
    }

    if (generateMeta) {
      newState = newState.copyWith(
        meta: StateMeta(
          variant: variant,
          moveMeta: MoveMeta(
            algebraic: toAlgebraic(move),
            formatted: toSan(move),
          ),
        ),
      );
    }

    history.add(newState);
    if (newState.invalidMove) return false;

    // kind of messy doing it like this, but inCheck depends on the current state
    // maybe that's a case for refactoring some methods into State?
    bool countChecks =
        variant.gameEndConditions[newState.turn.opponent].checkLimit != null;
    if (variant.forbidChecks || countChecks) {
      bool isInCheck = inCheck;
      if (isInCheck) {
        if (countChecks) {
          history.last = newState.copyWith(
            checks: List.from(newState.checks)..[newState.turn.opponent] += 1,
          );
        }
        if (variant.forbidChecks) {
          return false;
        }
      }
    }

    zobrist.incrementHash(newState.hash);
    return true;
  }

  BishopState? makeNormalMove(BishopState state, Move move) {
    if (move is! StandardMove && move is! DropMove) {
      return null;
    }
    Square fromSq =
        move.from >= Bishop.boardStart ? state.board[move.from] : Bishop.empty;

    List<int> board = [...state.board];
    if ((move.from != Bishop.hand && !size.onBoard(move.from)) ||
        !size.onBoard(move.to)) {
      return null;
    }

    int hash = state.hash;
    hash ^= zobrist.table[zobrist.turn][Zobrist.meta];
    List<Hand>? hands = state.hands != null
        ? List.generate(state.hands!.length, (i) => List.from(state.hands![i]))
        : null;
    List<Hand>? gates = state.gates != null
        ? List.generate(state.gates!.length, (i) => List.from(state.gates![i]))
        : null;
    List<List<int>> virginFiles = List.generate(
      state.virginFiles.length,
      (i) => List.from(state.virginFiles[i]),
    );
    List<int> pieces = List.from(state.pieces);
    GameResult? result;

    // TODO: more validation?

    // Square toSq = board[move.to];
    int fromRank = size.rank(move.from);
    int fromFile = size.file(move.from);
    PieceType fromPiece = variant.pieces[fromSq.type].type;
    if (fromSq.isNotEmpty &&
        (fromSq.colour != state.turn &&
            fromSq.colour != Bishop.neutralPassive)) {
      return null;
    }
    int colour = turn;
    // Remove the moved piece, if this piece came from on the board.
    if (move.from >= Bishop.boardStart) {
      hash ^= zobrist.table[move.from][fromSq.piece];
      if (move.promotion) {
        pieces[fromSq.piece]--;
      }
      if (move.gate) {
        move = move as StandardMove;
        if (!(move.castling && move.dropOnRookSquare)) {
          // Move piece from gate to board.
          if (variant.gatingMode == GatingMode.flex) {
            gates![colour].remove(move.dropPiece!);
          } else if (variant.gatingMode == GatingMode.fixed) {
            gates![colour][fromFile] = Bishop.empty;
          }
          int dropPiece = move.dropPiece!;
          hash ^= zobrist.table[move.from][dropPiece.piece];
          board[move.from] = makePiece(dropPiece, colour);
        } else {
          board[move.from] = Bishop.empty;
        }
      } else {
        board[move.from] = Bishop.empty;
      }
      // Mark the file as touched.
      if ((fromRank == 0 && colour == Bishop.white) ||
          (fromRank == size.v - 1 && colour == Bishop.black)) {
        virginFiles[colour].remove(size.file(move.from));
      }
    }

    // Add captured piece to hand
    if (variant.addCapturesToHand && move.capture) {
      int piece = move.capturedPiece!.hasInternalType
          ? move.capturedPiece!.internalType
          : move.capturedPiece!.type;
      hands![colour].add(piece);
      pieces[makePiece(piece, colour)]++;
    }

    // Remove gated piece from gate
    if (move.gate) {
      gates![colour].remove((move as StandardMove).dropPiece!);
    }

    // Remove captured piece from hash and pieces list
    if (move.capture && !move.enPassant) {
      int p = board[move.to].piece;
      hash ^= zobrist.table[move.to][p];
      pieces[p]--;
    }

    if (!move.castling && !move.promotion) {
      // Move the piece to the new square
      int putPiece = move.from >= Bishop.boardStart
          ? fromSq
          : makePiece(move.dropPiece!, colour);
      hash ^= zobrist.table[move.to][putPiece.piece];
      board[move.to] = putPiece;
      // note that it's possible to have a drop move without hands (e.g. duck chess)
      if (move.from == Bishop.hand) hands?[colour].remove(move.dropPiece!);
    } else if (move.promotion) {
      // Place the promoted piece
      board[move.to] =
          makePiece(move.promoPiece!, state.turn, internalType: fromSq.type);
      hash ^= zobrist.table[move.to][board[move.to].piece];
      pieces[board[move.to].piece]++;
    }
    // Manage halfmove counter
    int halfMoves = state.halfMoves;
    if (move.capture || fromPiece.promoOptions.canPromote) {
      halfMoves = 0;
    } else {
      halfMoves++;
    }

    int castlingRights = state.castlingRights;
    List<int> royalSquares = List.from(state.royalSquares);

    if (move.enPassant) {
      // Remove the captured ep piece
      int captureSq = state.move?.to ??
          (move.to + Bishop.playerDirection[colour.opponent] * size.north);
      hash ^= zobrist.table[captureSq][board[captureSq].piece];
      pieces[board[captureSq].piece]--;
      board[captureSq] = Bishop.empty;
    }

    int? epSquare;
    if (move.setEnPassant) {
      // Set the new ep square
      int dir = (move.to - move.from) ~/ 2;
      epSquare = move.from + dir;
      hash ^= zobrist.table[epSquare][Zobrist.meta];
    } else {
      epSquare = null;
    }
    if (state.epSquare != null) {
      // XOR the old ep square away from the hash
      hash ^= zobrist.table[state.epSquare!][Zobrist.meta];
    }

    if (move.castling) {
      move = move as StandardMove;
      bool kingside = move.castlingDir == Castling.k;
      int castlingFile = kingside
          ? variant.castlingOptions.kTarget!
          : variant.castlingOptions.qTarget!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = size.square(rookFile, fromRank);
      int kingSq = size.square(castlingFile, fromRank);
      int rook = board[move.castlingPieceSquare!];
      hash ^= zobrist.table[move.castlingPieceSquare!][rook.piece];
      if (board[kingSq].isNotEmpty) {
        hash ^= zobrist.table[kingSq][board[kingSq].piece];
      }
      hash ^= zobrist.table[kingSq][fromSq.piece];
      if (board[rookSq].isNotEmpty) {
        hash ^= zobrist.table[rookSq][board[rookSq].piece];
      }
      hash ^= zobrist.table[rookSq][rook.piece];
      board[move.castlingPieceSquare!] = Bishop.empty;
      board[kingSq] = fromSq;
      board[rookSq] = rook;
      castlingRights = castlingRights.remove(colour);
      // refactor conditions?
      hash ^= zobrist.table[zobrist.castling][state.castlingRights];
      hash ^= zobrist.table[zobrist.castling][castlingRights];
      royalSquares[colour] = kingSq;

      if (move.gate && move.dropOnRookSquare) {
        int dropPiece = makePiece(move.dropPiece!, colour);
        board[move.castlingPieceSquare!] = dropPiece;
        hash ^= zobrist.table[move.castlingPieceSquare!][dropPiece.piece];
      }
    } else if (fromPiece.royal) {
      // king moved
      castlingRights = castlingRights.remove(colour);
      hash ^= zobrist.table[zobrist.castling][state.castlingRights];
      hash ^= zobrist.table[zobrist.castling][castlingRights];
      royalSquares[colour] = move.to;
    } else if (fromSq.type == variant.castlingPiece) {
      // rook moved
      int fromFile = size.file(move.from);
      bool onFirstRank = size.rank(move.from) == size.firstRank(colour);
      int ks = colour == Bishop.white ? Castling.k : Castling.bk;
      int qs = colour == Bishop.white ? Castling.q : Castling.bq;
      if (fromFile == castlingTargetK &&
          onFirstRank &&
          castlingRights.hasRight(ks)) {
        castlingRights = castlingRights.flip(ks);
        hash ^= zobrist.table[zobrist.castling][state.castlingRights];
        hash ^= zobrist.table[zobrist.castling][castlingRights];
      } else if (fromFile == castlingTargetQ &&
          onFirstRank &&
          castlingRights.hasRight(qs)) {
        castlingRights = castlingRights.flip(qs);
        hash ^= zobrist.table[zobrist.castling][state.castlingRights];
        hash ^= zobrist.table[zobrist.castling][castlingRights];
      }
    } else if (move.capture &&
        move.capturedPiece!.type == variant.castlingPiece) {
      // rook captured
      int toFile = size.file(move.to);
      int opponent = colour.opponent;
      bool onFirstRank = size.rank(move.to) == size.firstRank(opponent);
      int ks = opponent == Bishop.white ? Castling.k : Castling.bk;
      int qs = opponent == Bishop.white ? Castling.q : Castling.bq;
      if (toFile == castlingTargetK &&
          onFirstRank &&
          castlingRights.hasRight(ks)) {
        castlingRights = castlingRights.flip(ks);
        hash ^= zobrist.table[zobrist.castling][state.castlingRights];
        hash ^= zobrist.table[zobrist.castling][castlingRights];
      } else if (toFile == castlingTargetQ &&
          onFirstRank &&
          castlingRights.hasRight(qs)) {
        castlingRights = castlingRights.flip(qs);
        hash ^= zobrist.table[zobrist.castling][state.castlingRights];
        hash ^= zobrist.table[zobrist.castling][castlingRights];
      }
    }
    if (variant.hasWinRegions) {
      int p = board[move.to].piece;
      if (variant.pieceHasWinRegions(p) && variant.inWinRegion(p, move.to)) {
        result = WonGameEnteredRegion(winner: state.turn, square: move.to);
      }
    }

    BishopState newState = BishopState(
      board: board,
      move: move,
      turn: 1 - state.turn,
      halfMoves: halfMoves,
      fullMoves:
          state.turn == Bishop.black ? state.fullMoves + 1 : state.fullMoves,
      castlingRights: castlingRights,
      royalSquares: royalSquares,
      virginFiles: virginFiles,
      epSquare: epSquare,
      hash: hash,
      hands: hands,
      gates: gates,
      pieces: pieces,
      checks: List.from(state.checks),
      result: result,
    );
    return newState;
  }

  BishopState? makePassMove(BishopState state, PassMove move) {
    int hash = state.hash;
    hash ^= zobrist.table[zobrist.turn][Zobrist.meta];
    return state.copyWith(
      move: move,
      turn: 1 - state.turn,
      hash: hash,
    );
  }

  /// Revert to the previous state in [history] and undoes the move that was last made.
  /// Returns the move that was undone.
  Move? undo() {
    if (history.length == 1) return null;
    BishopState lastState = history.removeLast();
    Move move = lastState.move!;
    zobrist.decrementHash(lastState.hash);
    return move;
  }
}
