part of 'game.dart';

extension GameOutputs on Game {
  /// Generates legal moves and returns the one that matches [algebraic].
  /// Returns null if no move is found.
  Move? getMove(String algebraic, {bool simplifyFixedGating = true}) {
    List<Move> moves = generateLegalMoves();
    Move? match = moves.firstWhereOrNull(
      (m) =>
          toAlgebraic(m, simplifyFixedGating: simplifyFixedGating) == algebraic,
    );
    return match;
  }

  /// Returns the algebraic representation of [move], with respect to the board size.
  String toAlgebraic(Move move, {bool simplifyFixedGating = true}) {
    String alg = move.algebraic(
        size: size,
        useRookForCastling: variant.castlingOptions.useRookAsTarget);
    if (move.promotion) {
      alg = '$alg${variant.pieces[move.promoPiece!].symbol.toLowerCase()}';
    }
    if (move.from == Bishop.hand) {
      alg = '${variant.pieces[move.dropPiece!].symbol.toLowerCase()}$alg';
    }
    if (move.gate &&
        !(variant.gatingMode == GatingMode.fixed && simplifyFixedGating)) {
      alg = '$alg/${variant.pieces[move.dropPiece!].symbol.toLowerCase()}';
      if (move.castling) {
        String dropSq = move.dropOnRookSquare
            ? squareName(move.castlingPieceSquare!, size)
            : squareName(move.from, size);
        alg = '$alg$dropSq';
      }
    }
    return alg;
  }

  /// Returns the SAN (Standard Algebraic Notation) representation of a move.
  /// Optionally, provide [moves] - a list of legal moves in the current position, which
  /// is used to determine the disambiguator. Use this if you need speed and have already
  /// generated the list of moves elsewhere.
  String toSan(Move move, [List<Move>? moves]) {
    String san = '';
    if (move.castling) {
      // if queenside is the only castling option, render it as 'O-O'
      String kingside = 'O-O';
      String queenside = variant.castlingOptions.kingside ? 'O-O-O' : kingside;
      san = ([Castling.k, Castling.bk].contains(move.castlingDir))
          ? kingside
          : queenside;
    } else {
      if (move.from == Bishop.hand) {
        PieceDefinition pieceDef = variant.pieces[move.dropPiece!];
        san = move.algebraic(size: size);
        if (!pieceDef.type.noSanSymbol)
          san = '${pieceDef.symbol.toUpperCase()}$san';
      } else {
        int piece = board[move.from].type;
        PieceDefinition pieceDef = variant.pieces[piece];
        String disambiguator = getDisambiguator(move, moves);
        if (pieceDef.type.noSanSymbol) {
          if (move.capture) san = squareName(move.from, size)[0];
        } else {
          san = pieceDef.symbol;
        }
        san = pieceDef.type.noSanSymbol ? disambiguator : '$san$disambiguator';
        if (move.capture) san = '${san}x';
        san = '$san${squareName(move.to, size)}';

        if (move.promotion)
          san = '$san=${variant.pieces[move.promoPiece!].symbol}';
      }
    }
    if (move.gate) {
      san = '$san/${variant.pieces[move.dropPiece!].symbol}';
      if (move.castling) {
        String dropSq = move.dropOnRookSquare
            ? squareName(move.castlingPieceSquare!, size)
            : squareName(move.from, size);
        san = '$san$dropSq';
      }
    }
    makeMove(move);
    if (inCheck) {
      san = '$san${checkmate ? '#' : '+'}';
    }
    undo();
    return san;
  }

  /// To be used in cases where, given a piece and a destination, there is more than
  /// one possible move. For example, in 'Nbxa4', this function provides the 'b'.
  /// Optionally, provide [moves] - a list of legal moves. This will be generated
  /// if it is not specified.
  String getDisambiguator(Move move, [List<Move>? moves]) {
    // provide a list of moves to make this more efficient
    moves ??= generateLegalMoves();

    int piece = board[move.from].type;
    int fromFile = file(move.from, size);
    bool ambiguity = false;
    bool needRank = false;
    bool needFile = false;
    for (Move m in moves) {
      if (m.handDrop) continue;
      if (m.drop && m.dropPiece != move.dropPiece) continue;
      if (m.from == move.from) continue;
      if (m.to != move.to) continue;
      if (piece != board[m.from].type) continue;
      ambiguity = true;
      if (file(m.from, size) == fromFile) {
        needRank = true;
      } else {
        needFile = true;
      }
      if (needRank && needFile) break;
    }

    String disambiguator = '';
    if (ambiguity) {
      String sqName = squareName(move.from, size);
      if (needFile) disambiguator = sqName[0];
      if (needRank) disambiguator = '$disambiguator${sqName[1]}';
    }
    return disambiguator;
  }

  /// Perform a [perft test](https://www.chessprogramming.org/Perft) on the current position, to [depth].
  int perft(int depth) {
    if (depth < 1) return 1;
    List<Move> moves = generateLegalMoves();
    int nodes = 0;
    for (Move m in moves) {
      makeMove(m);
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

  List<String> sanMoves() {
    List<Move> moveStack = [];
    while (canUndo) {
      Move? m = undo();
      if (m == null) break;
      moveStack.add(m);
    }
    List<String> moves = [];
    while (moveStack.isNotEmpty) {
      Move m = moveStack.removeLast();
      String san = toSan(m);
      moves.add(san);
      makeMove(m);
    }
    return moves;
  }

  String pgn() {
    List<String> moves = sanMoves();
    int firstMove = state.fullMoves - (moves.length ~/ 2);
    int firstTurn = history.first.turn;
    int turn = firstTurn;
    String pgn = '';
    for (int i = 0; i < moves.length; i++) {
      if (i == 0 || turn == Bishop.white) pgn = '$pgn${firstMove + i ~/ 2}. ';
      if (i == 0 && turn == Bishop.black) pgn = '$pgn..';
      pgn = '$pgn${moves[i]} ';
      turn = turn.opponent;
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
          if (variant.outputOptions.showPromoted && sq.hasFlag(promoFlag)) {
            char += '~';
          }
          fen = '$fen$char';
        }
      }
      if (empty > 0) addEmptySquares();
      if (i < variant.boardSize.v - 1) fen = '$fen/';
    }
    if (variant.hands) {
      String whiteHand = state.hands![Bishop.white]
          .map((p) => variant.pieces[p].symbol.toUpperCase())
          .join('');
      String blackHand = state.hands![Bishop.black]
          .map((p) => variant.pieces[p].symbol.toLowerCase())
          .join('');
      fen = '$fen[$whiteHand$blackHand]';
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

      fen = '$whiteGate/$fen/$blackGate';
    }
    String turnStr = state.turn == Bishop.white ? 'w' : 'b';
    String castling = state.castlingRights.formatted;
    if (variant.outputOptions.castlingFormat == CastlingFormat.shredder) {
      castling = replaceMultiple(
          castling, Castling.symbols.keys.toList(), castlingFileSymbols);
    }
    if (variant.outputOptions.virginFiles) {
      String whiteVFiles = state.virginFiles[Bishop.white]
          .map((e) => fileSymbol(e).toUpperCase())
          .join('');
      String blackVFiles =
          state.virginFiles[Bishop.black].map((e) => fileSymbol(e)).join('');
      castling = '$castling$whiteVFiles$blackVFiles';
    }
    String ep = state.epSquare != null
        ? squareName(state.epSquare!, variant.boardSize)
        : '-';
    String aux = '';
    if (variant.gameEndConditions.checkLimit != null) {
      aux = ' +${state.checks[Bishop.white]}+${state.checks[Bishop.black]}';
    }
    fen =
        '$fen $turnStr $castling $ep ${state.halfMoves} ${state.fullMoves}$aux';
    return fen;
  }

  /// Generates an ASCII representation of the board.
  String ascii([bool unicode = false]) {
    String border = '   +${'-' * (variant.boardSize.h * 3)}+';
    String output = '$border\n';
    for (int i in Iterable<int>.generate(variant.boardSize.v).toList()) {
      int rank = variant.boardSize.v - i;
      String rankStr = rank > 9 ? '$rank |' : ' $rank |';
      output = '$output$rankStr';
      for (int j in Iterable<int>.generate(variant.boardSize.h).toList()) {
        Square sq = board[i * variant.boardSize.h * 2 + j];
        String char = variant.pieces[sq.type].char(sq.colour);
        if (unicode && Bishop.unicodePieces.containsKey(char)) {
          char = Bishop.unicodePieces[char]!;
        }
        output = '$output $char ';
      }
      output = '$output|\n';
    }
    output = '$output$border\n     ';
    for (String i in Iterable<int>.generate(variant.boardSize.h)
        .map((e) => String.fromCharCode(e + 97))
        .toList()) {
      output = '$output$i  ';
    }
    return output;
  }

  /// Converts the internal board representation to a list of piece symbols (e.g. 'P', 'q').
  /// You probably need this for interopability with other applications (such as the Squares package).
  List<String> boardSymbols([bool full = false]) {
    List<String> symbols = [];
    for (int i = 0; i < board.length; i++) {
      if (full || onBoard(i, size)) {
        int piece = board[i];
        String symbol = piece == empty ? '' : variant.pieces[piece.type].symbol;
        symbols.add(piece.colour == Bishop.white
            ? symbol.toUpperCase()
            : symbol.toLowerCase());
      }
    }
    return symbols;
  }

  /// Converts the internal representation of the hands to a list of piece symbols (e.g. 'P', 'q').
  /// You probably need this for interopability with other applications (such as the Squares package).
  List<List<String>> handSymbols() {
    if (!variant.hands) return [[], []];
    List<String> whiteHand = state.hands![Bishop.white]
        .map((p) => variant.pieces[p].symbol.toUpperCase())
        .toList();
    List<String> blackHand = state.hands![Bishop.black]
        .map((p) => variant.pieces[p].symbol.toLowerCase())
        .toList();
    return [whiteHand, blackHand];
  }

  /// Converts the internal representation of the gates to a list of piece symbols (e.g. 'P', 'q').
  /// You probably need this for interopability with other applications (such as the Squares package).
  List<List<String>> gateSymbols() {
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
                : squareName(state.move!.from, size))
            : null,
        lastTo: state.move != null ? squareName(state.move!.to, size) : null,
        checkSq:
            inCheck ? squareName(state.royalSquares[state.turn], size) : null,
      );
}
