import 'dart:math';

import 'package:bishop/bishop.dart';

part 'game_endings.dart';
part 'game_info.dart';
part 'game_movement.dart';
part 'game_outputs.dart';
part 'game_result.dart';
part 'game_utils.dart';

/// Tracks the state of the game, handles move generation and validation,
/// and generates output.
class Game {
  /// The variant that specifies the gameplay rules for this game.
  final BuiltVariant variant;

  /// A random number generator seed.
  /// Used by the Zobrist hash table.
  final int zobristSeed;
  late Zobrist zobrist;

  final int? startPosSeed;
  List<int> get board => state.board;
  late String startPosition;
  List<BishopState> history = [];
  BishopState get state => history.last;
  BishopState? get prevState =>
      history.length > 1 ? history[history.length - 2] : null;
  bool get canUndo => history.length > 1;
  Colour get turn => state.turn;

  int? castlingTargetK;
  int? castlingTargetQ;
  int? royalFile;
  List<String> castlingFileSymbols = ['K', 'Q', 'k', 'q'];
  late MoveGenParams royalCaptureOptions;

  BoardSize get size => variant.boardSize;

  @override
  String toString() => 'Game(${variant.name}, $fen)';

  Game({
    Variant? variant,
    String? fen,
    FenBuilder? fenBuilder,
    this.zobristSeed = Bishop.defaultSeed,
    this.startPosSeed,
  }) : variant = BuiltVariant.fromData(variant ?? Variant.standard()) {
    setup(fen: fen, fenBuilder: fenBuilder);
  }

  factory Game.fromPgn(String pgn) => parsePgn(pgn).buildGame();

  void setup({String? fen, FenBuilder? fenBuilder}) {
    // Order of precedence: fen, fenBuilder, variant.startPosBuilder,
    // variant.startPosition.
    fenBuilder ??= variant.startPosBuilder?.build;
    startPosition =
        fen ?? fenBuilder?.call(seed: startPosSeed) ?? variant.startPosition!;
    loadFen(startPosition);
    royalCaptureOptions = MoveGenParams.pieceCaptures(variant.royalPiece);
  }

  int setupCastling(
    String castlingString,
    List<int> royalSquares,
    List<int> board,
  ) {
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
      royalFile = size.file(royalSquares[white ? 0 : 1]);
      if (Castling.symbols.containsKey(c)) {
        cr += Castling.symbols[c]!;
      } else {
        int cFile = fileFromSymbol(c);
        bool kingside = cFile > size.file(royalSquares[white ? 0 : 1]);
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
  /// If [strict] is enabled, a full string must be provided, including turn,
  /// ep square, etc.
  void loadFen(String fen, [bool strict = false]) {
    zobrist = Zobrist(variant, zobristSeed);
    final pieceLookup = variant.pieceIndexLookup;

    List<int> board = List.filled(variant.boardSize.numSquares * 2, 0);
    List<String> sections = fen.split(' ');

    // Parse hands for variants with drops
    List<List<int>>? hands;
    List<List<int>>? gates;
    List<int> pieces =
        List.filled((variant.pieces.length + 1) * Bishop.numPlayers, 0);
    List<int> checks = [0, 0];
    if (variant.handsEnabled || variant.gatingMode == GatingMode.flex) {
      List<List<int>> temp = List.generate(Bishop.numPlayers, (_) => []);
      RegExp handRegex = RegExp(r'\[([A-Za-z]+)\]');
      RegExpMatch? handMatch = handRegex.firstMatch(sections[0]);
      if (handMatch != null) {
        sections[0] = sections[0].substring(0, handMatch.start);
        String hand = handMatch.group(1)!;
        for (String c in hand.split('')) {
          String upper = c.toUpperCase();
          int colour = c == upper ? Bishop.white : Bishop.black;
          if (c == '*') colour = Bishop.neutralPassive;
          if (pieceLookup.containsKey(upper)) {
            int piece = pieceLookup[upper]!;
            temp[colour].add(piece);
            pieces[makePiece(piece, colour)]++;
          }
        }
      }
      if (variant.handsEnabled) {
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
    List<int> royalSquares = List.filled(Bishop.numPlayers, Bishop.invalid);

    for (String c in boardSymbols) {
      if (c == '~') {
        board[sq - 1] =
            board[sq - 1].setInternalType(variant.defaultPromotablePiece);
        continue;
      }
      String symbol = c.toUpperCase();
      if (isNumeric(c)) {
        emptySquares = (emptySquares * 10) + int.parse(c);
        if (!size.onBoard(sq + emptySquares - 1)) {
          throw ('Invalid FEN: rank overflow [$c, ${sq + emptySquares - 1}]');
        }
      } else {
        sq += emptySquares;
        emptySquares = 0;
      }
      if (c == '/') sq += variant.boardSize.h;
      if (pieceLookup.containsKey(symbol)) {
        if (!size.onBoard(sq)) {
          throw ('Invalid FEN: rank overflow [$symbol, $sq]');
        }
        // it's a piece
        int pieceIndex = pieceLookup[symbol]!;
        Colour colour = c == symbol ? Bishop.white : Bishop.black;
        if (symbol == '*') colour = Bishop.neutralPassive; // todo: not this
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
    int? ep = epStr == '-' ? null : size.squareNumber(epStr);
    int castling =
        variant.castling ? setupCastling(castlingStr, royalSquares, board) : 0;
    BishopState newState = BishopState(
      board: board,
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
      meta: StateMeta(variant: variant),
    );
    newState = newState.copyWith(hash: zobrist.compute(newState));
    zobrist.incrementHash(newState.hash);
    history.add(newState);
  }

  /// Generates all legal moves for the player whose turn it is.
  List<Move> generateLegalMoves() =>
      generatePlayerMoves(state.turn, MoveGenParams.normal);

  /// Generates all possible moves that could be played by the other player next turn,
  /// not respecting blocking pieces or checks.
  List<Move> generatePremoves() =>
      generatePlayerMoves(state.turn.opponent, MoveGenParams.premoves);

  /// Generates all moves for the specified [colour]. See [MoveGenParams] for possibilities.
  List<Move> generatePlayerMoves(int colour, [MoveGenParams? options]) {
    options ??= MoveGenParams.normal;
    List<Move> moves = [];
    for (int i = 0; i < board.length; i++) {
      Square target = board[i];
      if (target.isNotEmpty &&
          (target.colour == colour || target.colour == Bishop.neutralPassive)) {
        List<Move> pieceMoves = generatePieceMoves(i, options);
        moves.addAll(pieceMoves);
      }
    }
    if (variant.handsEnabled && options.quiet && !options.onlyPiece) {
      moves.addAll(generateDrops(colour));
    }
    if (variant.hasPass && options.quiet) {
      final pass = generatePass(colour);
      if (pass != null) moves.insert(0, pass);
    }
    if (variant.forcedCapture != null && !options.ignorePieces) {
      final captures = moves.captures;
      if (captures.isNotEmpty) {
        return captures;
      }
    }
    return moves;
  }

  PassMove? generatePass(int colour, [bool legal = true]) {
    if (state.move is PassMove) return null;
    if (!variant.canPass(state: state, colour: colour)) {
      return null;
    }
    PassMove m = PassMove();
    if (legal) {
      bool valid = makeMove(m, false);
      if (lostBy(colour, ignoreSoftResults: true) || kingAttacked(colour)) {
        valid = false;
      }
      undo();
      return valid ? m : null;
    }
    return m;
  }

  /// Generates drop moves for [colour]. Used for variants with hands, e.g. Crazyhouse.
  List<Move> generateDrops(int colour, [bool legal = true]) {
    List<Move> drops =
        variant.generateDrops(state: state, colour: colour) ?? [];

    if (legal) {
      List<Move> remove = [];
      for (Move m in drops) {
        bool valid = makeMove(m, false);
        if (!valid ||
            lostBy(colour, ignoreSoftResults: true) ||
            kingAttacked(colour)) {
          remove.add(m);
        }
        undo();
      }
      for (Move m in remove) {
        drops.remove(m);
      }
    }
    return drops;
  }

  /// Generates all moves for the piece on [square] in accordance with [options].
  List<Move> generatePieceMoves(
    int square, [
    MoveGenParams options = MoveGenParams.normal,
  ]) {
    Square piece = board[square];
    if (piece.isEmpty) return [];
    Colour colour = piece.colour;
    int dirMult = Bishop.playerDirection[piece.colour];
    List<Move> moves = [];
    PieceType pieceType = variant.pieceType(piece, square);
    int from = square;
    int fromRank = size.rank(from);
    bool exit = false;

    void generateTeleportMoves(TeleportMoveDefinition md) {
      for (int to = 0; to < size.numIndices; to++) {
        if (!size.onBoard(square)) {
          to += size.h;
          if (!size.onBoard(square)) break;
        }
        if (to == square) continue;
        // todo: md.firstMove, when better first move logic is built
        if (options.ignorePieces) {
          moves.add(StandardMove(from: from, to: to));
          continue;
        }
        Square target = board[to];
        if (target.isEmpty && md.quiet) {
          moves.add(StandardMove(from: from, to: to));
          continue;
        }
        if (target.isNotEmpty && target.colour != colour && md.capture) {
          final targetPieceType = variant.pieceType(target, to);
          if (targetPieceType.royal) {
            // doesn't make sense for teleports to be able to capture royals
            // unless we later implement region restricted teleport moves
            continue;
          }
          moves.add(StandardMove(from: from, to: to, capturedPiece: target));
        }
      }
    }

    // Generate normal moves
    for (MoveDefinition md in pieceType.moves) {
      if (exit) break;
      if (!md.capture && !options.quiet) continue;
      if (!md.quiet && !options.captures) continue;
      if (md is TeleportMoveDefinition) {
        generateTeleportMoves(md);
        continue;
      }

      if (md.firstOnly &&
          !variant.canFirstMove(
            state: state,
            from: from,
            colour: colour,
            moveDefinition: md,
          )) {
        continue;
      }

      if (md is! StandardMoveDefinition) continue;
      int range = md.range == 0 ? variant.boardSize.maxDim : md.range;
      int squaresSinceHop = -1;

      for (int i = 0; i < range; i++) {
        if (exit) break;
        int to = square + md.normalised * (i + 1) * dirMult;
        if (!size.onBoard(to)) break;
        if (variant.hasRegions) {
          if (!variant.allowMovement(piece, to)) break;
        }
        if (md.lame) {
          int fromLame = from + md.normalised * i * dirMult;
          int blockSq = fromLame + md.lameNormalised! * dirMult;
          if (board[blockSq].isNotEmpty && !options.ignorePieces) break;
        }

        Square target = board[to];
        bool setEnPassant =
            variant.enPassant && md.firstOnly && pieceType.enPassantable;

        if (md.hopper) {
          if (target.isEmpty) {
            if (squaresSinceHop == -1) continue;
            squaresSinceHop++;
            if (md.limitedHopper) {
              if (squaresSinceHop > md.hopDistance) {
                break;
              }
              if (squaresSinceHop != md.hopDistance) {
                continue;
              }
            }
          } else {
            squaresSinceHop++;
            if (squaresSinceHop == 0) continue;
            if (md.limitedHopper && squaresSinceHop != md.hopDistance) {
              break;
            }
          }
        }

        void addMove(StandardMove m) {
          final mm = variant.generatePromotionMoves(
            base: m,
            state: state,
            pieceType: pieceType,
          );
          if (mm != null) moves.addAll(mm);
          // bool removeBase = false;
          if (mm == null) moves.add(m);
          if (variant.gating) {
            int gRank = size.rank(m.from);
            if ((gRank == Bishop.rank1 && colour == Bishop.white) ||
                (gRank == size.maxRank && colour == Bishop.black)) {
              final gatingMoves = generateGatingMoves(m);
              moves.addAll(gatingMoves);
              if (gatingMoves.isNotEmpty &&
                  variant.gatingMode == GatingMode.fixed) {
                moves.remove(m);
              }
            }
          }
          // if (!addBase) moves.remove(m);
          if (options.onlySquare != null && m.to == options.onlySquare) {
            exit = true;
          }
        }

        if (target.isEmpty) {
          // TODO: prioritise ep? for moves that could be both ep and quiet
          if (md.quiet) {
            if (!options.quiet && options.onlySquare == null) continue;
            StandardMove m =
                StandardMove(to: to, from: from, setEnPassant: setEnPassant);
            addMove(m);
          } else if (variant.enPassant &&
              md.enPassant &&
              (state.epSquare == to || options.ignorePieces) &&
              options.captures) {
            // en passant
            StandardMove m = StandardMove(
              to: to,
              from: from,
              capturedPiece: makePiece(variant.epPiece, colour.opponent),
              enPassant: true,
              setEnPassant: setEnPassant,
            );
            addMove(m);
          } else if (options.onlySquare != null && to == options.onlySquare) {
            StandardMove m = StandardMove(
              to: to,
              from: from,
            );
            addMove(m);
          } else {
            if (!options.ignorePieces) {
              if (md.slider) {
                continue;
              } else {
                break;
              }
            }
            StandardMove m = StandardMove(from: from, to: to);
            addMove(m);
          }
        } else if (target.colour == colour) {
          if (!options.ignorePieces) break;
          StandardMove m = StandardMove(from: from, to: to);
          addMove(m);
        } else {
          if (md.capture) {
            if (!options.captures) break;
            if (options.onlyPiece && target.type != options.pieceType) break;
            StandardMove m = StandardMove(
              to: to,
              from: from,
              capturedPiece: target,
              setEnPassant: setEnPassant,
            );
            addMove(m);
          } else if (options.ignorePieces) {
            StandardMove m = StandardMove(
              to: to,
              from: from,
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
      int royalRank = size.rank(from);

      for (int i = 0; i < 2; i++) {
        bool sideCondition = i == 0
            ? (kingside && variant.castlingOptions.kingside)
            : (queenside && variant.castlingOptions.queenside);
        if (!sideCondition) continue;
        // Conditions for castling:
        // * All squares between the king's start and end (inclusive) must be
        // free and not attacked
        // * Obviously the king's start is occupied by the king, but it can't
        // be in check
        // * The square the rook lands on must be free (but can be attacked)
        int targetFile = i == 0
            ? variant.castlingOptions.kTarget!
            : variant.castlingOptions.qTarget!;
        int targetSq =
            size.square(targetFile, royalRank); // where the king lands
        int rookFile = i == 0 ? castlingTargetK! : castlingTargetQ!;
        int rookSq = size.square(rookFile, royalRank); // where the rook starts
        int rookTargetFile = i == 0 ? targetFile - 1 : targetFile + 1;
        int rookTargetSq =
            size.square(rookTargetFile, royalRank); // where the rook lands
        // Check rook target square is empty (or occupied by the rook/king already)
        if (board[rookTargetSq].isNotEmpty &&
            rookTargetSq != rookSq &&
            rookTargetSq != from) {
          continue;
        }
        // Check king target square is empty (or occupied by the castling rook)
        if (board[targetSq].isNotEmpty &&
            targetSq != rookSq &&
            targetSq != square) continue;
        int numMidSqs = (targetFile - royalFile!).abs();
        bool valid = true;
        if (!options.ignorePieces) {
          for (int j = 1; j <= numMidSqs; j++) {
            int midFile = royalFile! + (i == 0 ? j : -j);

            // For some Chess960 positions.
            // See also https://github.com/alexobviously/bishop/issues/11
            // as to why this is first.
            if (midFile == rookFile) continue;

            int midSq = size.square(midFile, royalRank);

            // None of these squares can be attacked
            if (isAttacked(midSq, colour.opponent)) {
              // squares between & dest square must not be attacked
              valid = false;
              break;
            }

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
          StandardMove m = StandardMove(
            from: from,
            to: targetSq,
            castlingDir: castlingDir,
            castlingPieceSquare: rookSq,
          );
          if (variant.gatingMode != GatingMode.fixed) moves.add(m);
          if (variant.gating) {
            int gRank = size.rank(m.from);
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
        bool valid = makeMove(m, false);
        if (!valid ||
            lostBy(colour, ignoreSoftResults: true) ||
            kingAttacked(colour)) {
          remove.add(m);
        }
        undo();
      }
      for (Move m in remove) {
        moves.remove(m);
      }
    }
    return moves;
  }

  /// Generates a move for each gating possibility for the [base] move.
  /// Doesn't include the option where a piece is not gated.
  List<StandardMove> generateGatingMoves(StandardMove base) {
    if (state.gates == null || state.gates!.isEmpty) return [];
    int gFile = size.file(base.from);
    Square piece = board[base.from];
    Colour colour = piece.colour;
    if (piece.isEmpty) return [];
    if (!(state.virginFiles[colour].contains(gFile))) return [];
    List<StandardMove> moves = [];
    void addGatingMove(int p) {
      StandardMove m = base.copyWith(dropPiece: p);
      moves.add(m);
      if (m.castling) {
        StandardMove m2 = base.copyWith(dropPiece: p, dropOnRookSquare: true);
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

  /// Gets a random valid move for the current player.
  Move getRandomMove() {
    List<Move> moves = generateLegalMoves();
    int i = Random().nextInt(moves.length);
    return moves[i];
  }

  /// Makes a random valid move for the current player.
  Move makeRandomMove() {
    Move m = getRandomMove();
    makeMove(m);
    return m;
  }

  /// Makes a move from an algebraic move string (e.g. e2e4, f7f8q).
  /// Return value indicates whether the move was valid.
  bool makeMoveString(String move) {
    Move? m = getMove(move);
    if (m == null) return false;
    return makeMove(m);
  }

  /// Makes a move from a SAN string, e.g. 'Nxf3', 'e4', 'O-O-O'.
  /// Return value indicates whether the move was valid.
  /// If [checks] is false, the '+' or '#' part of the SAN string will not be
  /// computed, which vastly increases efficiency in cases like PGN parsing.
  bool makeMoveSan(String move, {bool checks = false}) {
    Move? m = getMoveSan(move, checks: checks);
    if (m == null) return false;
    return makeMove(m);
  }

  /// Checks whether an algebraic move string (e.g. e2e4, f7f8q) is a valid move.
  bool isMoveValid(String move) => getMove(move) != null;

  /// Makes multiple [moves] in order, in algebraic format (e.g. e2e4, f7f8q).
  /// Returns the number of moves that were successfully made. If everything
  /// went fine, this should be equal to [moves.length].
  /// If [undoOnError] is true, all moves made before the error will be undone.
  int makeMultipleMoves(
    List<String> moves, {
    bool undoOnError = true,
    bool san = false,
  }) {
    int movesMade = 0;
    for (String move in moves) {
      bool ok = san ? makeMoveSan(move) : makeMoveString(move);
      if (!ok) break;
      movesMade++;
    }
    if (movesMade < moves.length && undoOnError) {
      for (int i = 0; i < movesMade; i++) {
        undo();
      }
    }
    return movesMade;
  }

  /// Checks if [square] is attacked by [colour].
  /// Works by generating all legal moves for the other player, and therefore is slow.
  bool isAttacked(int square, Colour colour) {
    List<Move> attacks =
        generatePlayerMoves(colour, MoveGenParams.squareAttacks(square));
    return attacks.isNotEmpty;
  }

  /// Check if [player]'s king is currently attacked.
  bool kingAttacked(int player) => state.royalSquares[player] != Bishop.invalid
      ? isAttacked(state.royalSquares[player], player.opponent)
      : false;

  /// Check the number of times the current position has occurred in the hash table.
  int get hashHits => zobrist.hashHits(state.hash);
}
