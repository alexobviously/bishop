import 'dart:math';

import 'package:bishop/bishop.dart';

import 'castling_rights.dart';

/// Tracks the state of the game, handles move generation and validation, and generates output.
class Game {
  /// The variant that specifies the gameplay rules for this game.
  final Variant variant;

  /// A random number generator seed.
  /// Used by the Zobrist hash table.
  final int seed;
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
  List<String> castlingFileSymbols = ['K', 'Q', 'k', 'q'];
  late MoveGenOptions royalCaptureOptions;

  BoardSize get size => variant.boardSize;

  @override
  String toString() => 'Game(${variant.name}, $fen)';

  Game({required this.variant, String? fen, this.seed = DEFAULT_SEED}) {
    setup(fen);
  }

  void setup([String? fen]) {
    startPosition = fen ?? (variant.startPosBuilder != null ? variant.startPosBuilder!() : variant.startPosition);
    loadFen(startPosition);
    royalCaptureOptions = MoveGenOptions.pieceCaptures(variant.royalPiece);
  }

  int setupCastling(String castlingString, List<int> royalSquares) {
    if (castlingString == '-') {
      return 0;
    }
    if (!isAlpha(castlingString) || (castlingString.length > 4 && !variant.outputOptions.virginFiles))
      throw ('Invalid castling string');
    CastlingRights cr = 0;
    for (String c in castlingString.split('')) {
      // there is probably a better way to do all of this
      bool white = c == c.toUpperCase();
      royalFile = file(royalSquares[white ? 0 : 1], size);
      if (CASTLING_SYMBOLS.containsKey(c)) {
        cr += CASTLING_SYMBOLS[c]!;
      } else {
        int _file = fileFromSymbol(c);
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
      // Actually if these are null then we should never need the file symbol,
      // but let's set it to something anyway.
      String k = castlingTargetK != null ? fileSymbol(castlingTargetK!) : 'k';
      String q = castlingTargetQ != null ? fileSymbol(castlingTargetQ!) : 'q';
      castlingFileSymbols = [k.toUpperCase(), q.toUpperCase(), k, q];
    }
    return cr;
  }

  /// Load a position from a FEN string.
  /// If [strict] is enabled, a full string must be provided, including turn, ep square, etc.
  void loadFen(String fen, [bool strict = false]) {
    zobrist = Zobrist(variant, seed);
    Map<String, int> pieceLookup = {}; // TODO: replace with variant.pieceLookup?
    for (int i = 0; i < variant.pieces.length; i++) {
      pieceLookup[variant.pieces[i].symbol] = i;
    }

    board = List.filled(variant.boardSize.numSquares * 2, 0);
    List<String> sections = fen.split(' ');

    // Parse hands for variants with drops

    List<List<int>>? _hands;
    List<List<int>>? _gates;
    List<int> _pieces = List.filled((variant.pieces.length + 1) * 2, 0);
    if (variant.hands || variant.gatingMode == GatingMode.FLEX) {
      List<List<int>> _temp = [[], []];
      RegExp handRegex = RegExp(r'\[([A-Za-z]+)\]');
      RegExpMatch? handMatch = handRegex.firstMatch(sections[0]);
      if (handMatch != null) {
        sections[0] = sections[0].substring(0, handMatch.start);
        String hand = handMatch.group(1)!;
        _temp = [[], []];
        for (String c in hand.split('')) {
          String _upper = c.toUpperCase();
          if (pieceLookup.containsKey(_upper)) {
            bool white = c == _upper;
            int _piece = pieceLookup[_upper]!;
            _temp[white ? 0 : 1].add(_piece);
            _pieces[makePiece(_piece, white ? 0 : 1)]++;
          }
        }
      }
      if (variant.hands)
        _hands = _temp;
      else if (variant.gatingMode == GatingMode.FLEX) _gates = _temp;
    }

    List<String> _board = sections[0].split('');
    if (_board.where((e) => e == '/').length !=
        (variant.boardSize.v - 1 + (variant.gatingMode == GatingMode.FIXED ? 2 : 0)))
      throw ("Invalid FEN: wrong number of ranks");
    String _turn = (strict || sections.length > 1) ? sections[1] : 'w';
    if (!(['w', 'b'].contains(_turn))) throw ("Invalid FEN: colour should be 'w' or 'b'");
    String _castling = (strict || sections.length > 2) ? sections[2] : 'KQkq'; // TODO: get default castling for variant
    String _ep = (strict || sections.length > 3) ? sections[3] : '-';
    String _halfMoves = (strict || sections.length > 4) ? sections[4] : '0';
    String _fullMoves = (strict || sections.length > 5) ? sections[5] : '1';

    // Process fixed gates, for variants like musketeer.
    // gate/rbn...BNR/GATE
    if (variant.gatingMode == GatingMode.FIXED) {
      _gates = [List.filled(size.h, 0), List.filled(size.h, 0)];
      // extract the first and last segments
      List<String> _fileStrings = sections[0].split('/');
      List<String> _gateStrings = [_fileStrings.removeAt(0), _fileStrings.removeAt(_fileStrings.length - 1)];
      _board = _fileStrings.join('/').split(''); // rebuild
      for (int i = 1; i < 2; i++) {
        int _sq = 0;
        int _empty = 0;
        for (String c in _gateStrings[i].split('')) {
          String symbol = c.toUpperCase();
          if (isNumeric(c)) {
            _empty = (_empty * 10) + int.parse(c);
            if (_sq + _empty - 1 > size.h) {
              // todo: this might be wrong
              throw ('Invalid FEN: gate ($i) overflow [$c, ${_sq + _empty - 1}]');
            }
          } else {
            _sq += _empty;
            _empty = 0;
          }

          if (pieceLookup.containsKey(symbol)) {
            // it's a piece
            int _piece = pieceLookup[symbol]!;
            _gates[1 - i][_sq] = _piece;
            _pieces[makePiece(_piece, 1 - i)]++;
            _sq++;
          }
        }
      }
    }

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
        if (!onBoard(sq + emptySquares - 1, size)) throw ('Invalid FEN: rank overflow [$c, ${sq + emptySquares - 1}]');
      } else {
        sq += emptySquares;
        emptySquares = 0;
      }
      if (c == '/') sq += variant.boardSize.h;
      if (pieceLookup.containsKey(symbol)) {
        if (!onBoard(sq, size)) throw ('Invalid FEN: rank overflow [$symbol, $sq]');
        // it's a piece
        int pieceIndex = pieceLookup[symbol]!;
        Colour colour = c == symbol ? WHITE : BLACK;
        Square piece = makePiece(pieceIndex, colour);
        board[sq] = piece;
        _pieces[piece]++;
        if (variant.pieces[pieceIndex].type.royal) {
          royalSquares[colour] = sq;
        }
        sq++;
      }
    }

    List<List<int>> _virginFiles = [[], []];
    if (variant.outputOptions.virginFiles) {
      String __castling = _castling; // so we can modify _castling in place
      for (int i = 0; i < __castling.length; i++) {
        String _char = __castling[i];
        String _lower = _char.toLowerCase();
        int _colour = _lower == _char ? BLACK : WHITE;
        int _file = fileFromSymbol(_lower);
        if (_file < 0 || _file >= size.h) continue;

        if (_virginFiles[_colour].contains(_file)) continue;
        _virginFiles[_colour].add(_file);
        _castling = _castling.replaceFirst(_char, '');
      }
    } else {
      List<int> _vf = List.generate(size.h, (i) => i);
      _virginFiles = [_vf, List.from(_vf)]; // just in case
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
      virginFiles: _virginFiles,
      hands: _hands,
      gates: _gates,
      pieces: _pieces,
    );
    _state.hash = zobrist.compute(_state, board);
    zobrist.incrementHash(_state.hash);
    history.add(_state);
  }

  /// Generates all legal moves for the player whose turn it is.
  List<Move> generateLegalMoves() => generatePlayerMoves(state.turn, MoveGenOptions.normal());

  /// Generates all possible moves that could be played by the other player next turn,
  /// not respecting blocking pieces or checks.
  List<Move> generatePremoves() => generatePlayerMoves(state.turn.opponent, MoveGenOptions.premoves());

  /// Generates all moves for the specified [colour]. See [MoveGenOptions] for possibilities.
  List<Move> generatePlayerMoves(int colour, [MoveGenOptions? options]) {
    if (options == null) options = MoveGenOptions.normal();
    List<Move> moves = [];
    for (int i = 0; i < board.length; i++) {
      Square target = board[i];
      if (target.isNotEmpty && target.colour == colour) {
        List<Move> pieceMoves = generatePieceMoves(i, options);
        moves.addAll(pieceMoves);
      }
    }
    if (variant.hands && options.quiet && !options.onlyPiece) moves.addAll(generateDrops(colour));
    return moves;
  }

  /// Generates drop moves for [colour]. Used for variants with hands, e.g. Crazyhouse.
  List<Move> generateDrops(int colour, [bool legal = true]) {
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

    if (legal) {
      List<Move> _remove = [];
      for (Move m in drops) {
        makeMove(m);
        if (kingAttacked(colour)) _remove.add(m);
        undo();
      }
      _remove.forEach((m) => drops.remove(m));
    }
    return drops;
  }

  /// Generates all moves for the piece on [square] in accordance with [options].
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
          if (board[blockSq].isNotEmpty && !options.ignorePieces) break;
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
          if (variant.gating) {
            int _rank = rank(m.from, size);
            if ((_rank == RANK_1 && colour == WHITE) || (_rank == size.maxRank && colour == BLACK)) {
              moves.addAll(generateGatingMoves(m));
            }
          }
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
          } else if (variant.enPassant &&
              md.enPassant &&
              (state.epSquare == to || options.ignorePieces) &&
              options.captures) {
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
            if (!options.ignorePieces) break;
            Move m = Move(from: from, to: to);
            addMove(m);
          }
        } else if (target.colour == colour) {
          if (!options.ignorePieces) break;
          Move m = Move(from: from, to: to);
          addMove(m);
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
          if (!options.ignorePieces) break;
        }
      }
    }

    // Generate castling
    if (variant.castling && options.castling && pieceType.royal && !inCheck) {
      bool kingside = colour == WHITE ? state.castlingRights.wk : state.castlingRights.bk;
      bool queenside = colour == WHITE ? state.castlingRights.wq : state.castlingRights.bq;
      int royalRank = rank(from, variant.boardSize);

      for (int i = 0; i < 2; i++) {
        bool sideCondition =
            i == 0 ? (kingside && variant.castlingOptions.kingside) : (queenside && variant.castlingOptions.queenside);
        if (!sideCondition) continue;
        // Conditions for castling:
        // * All squares between the king's start and end (inclusive) must be free and not attacked
        // * Obviously the king's start is occupied by the king, but it can't be in check
        // * The square the rook lands on must be free (but can be attacked)
        int targetFile = i == 0 ? variant.castlingOptions.kTarget! : variant.castlingOptions.qTarget!;
        int targetSq = getSquare(targetFile, royalRank, size); // where the king lands
        int rookFile = i == 0 ? castlingTargetK! : castlingTargetQ!;
        int rookSq = getSquare(rookFile, royalRank, size); // where the rook starts
        int rookTargetFile = i == 0 ? targetFile - 1 : targetFile + 1;
        int rookTargetSq = getSquare(rookTargetFile, royalRank, size); // where the rook lands
        // Check rook target square is empty (or occupied by the rook/king already)
        if (board[rookTargetSq].isNotEmpty && rookTargetSq != rookSq && rookTargetSq != from) continue;
        // Check king target square is empty (or occupied by the castling rook)
        if (board[targetSq].isNotEmpty && targetSq != rookSq) continue;
        int numMidSqs = (targetFile - royalFile!).abs();
        bool _valid = true;
        if (!options.ignorePieces) {
          for (int j = 1; j <= numMidSqs; j++) {
            int midFile = royalFile! + (i == 0 ? j : -j);
            int midSq = getSquare(midFile, royalRank, variant.boardSize);
            // None of these squares can be attacked
            if (isAttacked(midSq, colour.opponent)) {
              // squares between & dest square must not be attacked
              _valid = false;
              break;
            }
            if (midFile == rookFile) continue; // for some chess960 positions
            if (midFile == targetFile && targetFile == royalFile) continue; // king starting on target

            if (j != numMidSqs && board[midSq].isNotEmpty) {
              // squares between to and from must be empty
              _valid = false;
              break;
            }
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
          if (variant.gating) {
            int _rank = rank(m.from, size);
            if ((_rank == RANK_1 && colour == WHITE) || (_rank == size.maxRank && colour == BLACK)) {
              moves.addAll(generateGatingMoves(m));
            }
          }
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

  /// Generates a move for each piece in [variant.promotionPieces] for the [base] move.
  List<Move> generatePromotionMoves(Move base) {
    List<Move> moves = [];
    for (int p in variant.promotionPieces) {
      Move m = base.copyWith(promoSource: board[base.from].type, promoPiece: p);
      moves.add(m);
    }
    return moves;
  }

  /// Generates a move for each gating possibility for the [base] move.
  /// Doesn't include the option where a piece is not gated.
  List<Move> generateGatingMoves(Move base) {
    if (state.gates == null || state.gates!.isEmpty) return [];
    int _file = file(base.from);
    Square piece = board[base.from];
    Colour colour = piece.colour;
    if (piece.isEmpty) return [];
    if (!(state.virginFiles[colour].contains(_file))) return [];
    List<Move> moves = [];
    // TODO: GatingMode.fixed
    for (int p in state.gates![colour]) {
      Move m = base.copyWith(dropPiece: p);
      moves.add(m);
      if (m.castling) {
        Move m2 = base.copyWith(dropPiece: p, dropOnRookSquare: true);
        moves.add(m2);
      }
    }
    return moves;
  }

  /// Make a move and modify the game state. Returns true if the move was valid and made successfully.
  bool makeMove(Move move) {
    if ((move.from != HAND && !onBoard(move.from, size)) || !onBoard(move.to, size)) return false;
    int hash = state.hash;
    hash ^= zobrist.table[zobrist.TURN][Zobrist.META];
    List<Hand>? _hands =
        state.hands != null ? List.generate(state.hands!.length, (i) => List.from(state.hands![i])) : null;
    List<Hand>? _gates =
        state.gates != null ? List.generate(state.gates!.length, (i) => List.from(state.gates![i])) : null;
    List<List<int>> _virginFiles = List.generate(state.virginFiles.length, (i) => List.from(state.virginFiles[i]));
    List<int> _pieces = List.from(state.pieces);

    // TODO: more validation?
    Square fromSq = move.from >= BOARD_START ? board[move.from] : EMPTY;
    Square toSq = board[move.to];
    int fromRank = rank(move.from, size);
    PieceType fromPiece = variant.pieces[fromSq.type].type;
    if (fromSq != EMPTY && fromSq.colour != state.turn) return false;
    int colour = turn;
    // Remove the moved piece, if this piece came from on the board.
    if (move.from >= BOARD_START) {
      hash ^= zobrist.table[move.from][fromSq.piece];
      if (move.promotion) {
        _pieces[fromSq.piece]--;
      }
      if (move.gate) {
        if (!(move.castling && move.dropOnRookSquare)) {
          // Move piece from gate to board.
          _gates![colour].remove(move.dropPiece!);
          int dropPiece = move.dropPiece!;
          hash ^= zobrist.table[move.from][dropPiece.piece];
          board[move.from] = makePiece(dropPiece, colour);
        } else {
          board[move.from] = EMPTY;
        }
      } else {
        board[move.from] = EMPTY;
      }
      // Mark the file as touched.
      if ((fromRank == 0 && colour == WHITE) || (fromRank == size.v - 1 && colour == BLACK)) {
        _virginFiles[colour].remove(file(move.from, size));
      }
    }

    // Add captured piece to hand
    if (variant.hands && move.capture) {
      int _piece = move.capturedPiece!.hasFlag(FLAG_PROMO) ? variant.promotionPieces[0] : move.capturedPiece!.type;
      _hands![colour].add(_piece);
      _pieces[makePiece(_piece, colour)]++;
    }

    // Remove gated piece from gate
    if (move.gate) {
      _gates![colour].remove(move.dropPiece!);
    }

    // Remove captured piece from hash and pieces list
    if (move.capture && !move.enPassant) {
      int _p = board[move.to].piece;
      hash ^= zobrist.table[move.to][_p];
      _pieces[_p]--;
    }

    if (!move.castling && !move.promotion) {
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
      _pieces[board[move.to].piece]++;
    }
    // Manage halfmove counter
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
      _pieces[board[captureSq].piece]--;
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
      int castlingFile = kingside ? variant.castlingOptions.kTarget! : variant.castlingOptions.qTarget!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = getSquare(rookFile, fromRank, size);
      int kingSq = getSquare(castlingFile, fromRank, size);
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

      if (move.gate && move.dropOnRookSquare) {
        int dropPiece = makePiece(move.dropPiece!, colour);
        board[move.castlingPieceSquare!] = dropPiece;
        hash ^= zobrist.table[move.castlingPieceSquare!][dropPiece.piece];
      }
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
      virginFiles: _virginFiles,
      epSquare: epSquare,
      hash: hash,
      hands: _hands,
      gates: _gates,
      pieces: _pieces,
    );
    history.add(_state);
    zobrist.incrementHash(hash);
    return true;
  }

  /// Revert to the previous state in [history] and undoes the move that was last made.
  /// Returns the move that was undone.
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

  /// Makes a random valid move for the current player.
  Move makeRandomMove() {
    List<Move> moves = generateLegalMoves();
    int i = Random().nextInt(moves.length);
    makeMove(moves[i]);
    return moves[i];
  }

  /// Checks if [square] is attacked by [colour].
  /// Works by generating all legal moves for the other player, and therefore is slow.
  bool isAttacked(int square, Colour colour) {
    List<Move> attacks = generatePlayerMoves(colour, MoveGenOptions.squareAttacks(square));
    return attacks.isNotEmpty;
  }

  /// Check if [player]'s king is currently attacked.
  bool kingAttacked(int player) => isAttacked(state.royalSquares[player], player.opponent);

  /// Is the current player's king in check?
  bool get inCheck => kingAttacked(state.turn);

  /// Is this checkmate?
  bool get checkmate => inCheck && generateLegalMoves().isEmpty;

  /// Is this stalemate?
  bool get stalemate => !inCheck && generateLegalMoves().isEmpty;

  /// Check if there is currently sufficient material on the board for one player to mate the other.
  /// Returns true if there *isn't* sufficient material (and therefore it's a draw).
  bool get insufficientMaterial {
    if (hasSufficientMaterial(WHITE)) return false;
    return !hasSufficientMaterial(BLACK);
  }

  /// Determines whether there is sufficient material for [player] to deliver mate in the board
  /// position specified in [state].
  /// [state] defaults to the current board state if unspecified.
  bool hasSufficientMaterial(Colour player, {State? state}) {
    State _state = state ?? this.state;
    for (int p in variant.materialConditionsInt.soloMaters) {
      if (_state.pieces[makePiece(p, player)] > 0) return true;
    }
    // TODO: figure out how to track square colours to check bishop pairs
    for (int p in variant.materialConditionsInt.pairMaters) {
      if (_state.pieces[makePiece(p, player)] > 1) return true;
    }
    for (int p in variant.materialConditionsInt.combinedPairMaters) {
      if (_state.pieces[makePiece(p, player)] + _state.pieces[makePiece(p, player.opponent)] > 1) return true;
    }
    for (List<int> c in variant.materialConditionsInt.specialCases) {
      bool met = true;
      for (int p in c) {
        if (_state.pieces[makePiece(p, player)] < 1) met = false;
      }
      if (met) return true;
    }
    return false;
  }

  /// Check if we have reached the repetition draw limit (threefold repetition in standard chess).
  /// Configurable in [Variant.repetitionDraw].
  bool get repetition => variant.repetitionDraw != null ? hashHits >= variant.repetitionDraw! : false;

  /// Check if we have reached the half move rule (aka the 50 move rule in standard chess).
  /// Configurable in [variant.halfMoveDraw].
  bool get halfMoveRule => variant.halfMoveDraw != null && state.halfMoves >= variant.halfMoveDraw!;

  /// Check if there is any kind of draw.
  bool get inDraw => stalemate || insufficientMaterial || repetition || halfMoveRule;

  /// Check if it's checkmate or a draw.
  bool get gameOver => checkmate || inDraw;

  /// Check the number of times the current position has occurred in the hash table.
  int get hashHits => zobrist.hashHits(state.hash);

  /// Generates legal moves and returns the one that matches [algebraic].
  /// Returns null if no move is found.
  Move? getMove(String algebraic) {
    List<Move> moves = generateLegalMoves();
    Move? match = moves.firstWhereOrNull((m) => toAlgebraic(m) == algebraic);
    return match;
  }

  /// Returns the algebraic representation of [move], with respect to the board size.
  String toAlgebraic(Move move) {
    String alg = move.algebraic(size: size, useRookForCastling: variant.castlingOptions.useRookAsTarget);
    if (move.promotion) alg = '$alg${variant.pieces[move.promoPiece!].symbol.toLowerCase()}';
    if (move.from == HAND) alg = '${variant.pieces[move.dropPiece!].symbol.toLowerCase()}$alg';
    if (move.gate) {
      alg = '$alg/${variant.pieces[move.dropPiece!].symbol.toLowerCase()}';
      if (move.castling) {
        String _dropSq =
            move.dropOnRookSquare ? squareName(move.castlingPieceSquare!, size) : squareName(move.from, size);
        alg = '$alg$_dropSq';
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
      san = ([CASTLING_K, CASTLING_BK].contains(move.castlingDir)) ? kingside : queenside;
    } else {
      if (move.from == HAND) {
        PieceDefinition _pieceDef = variant.pieces[move.dropPiece!];
        san = move.algebraic(size: size);
        if (!_pieceDef.type.noSanSymbol) san = '${_pieceDef.symbol.toUpperCase()}$san';
      } else {
        int piece = board[move.from].type;
        PieceDefinition pieceDef = variant.pieces[piece];
        String disambiguator = getDisambiguator(move, moves);
        if (pieceDef.type.noSanSymbol) {
          if (move.capture) san = squareName(move.from, size)[0];
        } else
          san = pieceDef.symbol;
        san = pieceDef.type.noSanSymbol ? disambiguator : '$san$disambiguator';
        if (move.capture) san = '${san}x';
        san = '$san${squareName(move.to, size)}';

        if (move.promotion) san = '$san=${variant.pieces[move.promoPiece!].symbol}';
      }
    }
    if (move.gate) {
      san = '$san/${variant.pieces[move.dropPiece!].symbol}';
      if (move.castling) {
        String _dropSq =
            move.dropOnRookSquare ? squareName(move.castlingPieceSquare!, size) : squareName(move.from, size);
        san = '$san$_dropSq';
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
    if (moves == null) moves = generateLegalMoves();

    int _piece = board[move.from].type;
    int _file = file(move.from, size);
    bool ambiguity = false;
    bool needRank = false;
    bool needFile = false;
    for (Move m in moves) {
      if (m.handDrop) continue;
      if (m.drop && m.dropPiece != move.dropPiece) continue;
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
    assert(board.length == variant.boardSize.numIndices);
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
    if (variant.gatingMode == GatingMode.FLEX) {
      String whiteGate = state.gates![WHITE].map((p) => variant.pieces[p].symbol.toUpperCase()).join('');
      String blackGate = state.gates![BLACK].map((p) => variant.pieces[p].symbol.toLowerCase()).join('');
      _fen = '$_fen[$whiteGate$blackGate]';
    }
    String _turn = state.turn == WHITE ? 'w' : 'b';
    String _castling = state.castlingRights.formatted;
    if (variant.outputOptions.castlingFormat == CastlingFormat.Shredder) {
      _castling = replaceMultiple(_castling, CASTLING_SYMBOLS.keys.toList(), castlingFileSymbols);
    }
    if (variant.outputOptions.virginFiles) {
      String _whiteVfiles = state.virginFiles[WHITE].map((e) => fileSymbol(e).toUpperCase()).join('');
      String _blackVfiles = state.virginFiles[BLACK].map((e) => fileSymbol(e)).join('');
      _castling = '$_castling$_whiteVfiles$_blackVfiles';
    }
    String _ep = state.epSquare != null ? squareName(state.epSquare!, variant.boardSize) : '-';
    _fen = '$_fen $_turn $_castling $_ep ${state.halfMoves} ${state.fullMoves}';
    return _fen;
  }

  /// Generates an ASCII representation of the board.
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
    output = '$output$border\n     ';
    for (String i in Iterable<int>.generate(variant.boardSize.h).map((e) => String.fromCharCode(e + 97)).toList()) {
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
        int _piece = board[i];
        String symbol = _piece == EMPTY ? '' : variant.pieces[_piece.type].symbol;
        symbols.add(_piece.colour == WHITE ? symbol.toUpperCase() : symbol.toLowerCase());
      }
    }
    return symbols;
  }

  /// Converts the internal representation of the hands to a list of piece symbols (e.g. 'P', 'q').
  /// You probably need this for interopability with other applications (such as the Squares package).
  List<List<String>> handSymbols() {
    if (!variant.hands) return [[], []];
    List<String> whiteHand = state.hands![WHITE].map((p) => variant.pieces[p].symbol.toUpperCase()).toList();
    List<String> blackHand = state.hands![BLACK].map((p) => variant.pieces[p].symbol.toLowerCase()).toList();
    return [whiteHand, blackHand];
  }

  /// Converts the internal representation of the gates to a list of piece symbols (e.g. 'P', 'q').
  /// You probably need this for interopability with other applications (such as the Squares package).
  List<List<String>> gateSymbols() {
    if (!variant.gating) return [[], []];
    List<String> whiteGate = state.gates![WHITE].map((p) => variant.pieces[p].symbol.toUpperCase()).toList();
    List<String> blackGate = state.gates![BLACK].map((p) => variant.pieces[p].symbol.toLowerCase()).toList();
    return [whiteGate, blackGate];
  }

  GameInfo get info => GameInfo(
        lastMove: state.move,
        lastFrom: state.move != null ? (state.move!.from == HAND ? 'hand' : squareName(state.move!.from, size)) : null,
        lastTo: state.move != null ? squareName(state.move!.to, size) : null,
        checkSq: inCheck ? squareName(state.royalSquares[state.turn], size) : null,
      );

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

  /// Performs a [divide perft test](https://www.chessprogramming.org/Perft#Divide), to [depth].
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

  /// Returns a naive material evaluation of the current position, from the perspective of [player].
  /// Return value is in [centipawns](https://www.chessprogramming.org/Centipawns).
  /// For example, if white has captured a rook from black with no compensation, this will return +500.
  int evaluate(Colour player) {
    int eval = 0;
    for (int i = 0; i < size.numIndices; i++) {
      if (!onBoard(i, size)) continue;
      Square square = board[i];
      if (square.isNotEmpty) {
        Colour colour = square.colour;
        int type = square.type;
        int value = variant.pieces[type].value;
        if (colour == player)
          eval += value;
        else
          eval -= value;
      }
    }
    return eval;
  }
}
