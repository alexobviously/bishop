import 'dart:math';

import 'castling_rights.dart';
import 'constants.dart';
import 'first_where_extension.dart';
import 'move.dart';
import 'move_definition.dart';
import 'piece_type.dart';
import 'square.dart';
import 'state.dart';
import 'utils.dart';
import 'variant.dart';

class Game {
  final Variant variant;
  late List<int> board;
  late String startPosition;
  List<State> history = [];
  State get state => history.last;
  bool get canUndo => history.length > 1;

  int? castlingTargetK;
  int? castlingTargetQ;
  int? royalFile;
  late MoveGenOptions royalCaptureOptions;

  BoardSize get size => variant.boardSize;

  Game({required this.variant, String? fen}) {
    startPosition = fen ?? (variant.startPosBuilder != null ? variant.startPosBuilder!() : variant.startPosition);
    buildBoard();
    if (variant.castling) setupCastling();
    royalCaptureOptions = MoveGenOptions.pieceCaptures(variant.royalPiece);
  }
  void setupCastling() {
    for (int i = 0; i < variant.boardSize.h; i++) {
      if (board[i].piece == variant.royalPiece) royalFile = i;
      if (board[i].piece == variant.castlingPiece) {
        if (castlingTargetQ == null) {
          castlingTargetQ = i;
        } else {
          castlingTargetK = i;
        }
      }
    }
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
        Colour colour = c == symbol ? WHITE : BLACK;
        Square piece = makePiece(pieceLookup[symbol]!, colour);
        board[sq] = piece;
        sq++;
      }
    }

    int turn = _turn == 'w' ? WHITE : BLACK;
    int? ep = _ep == '-' ? null : squareNumber(_ep, variant.boardSize);
    int castling = castlingRights(_castling);
    State _state = State(
      turn: turn,
      halfMoves: int.parse(_halfMoves),
      fullMoves: int.parse(_fullMoves),
      epSquare: ep,
      castlingRights: castling,
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
    // Generate normal moves
    for (MoveDefinition md in pieceType.moves) {
      if (!md.capture && !options.quiet) continue;
      if (!md.quiet && !options.captures) continue;
      if (md.firstOnly && !variant.firstMoveRanks[colour].contains(fromRank)) continue;
      int range = md.range == 0 ? variant.boardSize.maxDim : md.range;
      for (int i = 0; i < range; i++) {
        int to = square + md.normalised * (i + 1) * dirMult;
        if (!onBoard(to, variant.boardSize)) break;
        if (md.lame) {
          int _from = square + md.normalised * i * dirMult;
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
        }

        if (target.isEmpty) {
          // TODO: prioritise ep? for moves that could be both ep and quiet
          if (md.quiet) {
            if (!options.quiet) continue;
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
      bool queenside = colour == WHITE ? state.castlingRights.bq : state.castlingRights.bq;
      int royalRank = rank(from, variant.boardSize);

      // TODO: if isAttacked(from) break
      for (int i = 0; i < 2; i++) {
        bool sideCondition = i == 0 ? kingside : queenside;
        if (!sideCondition) continue;
        int targetFile = i == 0 ? variant.castlingKingsideFile! : variant.castlingQueensideFile!;
        int targetSq = getSquare(targetFile, royalRank, variant.boardSize);
        int rookFile = i == 0 ? castlingTargetK! : castlingTargetQ!;
        int rookSq = getSquare(rookFile, royalRank, variant.boardSize);
        if (board[targetSq].isNotEmpty &&
            (board[targetSq].piece != variant.castlingPiece || board[targetSq].colour != colour)) continue;
        int numMidSqs = (targetFile - royalFile!).abs();
        bool _valid = true;
        for (int j = 1; j < numMidSqs; j++) {
          int midFile = royalFile! + (i == 0 ? -j : j);
          int midSq = getSquare(midFile, royalRank, variant.boardSize);
          if (board[midSq].isNotEmpty) {
            _valid = false;
            break;
          }
          // TODO: if isAttacked(midSq) break
        }
        if (_valid) {
          int castlingDir = i == 0 ? CASTLING_K : CASTLING_Q;
          Move m = Move(from: from, to: rookSq, castlingDir: castlingDir);
          moves.add(m);
        }
      }
    }

    if (options.legal) {
      List<Move> _remove = [];
      for (Move m in moves) {
        makeMove(m);
        if (hasKingCapture()) _remove.add(m);
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
      //print('promotion move: ${}');
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

    // TODO: en passant & set en passant
    if (move.castling) {
      bool kingside = move.castlingDir == CASTLING_K;
      int royalRank = rank(fromSq, size);
      int castlingFile = kingside ? variant.castlingKingsideFile! : variant.castlingQueensideFile!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = getSquare(rookFile, royalRank, size);
      int kingSq = getSquare(castlingFile, royalRank, size);
      board[kingSq] = fromSq;
      board[rookSq] = toSq;
      _castlingRights = _castlingRights.remove(colour);
    } else if (fromPiece.royal) {
      // king moved
      _castlingRights = _castlingRights.remove(colour);
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
    );
    history.add(_state);
    return true;
  }

  Move? undo() {
    if (history.length == 1) return null;
    State _state = history.removeLast();
    Move move = _state.move!;

    int fromSq = board[move.from];
    int toSq = board[move.to];

    if (move.castling) {
      bool kingside = move.castlingDir == CASTLING_K;
      int royalRank = rank(fromSq, size);
      int castlingFile = kingside ? variant.castlingKingsideFile! : variant.castlingQueensideFile!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = getSquare(rookFile, royalRank, size);
      int kingSq = getSquare(castlingFile, royalRank, size);
      int _rook = board[rookSq];
      int _king = board[kingSq];
      board[kingSq] = EMPTY;
      board[rookSq] = EMPTY;
      board[move.from] = _king;
      board[move.to] = _rook;
    } else {
      if (move.promotion) {
        board[move.from] = makePiece(move.promoSource!, state.turn);
      } else {
        board[move.from] = toSq;
      }
      // TODO: en passant
      if (move.capture) {
        board[move.to] = move.capturedPiece!;
      } else {
        board[move.to] = EMPTY;
      }
    }

    return move;
  }

  bool makeRandomMove() {
    List<Move> moves = generateLegalMoves();
    int i = Random().nextInt(moves.length);
    return makeMove(moves[i]);
  }

  bool hasKingCapture() {
    List<Move> moves = generatePlayerMoves(state.turn, MoveGenOptions.pieceCaptures(variant.royalPiece));
    return moves.isNotEmpty;
  }

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

  String toSan(Move move) {
    if (move.castling) {
      return ([CASTLING_K, CASTLING_BK].contains(move.castlingDir)) ? "O-O" : "O-O-O";
    }
    int piece = board[move.from].piece;
    PieceDefinition pieceDef = variant.pieces[piece];

    String san = '';
    if (pieceDef.type.noSanSymbol) {
      if (move.capture) san = squareName(move.from, size)[0];
    } else
      san = pieceDef.symbol;
    if (move.capture) san = '${san}x';
    san = '$san${squareName(move.to, size)}';

    if (move.promotion) san = '$san=${variant.pieces[move.promoPiece!].symbol}';
    // todo: check & checkmate
    return san;
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
}

class MoveGenOptions {
  final bool captures;
  final bool quiet;
  final bool castling;
  final bool legal;
  final int? pieceType;

  bool get onlyPiece => pieceType != null;

  const MoveGenOptions({
    required this.captures,
    required this.quiet,
    required this.castling,
    required this.legal,
    this.pieceType,
  });
  factory MoveGenOptions.normal() => MoveGenOptions(
        captures: true,
        quiet: true,
        castling: true,
        legal: true,
      );
  factory MoveGenOptions.onlyQuiet() => MoveGenOptions(
        captures: false,
        quiet: true,
        castling: true,
        legal: true,
      );
  factory MoveGenOptions.onlyCaptures() => MoveGenOptions(
        captures: true,
        quiet: false,
        castling: false,
        legal: true,
      );
  factory MoveGenOptions.pieceCaptures(int pieceType) => MoveGenOptions(
        captures: true,
        quiet: false,
        castling: false,
        legal: false,
        pieceType: pieceType,
      );
}

main(List<String> args) {
  // Game g = Game(variant: Variant.standard());

  // for (int i = 0; i < 57; i++) {
  //   print(g.ascii());
  //   if (g.state.move != null) print(g.state.move!.algebraic(g.size));
  //   print(g.fen);
  //   g.makeRandomMove();
  // }

  // print(g.ascii());
  // print(g.state.move!.algebraic(g.size));
  // print(g.fen);
  // print(g.sanMoves());
  // print(g.pgn());

  String f = '3qk1r1/r3b1pP/b2p4/1pp2p2/1nP1p2P/N3P3/1B1PPR2/R2QKBN1 w - - 3 22';
  Game g = Game(variant: Variant.standard(), fen: f);
  print(g.ascii());
  List<Move> moves = g.generateLegalMoves();
  Move m = moves[0];
  print(g.toAlgebraic(m));
  print(g.toSan(m));
  //print(moves.map((e) => g.toAlgebraic(e)).toList());
  //print(moves.map((e) => g.toSan(e)).toList());
  // Move? m = g.getMove('d1d3');
  // String s = g.toSan(m!);
  // print(s);
  g.makeMove(m);
  print(g.ascii());
}
