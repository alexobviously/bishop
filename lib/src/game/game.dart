import 'dart:math';

import 'package:bishop/bishop.dart';

part 'game_info.dart';
part 'game_outputs.dart';
part 'game_utils.dart';

/// Tracks the state of the game, handles move generation and validation, and generates output.
class Game {
  /// The variant that specifies the gameplay rules for this game.
  late final BuiltVariant variant;

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

  Game({
    required Variant variant,
    String? fen,
    FenBuilder? fenBuilder,
    this.seed = defaultSeed,
  }) {
    this.variant = BuiltVariant.fromData(variant);
    setup(fen: fen, fenBuilder: fenBuilder);
  }

  void setup({String? fen, FenBuilder? fenBuilder}) {
    // Order of precedence: fen, fenBuilder, variant.startPosBuilder, variant.startPosition.
    fenBuilder ??= variant.startPosBuilder;
    startPosition =
        fen ?? (fenBuilder != null ? fenBuilder() : variant.startPosition!);
    loadFen(startPosition);
    royalCaptureOptions = MoveGenOptions.pieceCaptures(variant.royalPiece);
  }

  int setupCastling(String castlingString, List<int> royalSquares) {
    if (castlingString == '-') {
      return 0;
    }
    if (!isAlpha(castlingString) ||
        (castlingString.length > 4 && !variant.outputOptions.virginFiles)) {
      throw ('Invalid castling string');
    }
    CastlingRights cr = 0;
    for (String c in castlingString.split('')) {
      // there is probably a better way to do all of this
      bool white = c == c.toUpperCase();
      royalFile = file(royalSquares[white ? 0 : 1], size);
      if (Castling.symbols.containsKey(c)) {
        cr += Castling.symbols[c]!;
      } else {
        int cFile = fileFromSymbol(c);
        bool kingside = cFile > file(royalSquares[white ? 0 : 1], size);
        if (kingside) {
          castlingTargetK = cFile;
          cr += white ? Castling.k : Castling.bk;
        } else {
          castlingTargetQ = cFile;
          cr += white ? Castling.q : Castling.bq;
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
          int piece = board[r + j].type;
          if (piece == variant.royalPiece) {
            kingside = true;
          } else if (piece == variant.castlingPiece) {
            if (kingside) {
              castlingTargetK = j;
            } else {
              castlingTargetQ = j;
            }
          }
        }
      }
    }
    if (variant.outputOptions.castlingFormat == CastlingFormat.shredder) {
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
    Map<String, int> pieceLookup =
        {}; // TODO: replace with variant.pieceLookup?
    for (int i = 0; i < variant.pieces.length; i++) {
      pieceLookup[variant.pieces[i].symbol] = i;
    }

    board = List.filled(variant.boardSize.numSquares * 2, 0);
    List<String> sections = fen.split(' ');

    // Parse hands for variants with drops
    List<List<int>>? hands;
    List<List<int>>? gates;
    List<int> pieces = List.filled((variant.pieces.length + 1) * 2, 0);
    List<int> checks = [0, 0];
    if (variant.hands || variant.gatingMode == GatingMode.flex) {
      List<List<int>> temp = [[], []];
      RegExp handRegex = RegExp(r'\[([A-Za-z]+)\]');
      RegExpMatch? handMatch = handRegex.firstMatch(sections[0]);
      if (handMatch != null) {
        sections[0] = sections[0].substring(0, handMatch.start);
        String hand = handMatch.group(1)!;
        temp = [[], []];
        for (String c in hand.split('')) {
          String upper = c.toUpperCase();
          if (pieceLookup.containsKey(upper)) {
            bool white = c == upper;
            int piece = pieceLookup[upper]!;
            temp[white ? 0 : 1].add(piece);
            pieces[makePiece(piece, white ? 0 : 1)]++;
          }
        }
      }
      if (variant.hands) {
        hands = temp;
      } else if (variant.gatingMode == GatingMode.flex) {
        gates = temp;
      }
    }

    List<String> boardSymbols = sections[0].split('');
    if (boardSymbols.where((e) => e == '/').length !=
        (variant.boardSize.v -
            1 +
            (variant.gatingMode == GatingMode.fixed ? 2 : 0))) {
      throw ('Invalid FEN: wrong number of ranks');
    }
    String turnStr = (strict || sections.length > 1) ? sections[1] : 'w';
    if (!(['w', 'b'].contains(turnStr))) {
      throw ("Invalid FEN: colour should be 'w' or 'b'");
    }
    String castlingStr = (strict || sections.length > 2)
        ? sections[2]
        : 'KQkq'; // TODO: get default castling for variant
    String epStr = (strict || sections.length > 3) ? sections[3] : '-';
    String halfMoves = (strict || sections.length > 4) ? sections[4] : '0';
    String fullMoves = (strict || sections.length > 5) ? sections[5] : '1';
    String aux = sections.length > 6 ? sections[6] : '';

    // Process fixed gates, for variants like musketeer.
    // gate/rbn...BNR/GATE
    if (variant.gatingMode == GatingMode.fixed) {
      gates = [List.filled(size.h, 0), List.filled(size.h, 0)];
      // extract the first and last segments
      List<String> fileStrings = sections[0].split('/');
      List<String> gateStrings = [
        fileStrings.removeAt(0),
        fileStrings.removeAt(fileStrings.length - 1)
      ];
      boardSymbols = fileStrings.join('/').split(''); // rebuild
      for (int i = 0; i < 2; i++) {
        int squareIndex = 0;
        int empty = 0;
        for (String c in gateStrings[i].split('')) {
          String symbol = c.toUpperCase();
          if (isNumeric(c)) {
            empty = (empty * 10) + int.parse(c);
            if (squareIndex + empty - 1 > size.h) {
              // todo: this might be wrong
              throw ('Invalid FEN: gate ($i) overflow [$c, ${squareIndex + empty - 1}]');
            }
          } else {
            squareIndex += empty;
            empty = 0;
          }

          if (pieceLookup.containsKey(symbol)) {
            // it's a piece
            int piece = pieceLookup[symbol]!;
            gates[1 - i][squareIndex] = piece;
            pieces[makePiece(piece, 1 - i)]++;
            squareIndex++;
          }
        }
      }
    }

    int sq = 0;
    int emptySquares = 0;
    List<int> royalSquares = [Bishop.invalid, Bishop.invalid];

    for (String c in boardSymbols) {
      if (c == '~') {
        board[sq - 1] = board[sq - 1] + promoFlag;
        continue;
      }
      String symbol = c.toUpperCase();
      if (isNumeric(c)) {
        emptySquares = (emptySquares * 10) + int.parse(c);
        if (!onBoard(sq + emptySquares - 1, size)) {
          throw ('Invalid FEN: rank overflow [$c, ${sq + emptySquares - 1}]');
        }
      } else {
        sq += emptySquares;
        emptySquares = 0;
      }
      if (c == '/') sq += variant.boardSize.h;
      if (pieceLookup.containsKey(symbol)) {
        if (!onBoard(sq, size)) {
          throw ('Invalid FEN: rank overflow [$symbol, $sq]');
        }
        // it's a piece
        int pieceIndex = pieceLookup[symbol]!;
        Colour colour = c == symbol ? Bishop.white : Bishop.black;
        Square piece = makePiece(pieceIndex, colour);
        board[sq] = piece;
        pieces[piece]++;
        if (variant.pieces[pieceIndex].type.royal) {
          royalSquares[colour] = sq;
        }
        sq++;
      }
    }

    List<List<int>> virginFiles = [[], []];
    if (variant.outputOptions.virginFiles) {
      String castlingStrMod =
          castlingStr; // so we can modify _castling in place
      for (int i = 0; i < castlingStrMod.length; i++) {
        String char = castlingStrMod[i];
        String lower = char.toLowerCase();
        int colour = lower == char ? Bishop.black : Bishop.white;
        int cFile = fileFromSymbol(lower);
        if (cFile < 0 || cFile >= size.h) continue;

        if (virginFiles[colour].contains(cFile)) continue;
        virginFiles[colour].add(cFile);
        castlingStr = castlingStr.replaceFirst(char, '');
      }
    } else {
      List<int> vf = List.generate(size.h, (i) => i);
      virginFiles = [vf, List.from(vf)]; // just in case
    }

    // handle extra data
    if (aux.isNotEmpty) {
      final checksRegex = RegExp(r'(\+)([0-9]+)(\+)([0-9]+)');
      RegExpMatch? checksMatch = checksRegex.firstMatch(aux);
      if (checksMatch != null) {
        checks = [int.parse(checksMatch[2]!), int.parse(checksMatch[4]!)];
      }
    }

    int turn = turnStr == 'w' ? Bishop.white : Bishop.black;
    int? ep = epStr == '-' ? null : squareNumber(epStr, variant.boardSize);
    int castling =
        variant.castling ? setupCastling(castlingStr, royalSquares) : 0;
    State newState = State(
      turn: turn,
      halfMoves: int.parse(halfMoves),
      fullMoves: int.parse(fullMoves),
      epSquare: ep,
      castlingRights: castling,
      royalSquares: royalSquares,
      virginFiles: virginFiles,
      hands: hands,
      gates: gates,
      pieces: pieces,
      checks: checks,
    );
    newState.hash = zobrist.compute(newState, board);
    zobrist.incrementHash(newState.hash);
    history.add(newState);
  }

  /// Generates all legal moves for the player whose turn it is.
  List<Move> generateLegalMoves() =>
      generatePlayerMoves(state.turn, MoveGenOptions.normal);

  /// Generates all possible moves that could be played by the other player next turn,
  /// not respecting blocking pieces or checks.
  List<Move> generatePremoves() =>
      generatePlayerMoves(state.turn.opponent, MoveGenOptions.premoves);

  /// Generates all moves for the specified [colour]. See [MoveGenOptions] for possibilities.
  List<Move> generatePlayerMoves(int colour, [MoveGenOptions? options]) {
    options ??= MoveGenOptions.normal;
    List<Move> moves = [];
    for (int i = 0; i < board.length; i++) {
      Square target = board[i];
      if (target.isNotEmpty && target.colour == colour) {
        List<Move> pieceMoves = generatePieceMoves(i, options);
        moves.addAll(pieceMoves);
      }
    }
    if (variant.hands && options.quiet && !options.onlyPiece) {
      moves.addAll(generateDrops(colour));
    }
    return moves;
  }

  /// Generates drop moves for [colour]. Used for variants with hands, e.g. Crazyhouse.
  List<Move> generateDrops(int colour, [bool legal = true]) {
    List<Move> drops = [];
    Set<int> hand = state.hands![colour].toSet();
    for (int i = 0; i < size.numIndices; i++) {
      if (!onBoard(i, size)) continue;
      if (board[i].isNotEmpty) continue;
      for (int p in hand) {
        int hRank = rank(i, size);
        bool onPromoRank = colour == Bishop.white
            ? hRank == size.maxRank
            : hRank == Bishop.rank1;
        if (onPromoRank && variant.pieces[p].type.promotable) continue;
        int dropPiece = p;
        // TODO: support more than one promo piece in this case
        if (p.hasFlag(promoFlag)) dropPiece = variant.promotionPieces[0];
        Move m = Move.drop(to: i, dropPiece: dropPiece);
        drops.add(m);
      }
    }

    if (legal) {
      List<Move> remove = [];
      for (Move m in drops) {
        makeMove(m);
        if (kingAttacked(colour)) remove.add(m);
        undo();
      }
      for (Move m in remove) {
        drops.remove(m);
      }
    }
    return drops;
  }

  /// Generates all moves for the piece on [square] in accordance with [options].
  List<Move> generatePieceMoves(int square, [MoveGenOptions? options]) {
    options ??= MoveGenOptions.normal;
    Square piece = board[square];
    if (piece.isEmpty) return [];
    Colour colour = piece.colour;
    int dirMult = Bishop.playerDirection[piece.colour];
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
      if (md.firstOnly && !variant.firstMoveRanks[colour].contains(fromRank)) {
        continue;
      }
      int range = md.range == 0 ? variant.boardSize.maxDim : md.range;
      for (int i = 0; i < range; i++) {
        if (exit) break;
        int to = square + md.normalised * (i + 1) * dirMult;
        if (!onBoard(to, variant.boardSize)) break;
        if (md.lame) {
          int fromLame = from + md.normalised * i * dirMult;
          int blockSq = fromLame + md.lameNormalised! * dirMult;
          if (board[blockSq].isNotEmpty && !options.ignorePieces) break;
        }
        bool optPromo = false;
        bool forcedPromo = false;
        if (pieceType.promotable && variant.promotion) {
          int toRank = rank(to, size);
          optPromo = colour == Bishop.white
              ? toRank >= variant.promotionRanks[Bishop.black]
              : toRank <= variant.promotionRanks[Bishop.white];
          if (optPromo) {
            forcedPromo = colour == Bishop.white
                ? toRank >= size.maxRank
                : toRank <= Bishop.rank1;
          }
        }

        Square target = board[to];
        bool setEnPassant =
            variant.enPassant && md.firstOnly && pieceType.enPassantable;

        void addMove(Move m) {
          if (optPromo) moves.addAll(generatePromotionMoves(m));
          bool addBase = !forcedPromo;
          if (variant.gating) {
            int gRank = rank(m.from, size);
            if ((gRank == Bishop.rank1 && colour == Bishop.white) ||
                (gRank == size.maxRank && colour == Bishop.black)) {
              final gatingMoves = generateGatingMoves(m);
              moves.addAll(gatingMoves);
              if (gatingMoves.isNotEmpty &&
                  variant.gatingMode == GatingMode.fixed) {
                addBase = false;
              }
            }
          }
          if (addBase) moves.add(m);
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
      bool kingside = colour == Bishop.white
          ? state.castlingRights.wk
          : state.castlingRights.bk;
      bool queenside = colour == Bishop.white
          ? state.castlingRights.wq
          : state.castlingRights.bq;
      int royalRank = rank(from, variant.boardSize);

      for (int i = 0; i < 2; i++) {
        bool sideCondition = i == 0
            ? (kingside && variant.castlingOptions.kingside)
            : (queenside && variant.castlingOptions.queenside);
        if (!sideCondition) continue;
        // Conditions for castling:
        // * All squares between the king's start and end (inclusive) must be free and not attacked
        // * Obviously the king's start is occupied by the king, but it can't be in check
        // * The square the rook lands on must be free (but can be attacked)
        int targetFile = i == 0
            ? variant.castlingOptions.kTarget!
            : variant.castlingOptions.qTarget!;
        int targetSq =
            getSquare(targetFile, royalRank, size); // where the king lands
        int rookFile = i == 0 ? castlingTargetK! : castlingTargetQ!;
        int rookSq =
            getSquare(rookFile, royalRank, size); // where the rook starts
        int rookTargetFile = i == 0 ? targetFile - 1 : targetFile + 1;
        int rookTargetSq =
            getSquare(rookTargetFile, royalRank, size); // where the rook lands
        // Check rook target square is empty (or occupied by the rook/king already)
        if (board[rookTargetSq].isNotEmpty &&
            rookTargetSq != rookSq &&
            rookTargetSq != from) {
          continue;
        }
        // Check king target square is empty (or occupied by the castling rook)
        if (board[targetSq].isNotEmpty && targetSq != rookSq) continue;
        int numMidSqs = (targetFile - royalFile!).abs();
        bool valid = true;
        if (!options.ignorePieces) {
          for (int j = 1; j <= numMidSqs; j++) {
            int midFile = royalFile! + (i == 0 ? j : -j);
            int midSq = getSquare(midFile, royalRank, variant.boardSize);
            // None of these squares can be attacked
            if (isAttacked(midSq, colour.opponent)) {
              // squares between & dest square must not be attacked
              valid = false;
              break;
            }
            if (midFile == rookFile) continue; // for some chess960 positions
            if (midFile == targetFile && targetFile == royalFile) {
              continue;
            } // king starting on target

            if (j != numMidSqs && board[midSq].isNotEmpty) {
              // squares between to and from must be empty
              valid = false;
              break;
            }
          }
        }
        if (valid) {
          int castlingDir = i == 0 ? Castling.k : Castling.q;
          Move m = Move(
            from: from,
            to: targetSq,
            castlingDir: castlingDir,
            castlingPieceSquare: rookSq,
          );
          if (variant.gatingMode != GatingMode.fixed) moves.add(m);
          if (variant.gating) {
            int gRank = rank(m.from, size);
            if ((gRank == Bishop.rank1 && colour == Bishop.white) ||
                (gRank == size.maxRank && colour == Bishop.black)) {
              moves.addAll(generateGatingMoves(m));
            }
          }
        }
      }
    }

    if (options.onlySquare != null) {
      List<Move> remove = [];
      for (Move m in moves) {
        if (m.to != options.onlySquare) {
          remove.add(m);
        }
      }
      for (Move m in remove) {
        moves.remove(m);
      }
    }

    if (options.legal) {
      List<Move> remove = [];
      for (Move m in moves) {
        makeMove(m);
        if (kingAttacked(colour)) remove.add(m);
        undo();
      }
      for (Move m in remove) {
        moves.remove(m);
      }
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
    int gFile = file(base.from);
    Square piece = board[base.from];
    Colour colour = piece.colour;
    if (piece.isEmpty) return [];
    if (!(state.virginFiles[colour].contains(gFile))) return [];
    List<Move> moves = [];
    void addGatingMove(int p) {
      Move m = base.copyWith(dropPiece: p);
      moves.add(m);
      if (m.castling) {
        Move m2 = base.copyWith(dropPiece: p, dropOnRookSquare: true);
        moves.add(m2);
      }
    }

    if (variant.gatingMode == GatingMode.flex) {
      for (int p in state.gates![colour]) {
        addGatingMove(p);
      }
    } else if (variant.gatingMode == GatingMode.fixed) {
      int p = state.gates![colour][gFile];
      if (p != 0) {
        addGatingMove(p);
      }
    }
    return moves;
  }

  /// Make a move and modify the game state. Returns true if the move was valid and made successfully.
  bool makeMove(Move move) {
    if ((move.from != Bishop.hand && !onBoard(move.from, size)) ||
        !onBoard(move.to, size)) {
      return false;
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

    // TODO: more validation?
    Square fromSq = move.from >= Bishop.boardStart ? board[move.from] : empty;
    // Square toSq = board[move.to];
    int fromRank = rank(move.from, size);
    int fromFile = file(move.from, size);
    PieceType fromPiece = variant.pieces[fromSq.type].type;
    if (fromSq != empty && fromSq.colour != state.turn) return false;
    int colour = turn;
    // Remove the moved piece, if this piece came from on the board.
    if (move.from >= Bishop.boardStart) {
      hash ^= zobrist.table[move.from][fromSq.piece];
      if (move.promotion) {
        pieces[fromSq.piece]--;
      }
      if (move.gate) {
        if (!(move.castling && move.dropOnRookSquare)) {
          // Move piece from gate to board.
          if (variant.gatingMode == GatingMode.flex) {
            gates![colour].remove(move.dropPiece!);
          } else if (variant.gatingMode == GatingMode.fixed) {
            gates![colour][fromFile] = empty;
          }
          int dropPiece = move.dropPiece!;
          hash ^= zobrist.table[move.from][dropPiece.piece];
          board[move.from] = makePiece(dropPiece, colour);
        } else {
          board[move.from] = empty;
        }
      } else {
        board[move.from] = empty;
      }
      // Mark the file as touched.
      if ((fromRank == 0 && colour == Bishop.white) ||
          (fromRank == size.v - 1 && colour == Bishop.black)) {
        virginFiles[colour].remove(file(move.from, size));
      }
    }

    // Add captured piece to hand
    if (variant.hands && move.capture) {
      int piece = move.capturedPiece!.hasFlag(promoFlag)
          ? variant.promotionPieces[0]
          : move.capturedPiece!.type;
      hands![colour].add(piece);
      pieces[makePiece(piece, colour)]++;
    }

    // Remove gated piece from gate
    if (move.gate) {
      gates![colour].remove(move.dropPiece!);
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
      //if (move.from == HAND) print('$colour ${move.dropPiece!}');
      if (move.from == Bishop.hand) hands![colour].remove(move.dropPiece!);
    } else if (move.promotion) {
      // Place the promoted piece
      board[move.to] = makePiece(move.promoPiece!, state.turn, promoFlag);
      hash ^= zobrist.table[move.to][board[move.to].piece];
      pieces[board[move.to].piece]++;
    }
    // Manage halfmove counter
    int halfMoves = state.halfMoves;
    if (move.capture || fromPiece.promotable) {
      halfMoves = 0;
    } else {
      halfMoves++;
    }

    int castlingRights = state.castlingRights;
    List<int> royalSquares = List.from(state.royalSquares);

    if (move.enPassant) {
      // Remove the captured ep piece
      int captureSq =
          move.to + Bishop.playerDirection[colour.opponent] * size.north;
      hash ^= zobrist.table[captureSq][board[captureSq].piece];
      board[captureSq] = empty;
      pieces[board[captureSq].piece]--;
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
      bool kingside = move.castlingDir == Castling.k;
      int castlingFile = kingside
          ? variant.castlingOptions.kTarget!
          : variant.castlingOptions.qTarget!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = getSquare(rookFile, fromRank, size);
      int kingSq = getSquare(castlingFile, fromRank, size);
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
      board[move.castlingPieceSquare!] = empty;
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
      int fromFile = file(move.from, size);
      int ks = colour == Bishop.white ? Castling.k : Castling.bk;
      int qs = colour == Bishop.white ? Castling.q : Castling.bq;
      if (fromFile == castlingTargetK && castlingRights.hasRight(ks)) {
        castlingRights = castlingRights.flip(ks);
        hash ^= zobrist.table[zobrist.castling][state.castlingRights];
        hash ^= zobrist.table[zobrist.castling][castlingRights];
      } else if (fromFile == castlingTargetQ && castlingRights.hasRight(qs)) {
        castlingRights = castlingRights.flip(qs);
        hash ^= zobrist.table[zobrist.castling][state.castlingRights];
        hash ^= zobrist.table[zobrist.castling][castlingRights];
      }
    } else if (move.capture &&
        move.capturedPiece!.type == variant.castlingPiece) {
      // rook captured
      int toFile = file(move.to, size);
      int opponent = colour.opponent;
      int ks = opponent == Bishop.white ? Castling.k : Castling.bk;
      int qs = opponent == Bishop.white ? Castling.q : Castling.bq;
      if (toFile == castlingTargetK && castlingRights.hasRight(ks)) {
        castlingRights = castlingRights.flip(ks);
        hash ^= zobrist.table[zobrist.castling][state.castlingRights];
        hash ^= zobrist.table[zobrist.castling][castlingRights];
      } else if (toFile == castlingTargetQ && castlingRights.hasRight(qs)) {
        castlingRights = castlingRights.flip(qs);
        hash ^= zobrist.table[zobrist.castling][state.castlingRights];
        hash ^= zobrist.table[zobrist.castling][castlingRights];
      }
    }

    State newState = State(
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
    );
    history.add(newState);

    // kind of messy doing it like this, but inCheck depends on the current state
    // maybe that's a case for refactoring some methods into State?
    if (variant.gameEndConditions.checkLimit != null) {
      if (inCheck) {
        history.last = newState.copyWith(
          checks: List.from(newState.checks)..[newState.turn.opponent] += 1,
        );
      }
    }

    zobrist.incrementHash(hash);
    return true;
  }

  /// Revert to the previous state in [history] and undoes the move that was last made.
  /// Returns the move that was undone.
  Move? undo() {
    if (history.length == 1) return null;
    State lastState = history.removeLast();
    Move move = lastState.move!;

    int toSq = board[move.to];

    if (move.castling) {
      bool kingside = move.castlingDir == Castling.k;
      int royalRank = rank(move.from, size);
      int castlingFile = kingside
          ? variant.castlingOptions.kTarget!
          : variant.castlingOptions.qTarget!;
      int rookFile = kingside ? castlingFile - 1 : castlingFile + 1;
      int rookSq = getSquare(rookFile, royalRank, size);
      int rook = board[rookSq];
      int king = board[move.to];
      board[move.to] = empty;
      board[rookSq] = empty;
      board[move.from] = king;
      board[move.castlingPieceSquare!] = rook;
    } else {
      if (move.promotion) {
        board[move.from] = makePiece(move.promoSource!, state.turn);
      } else {
        if (move.from >= Bishop.boardStart) board[move.from] = toSq;
      }
      if (move.enPassant) {
        int captureSq = move.to +
            Bishop.playerDirection[move.capturedPiece!.colour] * size.north;
        board[captureSq] = move.capturedPiece!;
      }
      if (move.capture && !move.enPassant) {
        board[move.to] = move.capturedPiece!;
      } else {
        board[move.to] = empty;
      }
    }

    zobrist.decrementHash(lastState.hash);
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
    List<Move> attacks =
        generatePlayerMoves(colour, MoveGenOptions.squareAttacks(square));
    return attacks.isNotEmpty;
  }

  /// Check if [player]'s king is currently attacked.
  bool kingAttacked(int player) =>
      isAttacked(state.royalSquares[player], player.opponent);

  /// Is the current player's king in check?
  bool get inCheck => kingAttacked(state.turn);

  /// Is this checkmate?
  /// Currently, other win/lose game end conditions (like three check), also
  /// count as a checkmate.
  bool get checkmate {
    if (variant.gameEndConditions.checkLimit != null) {
      if (state.checks[state.turn.opponent] >=
          variant.gameEndConditions.checkLimit!) {
        return true;
      }
    }
    return inCheck && generateLegalMoves().isEmpty;
  }

  /// Is this stalemate?
  bool get stalemate => !inCheck && generateLegalMoves().isEmpty;

  /// Check if there is currently sufficient material on the board for one player to mate the other.
  /// Returns true if there *isn't* sufficient material (and therefore it's a draw).
  bool get insufficientMaterial {
    if (hasSufficientMaterial(Bishop.white)) return false;
    return !hasSufficientMaterial(Bishop.black);
  }

  /// Determines whether there is sufficient material for [player] to deliver mate in the board
  /// position specified in [state].
  /// [state] defaults to the current board state if unspecified.
  bool hasSufficientMaterial(Colour player, {State? state}) {
    State newState = state ?? this.state;
    for (int p in variant.materialConditions.soloMaters) {
      if (newState.pieces[makePiece(p, player)] > 0) return true;
    }
    // TODO: figure out how to track square colours to check bishop pairs
    for (int p in variant.materialConditions.pairMaters) {
      if (newState.pieces[makePiece(p, player)] > 1) return true;
    }
    for (int p in variant.materialConditions.combinedPairMaters) {
      if (newState.pieces[makePiece(p, player)] +
              newState.pieces[makePiece(p, player.opponent)] >
          1) {
        return true;
      }
    }
    for (List<int> c in variant.materialConditions.specialCases) {
      bool met = true;
      for (int p in c) {
        if (newState.pieces[makePiece(p, player)] < 1) met = false;
      }
      if (met) return true;
    }
    return false;
  }

  /// Check if we have reached the repetition draw limit (threefold repetition in standard chess).
  /// Configurable in [Variant.repetitionDraw].
  bool get repetition => variant.repetitionDraw != null
      ? hashHits >= variant.repetitionDraw!
      : false;

  /// Check if we have reached the half move rule (aka the 50 move rule in standard chess).
  /// Configurable in [variant.halfMoveDraw].
  bool get halfMoveRule =>
      variant.halfMoveDraw != null && state.halfMoves >= variant.halfMoveDraw!;

  /// Check if there is any kind of draw.
  bool get inDraw =>
      stalemate || insufficientMaterial || repetition || halfMoveRule;

  /// Check if it's checkmate or a draw.
  bool get gameOver => checkmate || inDraw;

  /// Check the number of times the current position has occurred in the hash table.
  int get hashHits => zobrist.hashHits(state.hash);
}
