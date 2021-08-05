import 'dart:math';

import 'package:squares/squares.dart';

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
  late Zobrist zobrist;
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
    zobrist = Zobrist(variant, 7363661891);
    startPosition = fen ?? (variant.startPosBuilder != null ? variant.startPosBuilder!() : variant.startPosition);
    setup();
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
          int _piece = board[r + j].type;
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

  void setup() {
    Map<String, int> pieceLookup = {};
    for (int i = 0; i < variant.pieces.length; i++) {
      pieceLookup[variant.pieces[i].symbol] = i;
    }

    board = List.filled(variant.boardSize.numSquares * 2, 0);
    List<String> sections = startPosition.split(' ');

    // Parse hands for variants with drops

    List<List<int>>? _hands;
    if (variant.hands) {
      _hands = [[], []];
      RegExp handRegex = RegExp(r'\[([A-Za-z]+)\]');
      RegExpMatch? handMatch = handRegex.firstMatch(sections[0]);
      if (handMatch != null) {
        sections[0] = sections[0].substring(0, handMatch.start);
        String hand = handMatch.group(1)!;
        _hands = [[], []];
        for (String c in hand.split('')) {
          String _upper = c.toUpperCase();
          if (pieceLookup.containsKey(_upper)) {
            bool white = c == _upper;
            _hands[white ? 0 : 1].add(pieceLookup[_upper]!);
          }
        }
      }
    }

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
      if (c == '~') {
        board[sq - 1] = board[sq - 1] + FLAG_PROMO;
        continue;
      }
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
      hands: _hands,
    );
    _state.hash = zobrist.compute(_state, board);
    zobrist.incrementHash(_state.hash);
    history.add(_state);
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
    if (variant.hands && options.quiet && !options.onlyPiece) moves.addAll(generateDrops(player));
    return moves;
  }

  List<Move> generateDrops(int colour) {
    List<Move> drops = [];
    Set<int> _hand = state.hands![colour].toSet();
    for (int i = 0; i < size.numIndices; i++) {
      if (!onBoard(i, size)) continue;
      if (board[i].isNotEmpty) continue;
      for (int p in _hand) {
        int _rank = rank(i, size);
        bool onPromoRank = colour == WHITE ? _rank == size.maxRank : _rank == RANK_1;
        if (onPromoRank && variant.pieces[p].type.promotable) continue;
        int dropPiece = p;
        // TODO: support more than one promo piece in this case
        if (p.hasFlag(FLAG_PROMO)) dropPiece = variant.promotionPieces[0];
        Move m = Move.drop(to: i, dropPiece: dropPiece);
        drops.add(m);
      }
    }
    return drops;
  }

  List<Move> generatePieceMoves(int square, [MoveGenOptions? options]) {
    if (options == null) options = MoveGenOptions.normal();
    Square piece = board[square];
    if (piece.isEmpty) return [];
    Colour colour = piece.colour;
    int dirMult = PLAYER_DIRECTION[piece.colour];
    List<Move> moves = [];
    PieceType pieceType = variant.pieces[piece.type].type;
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
            if (options.onlyPiece && target.type != options.pieceType) break;
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
    if (variant.castling && options.castling && pieceType.royal && !inCheck) {
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
            (board[targetSq].type != variant.castlingPiece || board[targetSq].colour != colour)) continue;
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
      Move m = base.copyWith(promoSource: board[base.from].type, promoPiece: p);
      moves.add(m);
    }
    return moves;
  }

  bool makeMove(Move move, [bool debug = false]) {
    if (debug) print('${move.algebraic(size)} ${squareName(move.to)}');
    //if (!onBoard(move.from)) print(move.from);

    if ((move.from != HAND && !onBoard(move.from, size)) || !onBoard(move.to, size)) return false;
    int hash = state.hash;
    hash ^= zobrist.table[zobrist.TURN][Zobrist.META];
    List<Hand>? _hands =
        state.hands != null ? List.generate(state.hands!.length, (i) => List.from(state.hands![i])) : null;
    // TODO: more validation?
    Square fromSq = move.from >= BOARD_START ? board[move.from] : EMPTY;
    if (debug) print(fromSq);
    Square toSq = board[move.to];
    PieceType fromPiece = variant.pieces[fromSq.type].type;
    if (fromSq != EMPTY && fromSq.colour != state.turn) return false;
    int colour = turn;
    // Remove the moved piece, if this wasn't a drop
    if (move.from >= BOARD_START) {
      hash ^= zobrist.table[move.from][fromSq.piece];
      board[move.from] = EMPTY;
    }

    if (!move.castling && !move.promotion) {
      if (debug) print('dropping ${move.dropPiece}');
      // Move the piece to the new square
      int putPiece = move.from >= BOARD_START ? fromSq : makePiece(move.dropPiece!, colour);
      hash ^= zobrist.table[move.to][putPiece.piece];
      board[move.to] = putPiece;
      //if (move.from == HAND) print('$colour ${move.dropPiece!}');
      if (move.from == HAND) _hands![colour].remove(move.dropPiece!);
    } else if (move.promotion) {
      // Place the promoted piece
      board[move.to] = makePiece(move.promoPiece!, state.turn, FLAG_PROMO);
      hash ^= zobrist.table[move.to][board[move.to].piece];
    }
    int _halfMoves = state.halfMoves;
    if (move.capture || fromPiece.promotable)
      _halfMoves = 0;
    else
      _halfMoves++;
    int _castlingRights = state.castlingRights;
    List<int> royalSquares = List.from(state.royalSquares);

    if (move.enPassant) {
      // Remove the captured ep piece
      int captureSq = move.to + PLAYER_DIRECTION[colour.opponent] * size.north;
      hash ^= zobrist.table[captureSq][board[captureSq].piece];
      board[captureSq] = EMPTY;
    }

    int? epSquare;
    if (move.setEnPassant) {
      // Set the new ep square
      int dir = (move.to - move.from) ~/ 2;
      epSquare = move.from + dir;
      hash ^= zobrist.table[epSquare][Zobrist.META];
    } else {
      epSquare = null;
    }
    if (state.epSquare != null) {
      // XOR the old ep square away from the hash
      hash ^= zobrist.table[state.epSquare!][Zobrist.META];
    }

    if (move.castling) {
      bool kingside = move.castlingDir == CASTLING_K;
      int royalRank = rank(move.from, size);
      int castlingFile = kingside ? variant.castlingOptions.kTarget! : variant.castlingOptions.qTarget!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = getSquare(rookFile, royalRank, size);
      int kingSq = getSquare(castlingFile, royalRank, size);
      int rook = board[move.castlingPieceSquare!];
      hash ^= zobrist.table[move.castlingPieceSquare!][rook.piece];
      if (board[kingSq].isNotEmpty) hash ^= zobrist.table[kingSq][board[kingSq].piece];
      hash ^= zobrist.table[kingSq][fromSq.piece];
      if (board[rookSq].isNotEmpty) hash ^= zobrist.table[rookSq][board[rookSq].piece];
      hash ^= zobrist.table[rookSq][rook.piece];
      board[move.castlingPieceSquare!] = EMPTY;
      board[kingSq] = fromSq;
      board[rookSq] = rook;
      _castlingRights = _castlingRights.remove(colour);
      // refactor conditions?
      hash ^= zobrist.table[zobrist.CASTLING][state.castlingRights];
      hash ^= zobrist.table[zobrist.CASTLING][_castlingRights];
      royalSquares[colour] = kingSq;
    } else if (fromPiece.royal) {
      // king moved
      _castlingRights = _castlingRights.remove(colour);
      hash ^= zobrist.table[zobrist.CASTLING][state.castlingRights];
      hash ^= zobrist.table[zobrist.CASTLING][_castlingRights];
      royalSquares[colour] = move.to;
    } else if (fromSq.type == variant.castlingPiece) {
      // rook moved
      int fromFile = file(move.from, size);
      int ks = colour == WHITE ? CASTLING_K : CASTLING_BK;
      int qs = colour == WHITE ? CASTLING_Q : CASTLING_BQ;
      if (fromFile == castlingTargetK && _castlingRights.hasRight(ks)) {
        _castlingRights = _castlingRights.flip(ks);
        hash ^= zobrist.table[zobrist.CASTLING][state.castlingRights];
        hash ^= zobrist.table[zobrist.CASTLING][_castlingRights];
      } else if (fromFile == castlingTargetQ && _castlingRights.hasRight(qs)) {
        _castlingRights = _castlingRights.flip(qs);
        hash ^= zobrist.table[zobrist.CASTLING][state.castlingRights];
        hash ^= zobrist.table[zobrist.CASTLING][_castlingRights];
      }
    } else if (move.capture && move.capturedPiece!.type == variant.castlingPiece) {
      // rook captured
      int toFile = file(move.to, size);
      int opponent = colour.opponent;
      int ks = opponent == WHITE ? CASTLING_K : CASTLING_BK;
      int qs = opponent == WHITE ? CASTLING_Q : CASTLING_BQ;
      if (toFile == castlingTargetK && _castlingRights.hasRight(ks)) {
        _castlingRights = _castlingRights.flip(ks);
        hash ^= zobrist.table[zobrist.CASTLING][state.castlingRights];
        hash ^= zobrist.table[zobrist.CASTLING][_castlingRights];
      } else if (toFile == castlingTargetQ && _castlingRights.hasRight(qs)) {
        _castlingRights = _castlingRights.flip(qs);
        hash ^= zobrist.table[zobrist.CASTLING][state.castlingRights];
        hash ^= zobrist.table[zobrist.CASTLING][_castlingRights];
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
      hash: hash,
      hands: _hands,
    );
    history.add(_state);
    zobrist.incrementHash(hash);
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
        if (move.from >= BOARD_START) board[move.from] = toSq;
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

    zobrist.decrementHash(_state.hash);
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
  bool get repetition => variant.repetitionDraw != null ? hashHits >= variant.repetitionDraw! : false;
  bool get halfMoveRule => variant.halfMoveDraw != null && state.halfMoves >= variant.halfMoveDraw!;
  bool get inDraw => stalemate || insufficientMaterial || repetition || halfMoveRule;
  bool get gameOver => checkmate || inDraw;

  int get hashHits => zobrist.hashHits(state.hash);

  Move? getMove(String algebraic) {
    List<Move> moves = generateLegalMoves();
    Move? match = moves.firstWhereOrNull((m) => toAlgebraic(m) == algebraic);
    return match;
  }

  String toAlgebraic(Move move) {
    String alg = move.algebraic(size);
    if (move.promotion) alg = '$alg${variant.pieces[move.promoPiece!].symbol.toLowerCase()}';
    if (move.from == HAND) alg = '${variant.pieces[move.dropPiece!].symbol.toLowerCase()}$alg';
    return alg;
  }

  String toSan(Move move, [List<Move>? moves]) {
    String _alg = move.algebraic(size);
    if (move.castling) {
      return ([CASTLING_K, CASTLING_BK].contains(move.castlingDir)) ? "O-O" : "O-O-O";
    }

    String san = '';
    if (move.from == HAND) {
      PieceDefinition _pieceDef = variant.pieces[move.dropPiece!];
      san = move.algebraic(size);
      if (!_pieceDef.type.noSanSymbol) san = '${_pieceDef.symbol.toUpperCase()}$san';
    } else {
      int piece = board[move.from].type;
      PieceDefinition pieceDef = variant.pieces[piece];
      String disambiguator = getDisambiguator(move, moves);
      if (pieceDef.type.noSanSymbol) {
        if (move.capture) san = squareName(move.from, size)[0];
      } else
        san = pieceDef.symbol;
      san = '$san$disambiguator';
      if (move.capture) san = '${san}x';
      san = '$san${squareName(move.to, size)}';

      if (move.promotion) san = '$san=${variant.pieces[move.promoPiece!].symbol}';
    }
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

    int _piece = board[move.from].type;
    int _file = file(move.from, size);
    bool ambiguity = false;
    bool needRank = false;
    bool needFile = false;
    for (Move m in moves) {
      if (m.drop) continue;
      if (m.from == move.from) continue;
      if (m.to != move.to) continue;
      if (_piece != board[m.from].type) continue;
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
          String char = variant.pieces[sq.type].char(sq.colour);
          if (variant.outputOptions.showPromoted && sq.hasFlag(FLAG_PROMO)) char += '~';
          _fen = '$_fen$char';
        }
      }
      if (empty > 0) addEmptySquares();
      if (i < variant.boardSize.v - 1) _fen = '$_fen/';
    }
    if (variant.hands) {
      String whiteHand = state.hands![WHITE].map((p) => variant.pieces[p].symbol.toUpperCase()).join('');
      String blackHand = state.hands![BLACK].map((p) => variant.pieces[p].symbol.toLowerCase()).join('');
      _fen = '$_fen[$whiteHand$blackHand]';
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
        String char = variant.pieces[sq.type].char(sq.colour);
        if (unicode && UNICODE_PIECES.containsKey(char)) char = UNICODE_PIECES[char]!;
        output = '$output $char ';
      }
      output = '$output|\n';
    }
    output = '$output$border';
    return output;
  }

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

  Map<String, int> divide(int depth) {
    List<Move> moves = generateLegalMoves();
    Map<String, int> perfts = {};
    for (Move m in moves) {
      makeMove(m);
      perfts[toAlgebraic(m)] = perft(depth - 1);
      undo();
    }
    return perfts;
  }
}

main(List<String> args) {
  Squares game = Squares(
      variant: Variant.crazyhouse(), fen: 'rnb1k1nr/pppq1pR1/3b4/8/8/N7/PPPPPP2/R1BQKBq~1[Ppppnr] b Qkq - 0 10');
  print(game.state.hands);
  print(game.fen);
  List<Move> moves = game.generateLegalMoves();
  print(moves.length);
  print(moves.map((e) => game.toSan(e)).toList());
  Move? m = game.getMove('p@b4');
  //print(m);
  print(m?.dropPiece);
  print(game.ascii());
  print(game.fen);
  game.makeMove(m!, true);
  print(game.ascii());
  print(game.fen);
  game.undo();
  print(game.ascii());
  print(game.fen);
}
