part of 'game.dart';

extension GameOutputs on Game {
  /// Generates legal moves and returns the one that matches [algebraic].
  /// Returns null if no move is found.
  Move? getMove(String algebraic) {
    List<Move> moves = generateLegalMoves();
    Move? match = moves.firstWhereOrNull(
      (m) => toAlgebraic(m) == algebraic,
    );
    return match;
  }

  /// Gets a move from a SAN string, e.g. 'Nxf3', 'e4', 'O-O-O'.
  /// If [checks] is false, the '+' or '#' part of the SAN string will not be
  /// computed, which vastly increases efficiency in cases like PGN parsing.\
  Move? getMoveSan(String san, {bool checks = false}) {
    if (!checks) {
      san = san.replaceAll('#', '').replaceAll('+', '');
    }
    List<Move> moves = generateLegalMoves();
    Move? match = moves
        .firstWhereOrNull((m) => toSan(m, moves: moves, checks: checks) == san);
    return match;
  }

  /// Returns the algebraic representation of [move], with respect to the board size.
  String toAlgebraic(Move move) {
    if (move is PassMove) return move.algebraic();
    if (move is DropMove) {
      return '${variant.pieces[move.piece].symbol.toLowerCase()}${move.algebraic(size)}';
    }
    if (move is GatingMove) {
      String alg = toAlgebraic(move.child);
      if (variant.gatingMode == GatingMode.fixed) {
        return alg;
      }
      alg = '$alg/${variant.pieces[move.dropPiece].symbol.toLowerCase()}';
      if (move.child.castling) {
        String dropSq = move.dropOnRookSquare
            ? size.squareName(move.child.castlingPieceSquare!)
            : size.squareName(move.from);
        alg = '$alg$dropSq';
      }
      return alg;
    }
    if (move is! StandardMove) return '';
    String alg = move.algebraic(
      size: size,
      useRookForCastling: variant.castlingOptions.useRookAsTarget,
    );
    if (move.promotion) {
      alg = '$alg${variant.pieces[move.promoPiece!].symbol.toLowerCase()}';
    }
    if (move.from == Bishop.hand) {
      alg = '${variant.pieces[move.dropPiece!].symbol.toLowerCase()}$alg';
    }
    return alg;
  }

  /// Returns the SAN (Standard Algebraic Notation) representation of a move.
  /// Optionally, provide [moves] - a list of legal moves in the current position, which
  /// is used to determine the disambiguator. Use this if you need speed and have already
  /// generated the list of moves elsewhere.
  /// If [checks] is false, the '+' or '#' part of the SAN string will not be
  /// computed, which vastly increases efficiency in cases like PGN parsing.
  String toSan(Move move, {List<Move>? moves, bool checks = true}) {
    if (move is PassMove) return move.algebraic();
    if (move is GatingMove) {
      String san = '${toSan(move.child, checks: checks)}/'
          '${variant.pieces[move.dropPiece].symbol}';
      if (move.castling) {
        String dropSq = move.dropOnRookSquare
            ? size.squareName(move.child.castlingPieceSquare!)
            : size.squareName(move.from);
        san = '$san$dropSq';
      }
      // a hack, will be reworked eventually
      if (san.contains('+')) {
        san = '${san.replaceAll('+', '')}+';
      }
      if (san.contains('#')) {
        san = '${san.replaceAll('#', '')}#';
      }
      return san;
    }
    if (move is! StandardMove && move is! DropMove) return '';
    String san = '';
    if (move.castling) {
      move = move as StandardMove;
      // if queenside is the only castling option, render it as 'O-O'
      String kingside = 'O-O';
      String queenside = variant.castlingOptions.kingside ? 'O-O-O' : kingside;
      san = ([Castling.k, Castling.bk].contains(move.castlingDir))
          ? kingside
          : queenside;
    } else {
      if (move is DropMove) {
        PieceDefinition pieceDef = variant.pieces[move.piece];
        san = move.algebraic(size);
        if (!pieceDef.type.noSanSymbol) {
          san = '${pieceDef.symbol.toUpperCase()}$san';
        }
      } else {
        move = move as StandardMove;
        int piece = board[move.from].type;
        PieceDefinition pieceDef = variant.pieces[piece];
        String disambiguator = getDisambiguator(move, moves);
        if (pieceDef.type.noSanSymbol) {
          if (move.capture) san = size.squareName(move.from)[0];
        } else {
          san = pieceDef.symbol;
        }
        if (disambiguator.isNotEmpty) {
          san =
              pieceDef.type.noSanSymbol ? disambiguator : '$san$disambiguator';
        }
        if (move.capture) san = '${san}x';
        san = '$san${size.squareName(move.to)}';

        if (move.promotion) {
          san = '$san=${variant.pieces[move.promoPiece!].symbol}';
        }
      }
    }
    if (checks) {
      bool ok = makeMove(move, false);
      if (!ok) return 'invalid';
      if (inCheck || won) {
        san = '$san${won ? '#' : '+'}';
      }
      undo();
    }
    return san;
  }

  /// To be used in cases where, given a piece and a destination, there is more than
  /// one possible move. For example, in 'Nbxa4', this function provides the 'b'.
  /// Optionally, provide [moves] - a list of legal moves. This will be generated
  /// if it is not specified.
  String getDisambiguator(StandardMove move, [List<Move>? moves]) {
    // provide a list of moves to make this more efficient
    moves ??= generateLegalMoves();

    return getStandardDisambiguator(
      move: move,
      moves: moves,
      variant: variant,
      state: state,
    );
  }

  /// Perform a [perft test](https://www.chessprogramming.org/Perft) on the current position, to [depth].
  int perft(int depth) {
    if (depth < 1) return 1;
    List<Move> moves = generateLegalMoves();
    int nodes = 0;
    for (Move m in moves) {
      makeMove(m, false);
      if (depth - 1 > 0) {
        int childNodes = perft(depth - 1);
        nodes += childNodes;
      } else {
        nodes++;
      }
      undo();
    }
    return nodes;
  }

  /// Get a list of legal moves in the current position, in algebraic format.
  List<String> algebraicMoves() =>
      generateLegalMoves().map((e) => toAlgebraic(e)).toList();

  /// Get a list of moves played in the game so far.
  List<Move> get moveHistory =>
      history.where((e) => e.move != null).map((e) => e.move!).toList();

  /// Get the history of the game (i.e. all moves played) in algebraic format.
  List<String> get moveHistoryAlgebraic => history
      .where((e) => e.move != null)
      .map((e) => toAlgebraic(e.move!))
      .toList();

  /// Get the history of the game (i.e. all moves played) in SAN format.
  List<String> get moveHistorySan {
    final sans = history.skip(1).map((e) => e.meta?.prettyName).toList();
    if (!sans.contains(null)) {
      return sans.map((e) => e as String).toList();
    }
    List<BishopState> stateStack = [];
    while (canUndo) {
      stateStack.add(state);
      undo();
    }
    List<String> moves = [];
    while (stateStack.isNotEmpty) {
      BishopState s = stateStack.removeLast();
      Move m = s.move!;
      String san = s.meta?.prettyName ?? toSan(m);
      moves.add(san);
      makeMove(m);
    }
    return moves;
  }

  @Deprecated('Use Game.moveHistorySan')
  List<String> sanMoves() => moveHistorySan;

  String pgn({
    Map<String, String>? metadata,
    bool includeVariant = false,
    bool includeResult = true,
  }) {
    metadata ??= {};
    List<String> moves = moveHistorySan;
    int firstMove = state.fullMoves - (moves.length ~/ 2);
    int firstTurn = history.first.turn;
    int turn = firstTurn;
    String pgn = '';
    for (int i = 0; i < moves.length; i++) {
      if (i == 0 || turn == Bishop.white)
        pgn = '$pgn${firstMove + i ~/ 2}${(i == 0 && turn == Bishop.black) ? "" : ". "}';
      if (i == 0 && turn == Bishop.black) pgn = '$pgn... ';
      pgn = '$pgn${moves[i]} ';
      turn = turn.opponent;
    }
    if (includeVariant &&
        !metadata.containsKey('Variant') &&
        variant.name != 'Chess') {
      metadata['Variant'] = variant.name;
    }

    if (metadata.isNotEmpty) {
      String meta =
          metadata.entries.map((e) => '[${e.key} "${e.value}"]').join('\n');
      pgn = '$meta\n\n$pgn';
    }
    if (gameOver) {
      String comment = '{${result!.readable}} ${result!.scoreString}';
      pgn = '$pgn $comment';
    }
    return pgn;
  }

  String get fen {
    assert(board.length == variant.boardSize.numIndices);
    String fen = '';
    int empty = 0;

    void addEmptySquares() {
      if (empty > 0) {
        fen = '$fen$empty';
        empty = 0;
      }
    }

    for (int i = 0; i < variant.boardSize.v; i++) {
      for (int j = 0; j < variant.boardSize.h; j++) {
        int s = (i * variant.boardSize.h * 2) + j;
        Square sq = board[s];
        if (sq.isEmpty) {
          empty++;
        } else {
          if (empty > 0) addEmptySquares();
          String char = variant.pieces[sq.type].char(sq.colour);
          if (variant.outputOptions.showPromoted && sq.hasInternalType) {
            char += '~';
          }
          fen = '$fen$char';
        }
      }
      if (empty > 0) addEmptySquares();
      if (i < variant.boardSize.v - 1) fen = '$fen/';
    }
    if (variant.handsEnabled) {
      fen = '$fen[$handString]';
    }
    if (variant.gatingMode == GatingMode.flex) {
      String whiteGate = state.gates![Bishop.white]
          .map((p) => variant.pieces[p].symbol.toUpperCase())
          .join('');
      String blackGate = state.gates![Bishop.black]
          .map((p) => variant.pieces[p].symbol.toLowerCase())
          .join('');
      fen = '$fen[$whiteGate$blackGate]';
    }
    if (variant.gatingMode == GatingMode.fixed) {
      String whiteGate = state.gates![Bishop.white]
          .map((p) => variant.pieces[p].symbol.toUpperCase())
          .join('');
      String blackGate = state.gates![Bishop.black]
          .map((p) => variant.pieces[p].symbol.toLowerCase())
          .join('');
      // replaces dots with numbers
      String processGate(String g) {
        String o = '';
        int n = 0;
        for (String c in g.split('')) {
          if (c == '.') {
            n++;
          } else {
            if (n > 0) {
              o = '$o$n';
              n = 0;
            }
            o = '$o$c';
          }
        }
        if (n > 0) {
          o = '$o$n';
        }
        return o;
      }

      whiteGate = processGate(whiteGate);
      blackGate = processGate(blackGate);

      fen = '$blackGate/$fen/$whiteGate';
    }
    String turnStr = state.turn == Bishop.white ? 'w' : 'b';
    String castling = state.castlingRights.formatted;
    if (variant.outputOptions.castlingFormat == CastlingFormat.shredder) {
      castling = replaceMultiple(
        castling,
        Castling.symbols.keys.toList(),
        castlingFileSymbols,
      );
    }
    if (variant.outputOptions.virginFiles) {
      String whiteVFiles = state.virginFiles[Bishop.white]
          .map((e) => fileSymbol(e).toUpperCase())
          .join('');
      String blackVFiles =
          state.virginFiles[Bishop.black].map((e) => fileSymbol(e)).join('');
      castling = '$castling$whiteVFiles$blackVFiles';
    }
    String ep = state.epSquare != null ? size.squareName(state.epSquare!) : '-';
    String aux = '';
    if (variant.gameEndConditions.hasCheckLimit) {
      aux = ' +${state.checks[Bishop.white]}+${state.checks[Bishop.black]}';
    }
    fen =
        '$fen $turnStr $castling $ep ${state.halfMoves} ${state.fullMoves}$aux';
    return fen;
  }

  /// Generates an ASCII representation of the board.
  String ascii([bool unicode = false]) =>
      state.ascii(unicode: unicode, variant: variant);

  /// Converts the internal board representation to a list of piece symbols (e.g. 'P', 'q').
  /// You probably need this for interopability with other applications (such as the Squares package).
  List<String> boardSymbols([bool full = false]) {
    List<String> symbols = [];
    for (int i = 0; i < board.length; i++) {
      if (full || size.onBoard(i)) {
        int piece = board[i];
        String symbol = piece.isEmpty ? '' : variant.pieces[piece.type].symbol;
        symbols.add(
          piece.colour == Bishop.white
              ? symbol.toUpperCase()
              : symbol.toLowerCase(),
        );
      }
    }
    return symbols;
  }

  /// Converts the internal representation of the hands to a list of piece symbols (e.g. 'P', 'q').
  /// You probably need this for interopability with other applications (such as the Squares package).
  List<List<String>> get handSymbols {
    if (!variant.handsEnabled) return [[], []];
    List<String> whiteHand = state.hands![Bishop.white]
        .map((p) => variant.pieces[p].symbol.toUpperCase())
        .toList();
    List<String> blackHand = state.hands![Bishop.black]
        .map((p) => variant.pieces[p].symbol.toLowerCase())
        .toList();
    return [whiteHand, blackHand];
  }

  String get handString {
    final symbols = handSymbols;
    return [...symbols.first, ...symbols.last].join('');
  }

  /// Converts the internal representation of the gates to a list of piece symbols (e.g. 'P', 'q').
  /// You probably need this for interopability with other applications (such as the Squares package).
  List<List<String>> get gateSymbols {
    if (!variant.gating) return [[], []];
    List<String> whiteGate = state.gates![Bishop.white]
        .map((p) => variant.pieces[p].symbol.toUpperCase())
        .toList();
    List<String> blackGate = state.gates![Bishop.black]
        .map((p) => variant.pieces[p].symbol.toLowerCase())
        .toList();
    return [whiteGate, blackGate];
  }

  GameInfo get info => GameInfo(
        lastMove: state.move,
        lastFrom: state.move != null
            ? (state.move!.from == Bishop.hand
                ? 'hand'
                : size.squareName(state.move!.from))
            : null,
        lastTo: state.move != null ? size.squareName(state.move!.to) : null,
        checkSq:
            inCheck ? size.squareName(state.royalSquares[state.turn]) : null,
      );

  /// Retrieves the value of the custom state variable [i].
  int getCustomState(int i) =>
      state.board[size.secretSquare(i)] >> Bishop.flagsStartBit;
}
