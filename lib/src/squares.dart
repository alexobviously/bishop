import 'dart:math';

import 'castling_rights.dart';
import 'constants.dart';
import 'first_where_extension.dart';
import 'move.dart';
import 'move_definition.dart';
import 'move_gen_options.dart';
import 'piece_type.dart';
import 'square.dart';
import 'state.dart';
import 'utils.dart';
import 'variant/variant.dart';

class Squares {
  final Variant variant;
  late List<int> board;
  late String startPosition;
  List<State> history = [];
  State get state => history.last;
  bool get canUndo => history.length > 1;
  Colour get turn => state.turn;

  int? castlingTargetK;
  int? castlingTargetQ;
  int? royalFile;
  List<String>? castlingFileSymbols;
  late MoveGenOptions royalCaptureOptions;

  BoardSize get size => variant.boardSize;

  Squares({required this.variant, String? fen}) {
    startPosition = fen ?? (variant.startPosBuilder != null ? variant.startPosBuilder!() : variant.startPosition);
    buildBoard();
    royalCaptureOptions = MoveGenOptions.pieceCaptures(variant.royalPiece);
  }
  int setupCastling(String castlingString, List<int> royalSquares) {
    if (castlingString == '-') {
      return 0;
    }
    if (!isAlpha(castlingString) || castlingString.length > 4) throw ('Invalid castling string');
    CastlingRights cr = 0;
    for (String c in castlingString.split('')) {
      // there is probably a better way to do all of this
      bool white = c == c.toUpperCase();
      royalFile = file(royalSquares[white ? 0 : 1], size);
      if (CASTLING_SYMBOLS.containsKey(c)) {
        cr += CASTLING_SYMBOLS[c]!;
      } else {
        int _file = c.toLowerCase().codeUnits.first - 97;
        bool kingside = _file > file(royalSquares[white ? 0 : 1], size);
        if (kingside) {
          castlingTargetK = _file;
          cr += white ? CASTLING_K : CASTLING_BK;
        } else {
          castlingTargetQ = _file;
          cr += white ? CASTLING_Q : CASTLING_BQ;
        }
      }
    }
    if (variant.castlingOptions.fixedRooks) {
      castlingTargetK = variant.castlingOptions.kRook;
      castlingTargetQ = variant.castlingOptions.qRook;
    } else {
      for (int i = 0; i < 2; i++) {
        if (castlingTargetK != null && castlingTargetQ != null) break;
        int r = i * (size.v - 1) * size.north;
        bool kingside = false;
        for (int j = 0; j < size.h; j++) {
          int _piece = board[r + j].piece;
          if (_piece == variant.royalPiece)
            kingside = true;
          else if (_piece == variant.castlingPiece) {
            if (kingside) {
              castlingTargetK = j;
            } else {
              castlingTargetQ = j;
            }
          }
        }
      }
    }
    if (variant.outputOptions.castlingFormat == CastlingFormat.Shredder) {
      String k = fileSymbol(castlingTargetK!);
      String q = fileSymbol(castlingTargetQ!);
      castlingFileSymbols = [k.toUpperCase(), q.toUpperCase(), k, q];
    }
    return cr;
  }

  void buildBoard() {
    Map<String, int> pieceLookup = {};
    for (int i = 0; i < variant.pieces.length; i++) {
      pieceLookup[variant.pieces[i].symbol] = i;
    }

    board = List.filled(variant.boardSize.numSquares * 2, 0);
    List<String> sections = startPosition.split(' ');
    List<String> _board = sections[0].split('');
    String _turn = sections[1];
    String _castling = sections[2];
    String _ep = sections[3];
    String _halfMoves = sections[4];
    String _fullMoves = sections[5];
    int sq = 0;
    int emptySquares = 0;
    List<int> royalSquares = [INVALID, INVALID];
    for (String c in _board) {
      String symbol = c.toUpperCase();
      if (isNumeric(c)) {
        emptySquares = (emptySquares * 10) + int.parse(c);
      } else {
        sq += emptySquares;
        emptySquares = 0;
      }
      if (c == '/') sq += variant.boardSize.h;
      if (pieceLookup.containsKey(symbol)) {
        // it's a piece
        int pieceIndex = pieceLookup[symbol]!;
        Colour colour = c == symbol ? WHITE : BLACK;
        Square piece = makePiece(pieceIndex, colour);
        board[sq] = piece;
        if (variant.pieces[pieceIndex].type.royal) {
          royalSquares[colour] = sq;
        }
        sq++;
      }
    }

    int turn = _turn == 'w' ? WHITE : BLACK;
    int? ep = _ep == '-' ? null : squareNumber(_ep, variant.boardSize);
    int castling = variant.castling ? setupCastling(_castling, royalSquares) : 0;
    State _state = State(
      turn: turn,
      halfMoves: int.parse(_halfMoves),
      fullMoves: int.parse(_fullMoves),
      epSquare: ep,
      castlingRights: castling,
      royalSquares: royalSquares,
    );
    history.add(_state);
  }

  String get fen {
    assert(board.length == variant.boardSize.numSquares);
    String _fen = '';
    int empty = 0;

    void addEmptySquares() {
      if (empty > 0) {
        _fen = '$_fen$empty';
        empty = 0;
      }
    }

    for (int i = 0; i < variant.boardSize.v; i++) {
      for (int j = 0; j < variant.boardSize.h; j++) {
        int s = (i * variant.boardSize.h * 2) + j;
        Square sq = board[s];
        if (sq.isEmpty)
          empty++;
        else {
          if (empty > 0) addEmptySquares();
          String char = variant.pieces[sq.piece].char(sq.colour);
          _fen = '$_fen$char';
        }
      }
      if (empty > 0) addEmptySquares();
      if (i < variant.boardSize.v - 1) _fen = '$_fen/';
    }
    String _turn = state.turn == WHITE ? 'w' : 'b';
    String _castling = state.castlingRights.formatted;
    if (variant.outputOptions.castlingFormat == CastlingFormat.Shredder) {
      _castling = replaceMultiple(_castling, CASTLING_SYMBOLS.keys.toList(), castlingFileSymbols!);
    }
    String _ep = state.epSquare != null ? squareName(state.epSquare!, variant.boardSize) : '-';
    _fen = '$_fen $_turn $_castling $_ep ${state.halfMoves} ${state.fullMoves}';
    return _fen;
  }

  String ascii([bool unicode = false]) {
    String border = '   +${'-' * (variant.boardSize.h * 3)}+';
    String output = '$border\n';
    for (int i in Iterable<int>.generate(variant.boardSize.v).toList()) {
      int rank = variant.boardSize.v - i;
      String _rank = rank > 9 ? '$rank |' : ' $rank |';
      output = '$output$_rank';
      for (int j in Iterable<int>.generate(variant.boardSize.h).toList()) {
        Square sq = board[i * variant.boardSize.h * 2 + j];
        String char = variant.pieces[sq.piece].char(sq.colour);
        if (unicode && UNICODE_PIECES.containsKey(char)) char = UNICODE_PIECES[char]!;
        output = '$output $char ';
      }
      output = '$output|\n';
    }
    output = '$output$border';
    return output;
  }

  List<Move> generateLegalMoves() => generatePlayerMoves(state.turn, MoveGenOptions.normal());

  List<Move> generatePlayerMoves(int player, [MoveGenOptions? options]) {
    if (options == null) options = MoveGenOptions.normal();
    List<Move> moves = [];
    for (int i = 0; i < board.length; i++) {
      Square target = board[i];
      if (target.isNotEmpty && target.colour == player) {
        List<Move> pieceMoves = generatePieceMoves(i, options);
        moves.addAll(pieceMoves);
      }
    }
    return moves;
  }

  List<Move> generatePieceMoves(int square, [MoveGenOptions? options]) {
    if (options == null) options = MoveGenOptions.normal();
    Square piece = board[square];
    if (piece.isEmpty) return [];
    Colour colour = piece.colour;
    int dirMult = PLAYER_DIRECTION[piece.colour];
    List<Move> moves = [];
    PieceType pieceType = variant.pieces[piece.piece].type;
    int from = square;
    int fromRank = rank(from, size);
    bool exit = false;
    // Generate normal moves
    for (MoveDefinition md in pieceType.moves) {
      if (exit) break;
      if (!md.capture && !options.quiet) continue;
      if (!md.quiet && !options.captures) continue;
      if (md.firstOnly && !variant.firstMoveRanks[colour].contains(fromRank)) continue;
      int range = md.range == 0 ? variant.boardSize.maxDim : md.range;
      for (int i = 0; i < range; i++) {
        if (exit) break;
        int to = square + md.normalised * (i + 1) * dirMult;
        if (!onBoard(to, variant.boardSize)) break;
        if (md.lame) {
          int _from = from + md.normalised * i * dirMult;
          int blockSq = _from + md.lameNormalised! * dirMult;
          if (board[blockSq].isNotEmpty) break;
        }
        bool optPromo = false;
        bool forcedPromo = false;
        if (pieceType.promotable && variant.promotion) {
          int toRank = rank(to, size);
          optPromo =
              colour == WHITE ? toRank >= variant.promotionRanks[BLACK] : toRank <= variant.promotionRanks[WHITE];
          if (optPromo) {
            forcedPromo = colour == WHITE ? toRank >= size.maxRank : toRank <= RANK_1;
          }
        }
        Square target = board[to];
        bool setEnPassant = variant.enPassant && md.firstOnly && pieceType.enPassantable;

        void addMove(Move m) {
          if (optPromo) moves.addAll(generatePromotionMoves(m));
          if (!forcedPromo) moves.add(m);
          if (options!.onlySquare != null && m.to == options.onlySquare) {
            exit = true;
          }
        }

        if (target.isEmpty) {
          // TODO: prioritise ep? for moves that could be both ep and quiet
          if (md.quiet) {
            if (!options.quiet && options.onlySquare == null) continue;
            Move m = Move(to: to, from: from, setEnPassant: setEnPassant);
            addMove(m);
          } else if (variant.enPassant && md.enPassant && state.epSquare == to && options.captures) {
            Move m = Move(
              to: to,
              from: from,
              capturedPiece: makePiece(variant.epPiece, colour.opponent),
              enPassant: true,
              setEnPassant: setEnPassant,
            );
            addMove(m);
          } else if (options.onlySquare != null && to == options.onlySquare) {
            Move m = Move(
              to: to,
              from: from,
            );
            addMove(m);
          } else {
            break;
          }
        } else if (target.colour == colour) {
          break;
        } else {
          if (md.capture) {
            if (!options.captures) break;
            if (options.onlyPiece && target.piece != options.pieceType) break;
            Move m = Move(
              to: to,
              from: from,
              capturedPiece: target,
              setEnPassant: setEnPassant,
            );
            addMove(m);
          }
          break;
        }
      }
    }

    // Generate castling
    if (variant.castling && options.castling && pieceType.royal) {
      bool kingside = colour == WHITE ? state.castlingRights.wk : state.castlingRights.bk;
      bool queenside = colour == WHITE ? state.castlingRights.wq : state.castlingRights.bq;
      int royalRank = rank(from, variant.boardSize);

      for (int i = 0; i < 2; i++) {
        bool sideCondition = i == 0 ? kingside : queenside;
        if (!sideCondition) continue;
        int targetFile = i == 0 ? variant.castlingOptions.kTarget! : variant.castlingOptions.qTarget!;
        int targetSq = getSquare(targetFile, royalRank, variant.boardSize);
        int rookFile = i == 0 ? castlingTargetK! : castlingTargetQ!;
        int rookSq = getSquare(rookFile, royalRank, variant.boardSize);
        if (board[targetSq].isNotEmpty &&
            (board[targetSq].piece != variant.castlingPiece || board[targetSq].colour != colour)) continue;
        int numMidSqs = (targetFile - royalFile!).abs();
        bool _valid = true;
        for (int j = 1; j <= numMidSqs; j++) {
          int midFile = royalFile! + (i == 0 ? j : -j);
          if (midFile == rookFile) continue; // for some chess960 positions
          int midSq = getSquare(midFile, royalRank, variant.boardSize);
          if (j != numMidSqs && board[midSq].isNotEmpty) {
            // squares between to and from must be empty
            _valid = false;
            break;
          }
          if (isAttacked(midSq, colour.opponent)) {
            // squares between & dest square must not be attacked
            _valid = false;
            break;
          }
        }
        if (_valid) {
          int castlingDir = i == 0 ? CASTLING_K : CASTLING_Q;
          Move m = Move(
            from: from,
            to: targetSq,
            castlingDir: castlingDir,
            castlingPieceSquare: rookSq,
          );
          moves.add(m);
        }
      }
    }

    if (options.onlySquare != null) {
      List<Move> _remove = [];
      for (Move m in moves) {
        if (m.to != options.onlySquare) {
          _remove.add(m);
        }
      }
      _remove.forEach((m) => moves.remove(m));
    }

    if (options.legal) {
      List<Move> _remove = [];
      for (Move m in moves) {
        makeMove(m);
        if (kingAttacked(colour)) _remove.add(m);
        undo();
      }
      _remove.forEach((m) => moves.remove(m));
    }
    return moves;
  }

  List<Move> generatePromotionMoves(Move base) {
    List<Move> moves = [];
    for (int p in variant.promotionPieces) {
      Move m = base.copyWith(promoSource: board[base.from].piece, promoPiece: p);
      moves.add(m);
    }
    return moves;
  }

  bool makeMove(Move move) {
    if (!onBoard(move.from, size) || !onBoard(move.to, size)) return false;
    // TODO: more validation?
    Square fromSq = board[move.from];
    Square toSq = board[move.to];
    PieceType fromPiece = variant.pieces[fromSq.piece].type;
    int colour = fromSq.colour;
    if (colour != state.turn) return false;
    board[move.from] = EMPTY;
    if (!move.castling && !move.promotion) {
      board[move.to] = fromSq;
    } else if (move.promotion) {
      board[move.to] = makePiece(move.promoPiece!, state.turn);
    }
    int _halfMoves = state.halfMoves;
    if (move.capture || fromPiece.promotable)
      _halfMoves = 0;
    else
      _halfMoves++;
    int _castlingRights = state.castlingRights;
    List<int> royalSquares = List.from(state.royalSquares);

    if (move.enPassant) {
      int captureSq = move.to + PLAYER_DIRECTION[colour.opponent] * size.north;
      board[captureSq] = EMPTY;
    }

    int? epSquare;
    if (move.setEnPassant) {
      int dir = (move.to - move.from) ~/ 2;
      epSquare = move.from + dir;
    } else {
      epSquare = null;
    }

    // TODO: en passant & set en passant
    if (move.castling) {
      bool kingside = move.castlingDir == CASTLING_K;
      int royalRank = rank(move.from, size);
      int castlingFile = kingside ? variant.castlingOptions.kTarget! : variant.castlingOptions.qTarget!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = getSquare(rookFile, royalRank, size);
      int kingSq = getSquare(castlingFile, royalRank, size);
      int rook = board[move.castlingPieceSquare!];
      board[move.castlingPieceSquare!] = EMPTY;
      board[kingSq] = fromSq;
      board[rookSq] = rook;
      _castlingRights = _castlingRights.remove(colour);
      royalSquares[colour] = kingSq;
    } else if (fromPiece.royal) {
      // king moved
      _castlingRights = _castlingRights.remove(colour);
      royalSquares[colour] = move.to;
    } else if (fromSq.piece == variant.castlingPiece) {
      // rook moved
      int fromFile = file(move.from, size);
      int ks = colour == WHITE ? CASTLING_K : CASTLING_BK;
      int qs = colour == WHITE ? CASTLING_Q : CASTLING_BQ;
      if (fromFile == castlingTargetK && _castlingRights.hasRight(ks)) {
        _castlingRights = _castlingRights.flip(ks);
      } else if (fromFile == castlingTargetQ && _castlingRights.hasRight(qs)) {
        _castlingRights = _castlingRights.flip(qs);
      }
    } else if (move.capture && move.capturedPiece == variant.castlingPiece) {
      // rook captured
      int toFile = file(move.to, size);
      int opponent = colour.opponent;
      int ks = opponent == WHITE ? CASTLING_K : CASTLING_BK;
      int qs = opponent == WHITE ? CASTLING_Q : CASTLING_BQ;
      if (toFile == castlingTargetK && _castlingRights.hasRight(ks)) {
        _castlingRights = _castlingRights.flip(ks);
      } else if (toFile == castlingTargetQ && _castlingRights.hasRight(qs)) {
        _castlingRights = _castlingRights.flip(qs);
      }
    }

    State _state = State(
      move: move,
      turn: 1 - state.turn,
      halfMoves: _halfMoves,
      fullMoves: state.turn == BLACK ? state.fullMoves + 1 : state.fullMoves,
      castlingRights: _castlingRights,
      royalSquares: royalSquares,
      epSquare: epSquare,
    );
    history.add(_state);
    return true;
  }

  Move? undo() {
    if (history.length == 1) return null;
    State _state = history.removeLast();
    Move move = _state.move!;

    int toSq = board[move.to];

    if (move.castling) {
      bool kingside = move.castlingDir == CASTLING_K;
      int royalRank = rank(move.from, size);
      int castlingFile = kingside ? variant.castlingOptions.kTarget! : variant.castlingOptions.qTarget!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = getSquare(rookFile, royalRank, size);
      int _rook = board[rookSq];
      int _king = board[move.to];
      board[move.to] = EMPTY;
      board[rookSq] = EMPTY;
      board[move.from] = _king;
      board[move.castlingPieceSquare!] = _rook;
    } else {
      if (move.promotion) {
        board[move.from] = makePiece(move.promoSource!, state.turn);
      } else {
        board[move.from] = toSq;
      }
      if (move.enPassant) {
        int captureSq = move.to + PLAYER_DIRECTION[move.capturedPiece!.colour] * size.north;
        board[captureSq] = move.capturedPiece!;
      }
      if (move.capture && !move.enPassant) {
        board[move.to] = move.capturedPiece!;
      } else {
        board[move.to] = EMPTY;
      }
    }

    return move;
  }

  Move makeRandomMove() {
    List<Move> moves = generateLegalMoves();
    int i = Random().nextInt(moves.length);
    makeMove(moves[i]);
    return moves[i];
  }

  bool hasKingCapture() {
    List<Move> moves = generatePlayerMoves(state.turn, royalCaptureOptions);
    return moves.isNotEmpty;
  }

  bool isAttacked(int square, Colour colour) {
    List<Move> attacks = generatePlayerMoves(colour, MoveGenOptions.squareAttacks(square));
    return attacks.isNotEmpty;
  }

  bool kingAttacked(int player) => isAttacked(state.royalSquares[player], player.opponent);

  bool get inCheck => kingAttacked(state.turn);
  bool get checkmate => inCheck && generateLegalMoves().isEmpty;
  bool get stalemate => !inCheck && generateLegalMoves().isEmpty;
  bool get insufficientMaterial => false;
  bool get repetition => false;
  bool get halfMoveRule => variant.halfMoveDraw != null && state.halfMoves >= variant.halfMoveDraw!;
  bool get inDraw => stalemate || insufficientMaterial || repetition || halfMoveRule;
  bool get gameOver => checkmate || inDraw;

  Move? getMove(String algebraic) {
    List<Move> moves = generateLegalMoves();
    Move? match = moves.firstWhereOrNull((m) => m.algebraic(size) == algebraic);
    return match;
  }

  String toAlgebraic(Move move) {
    String alg = move.algebraic(size);
    if (move.promotion) alg = '$alg${variant.pieces[move.promoPiece!].symbol.toLowerCase()}';
    return alg;
  }

  String toSan(Move move, [List<Move>? moves]) {
    if (move.castling) {
      return ([CASTLING_K, CASTLING_BK].contains(move.castlingDir)) ? "O-O" : "O-O-O";
    }
    int piece = board[move.from].piece;
    PieceDefinition pieceDef = variant.pieces[piece];

    String san = '';
    String disambiguator = getDisambiguator(move, moves);
    if (pieceDef.type.noSanSymbol) {
      if (move.capture) san = squareName(move.from, size)[0];
    } else
      san = pieceDef.symbol;
    san = '$san$disambiguator';
    if (move.capture) san = '${san}x';
    san = '$san${squareName(move.to, size)}';

    if (move.promotion) san = '$san=${variant.pieces[move.promoPiece!].symbol}';

    makeMove(move);
    if (inCheck) {
      san = '$san${checkmate ? '#' : '+'}';
    }
    undo();
    return san;
  }

  // To be used in cases where, given a piece and a destination, there is more than
  // one possible move. For example, in 'Nbxa4', this function provides the 'b'.
  String getDisambiguator(Move move, [List<Move>? moves]) {
    // provide a list of moves to make this more efficient
    if (moves == null) moves = generateLegalMoves();

    int _piece = board[move.from].piece;
    int _file = file(move.from, size);
    bool ambiguity = false;
    bool needRank = false;
    bool needFile = false;
    for (Move m in moves) {
      if (m.from == move.from) continue;
      if (m.to != move.to) continue;
      if (_piece != board[m.from].piece) continue;
      ambiguity = true;
      if (file(m.from, size) == _file) {
        needRank = true;
      } else {
        needFile = true;
      }
      if (needRank && needFile) break;
    }

    String disambiguator = '';
    if (ambiguity) {
      String _squareName = squareName(move.from, size);
      if (needFile) disambiguator = _squareName[0];
      if (needRank) disambiguator = '$disambiguator${_squareName[1]}';
    }
    return disambiguator;
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
    String _pgn = '';
    for (int i = 0; i < moves.length; i++) {
      if (i == 0 || turn == WHITE) _pgn = '$_pgn${firstMove + i ~/ 2}. ';
      if (i == 0 && turn == BLACK) _pgn = '$_pgn..';
      _pgn = '$_pgn${moves[i]} ';
      turn = turn.opponent;
    }
    return _pgn;
  }

  int perft(int depth) {
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
}

main(List<String> args) {
  // Game g = Game(variant: Variant.standard());

  // for (int i = 0; i < 599; i++) {
  //   print(g.ascii());
  //   if (g.state.move != null) print(g.state.move!.algebraic(g.size));
  //   print(g.fen);
  //   if (g.gameOver) {
  //     print('game over');
  //     break;
  //   }
  //   g.makeRandomMove();
  // }

  // print(g.ascii());
  // print("MOVE ${g.state.fullMoves}");
  // print(g.state.move!.algebraic(g.size));
  // print(g.fen);
  // //print(g.sanMoves());
  // print(g.pgn());
  // print('checkmate: ${g.checkmate}');
  // print('draw: ${g.inDraw}');

  // //String f = 'r1bqkb2/p1pppppr/1p3n2/4n2p/7P/2P1PP2/PP1PK1P1/RNBQ1BNR w q - 1 7';
  // //String f = '3k4/3r4/8/8/8/8/3K4/8 w - - 0 1';
  // String f = '7k/B7/3R1pnp/7N/PpP5/1P4P1/1KR2p2/1N2q3 w - - 2 80';
  Squares g =
      Squares(variant: Variant.standard(), fen: 'rnbqkbnr/pp1pppp1/7p/2pP4/8/8/PPP1PPPP/RNBQKBNR w KQkq c6 0 3');
  // print('turn: ${g.state.turn}');
  // print(g.inCheck);
  // print(g.ascii());
  List<Move> moves = g.generateLegalMoves();
  Move m = g.getMove('d5c6')!;
  print(m.algebraic());
  print(g.toSan(m));
  print(m.enPassant);
  Square fromSq = g.board[m.from];
  int colour = fromSq.colour;
  int captureSq = m.to + PLAYER_DIRECTION[colour.opponent] * g.size.h * 2;
  print(squareName(captureSq, g.size));
  g.makeMove(m);
  print(g.ascii());
  print(g.fen);
  g.undo();
  print(g.ascii());
  print(g.fen);
  // // List<Move> moves = g.generatePlayerMoves(g.state.turn, MoveGenOptions.normal());
  // //print(g.ascii());
  // // Move m = moves[0];
  // // print(g.toAlgebraic(m));
  // // print(g.toSan(m));
  // // print(moves.map((e) => g.toAlgebraic(e)).toList());
  // print(moves.map((e) => g.toSan(e, moves)).toList());
  // // g.makeMove(moves.first);
  // // print(g.inCheck);
  // // print(g.ascii());
  // // print(g.fen);
  // // // // Move? m = g.getMove('d1d3');
  // // // // String s = g.toSan(m!);
  // // // // print(s);
  // // g.makeMove(m);
  // // print(g.ascii());
}
