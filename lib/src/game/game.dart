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

  final bool startedInInitialPosition;

  @override
  String toString() => 'Game(${variant.name}, $fen)';

  Game({
    Variant? variant,
    String? fen,
    FenBuilder? fenBuilder,
    this.zobristSeed = Bishop.defaultSeed,
    this.startPosSeed,
  })  : startedInInitialPosition = fen == null && fenBuilder == null,
        variant = BuiltVariant.fromData(variant ?? Variant.standard()) {
    setup(fen: fen, fenBuilder: fenBuilder);
  }

  factory Game.fromPgn(String pgn) => parsePgn(pgn).buildGame();

  void setup({String? fen, FenBuilder? fenBuilder}) {
    zobrist = Zobrist(variant, zobristSeed);
    // Order of precedence: fen, fenBuilder, variant.startPosBuilder,
    // variant.startPosition.
    fenBuilder ??= variant.startPosBuilder?.build;
    startPosition =
        fen ?? fenBuilder?.call(seed: startPosSeed) ?? variant.startPosition!;
    loadFen(startPosition, initialSetup: true);
  }

  void loadFen(
    String fen, {
    bool strict = false,
    bool initialSetup = false,
  }) {
    final result = parseFen(
      fen: fen,
      variant: variant,
      strict: strict,
      initialPosition: initialSetup && startedInInitialPosition,
      seed: startPosSeed,
    );
    final newState = result.state.copyWith(hash: zobrist.compute(result.state));
    zobrist.incrementHash(newState.hash);
    history.add(newState);
    royalFile = result.castling.royalFile;
    castlingTargetK = result.castling.castlingTargetK;
    castlingTargetQ = result.castling.castlingTargetQ;
    castlingFileSymbols =
        result.castling.castlingFileSymbols ?? castlingFileSymbols;
    royalCaptureOptions = MoveGenParams.pieceCaptures(variant.royalPiece);
  }

  /// Generates all legal moves for the player whose turn it is.
  List<Move> generateLegalMoves() =>
      generatePlayerMoves(state.turn, MoveGenParams.normal);

  /// Generates all possible moves that could be played by the other player next turn,
  /// not respecting blocking pieces or checks.
  List<Move> generatePremoves() =>
      generatePlayerMoves(state.turn.opponent, MoveGenParams.premoves);

  /// Generates all moves for the specified [player]. See [MoveGenParams] for possibilities.
  List<Move> generatePlayerMoves(int player, [MoveGenParams? params]) {
    params ??= MoveGenParams.normal;
    List<Move> moves = [];
    for (int i = 0; i < board.length; i++) {
      Square target = board[i];
      if (target.isNotEmpty &&
          (target.colour == player || target.colour == Bishop.neutralPassive)) {
        List<Move> pieceMoves = generatePieceMoves(i, params);
        moves.addAll(pieceMoves);
        if (params.onlyOne && moves.isNotEmpty) return moves;
      }
    }
    if (variant.handsEnabled && params.quiet && !params.onlyPiece) {
      moves.addAll(generateDrops(player));
    }
    if (variant.hasMoveGenerators) {
      moves.addAll(
        variant.generateCustomMoves(
          state: state,
          player: player,
          params: params,
        ),
      );
    }
    if (variant.hasPass && params.quiet) {
      final pass = generatePass(player);
      if (pass != null) moves.insert(0, pass);
    }
    if (variant.forcedCapture != null && !params.ignorePieces) {
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

    PieceType pieceType = variant.pieceType(piece, square);
    if (options.onlySquare != null &&
        pieceType.optimisationData != null &&
        pieceType.optimisationData!
            .excludePiece(square, options.onlySquare!, size)) {
      return const [];
    }

    List<Move> moves = [];
    int from = square;
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

    void addMove(StandardMove m) {
      final mm = variant.generatePromotionMoves(
        base: m,
        state: state,
        pieceType: pieceType,
      );
      if (mm != null) moves.addAll(mm);
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
      if (options.onlySquare != null && m.to == options.onlySquare) {
        exit = true;
      }
    }

    // Generate normal moves
    for (MoveDefinition md in pieceType.moves) {
      if (exit) break;
      if (!md.capture && !options.quiet) continue;
      if (!md.quiet && !options.captures) continue;
      if (options.onlySquare != null &&
          md.excludeMove(square, options.onlySquare!, dirMult, size)) {
        continue;
      }
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
        // * All squares between the rook and the king's target must be free.
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
          int numRookMidSquares = (targetFile - rookFile).abs();
          if (numRookMidSquares > 1) {
            for (int j = 1; j <= numRookMidSquares; j++) {
              int midFile = rookFile + (i == 0 ? -j : j);
              int midSq = size.square(midFile, royalRank);
              if (board[midSq].isNotEmpty) {
                valid = false;
                break;
              }
            }
          }
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
  List<GatingMove> generateGatingMoves(StandardMove base) {
    if (state.gates == null || state.gates!.isEmpty) return [];
    int gFile = size.file(base.from);
    Square piece = board[base.from];
    Colour colour = piece.colour;
    if (piece.isEmpty) return [];
    if (!(state.virginFiles[colour].contains(gFile))) return [];
    List<GatingMove> moves = [];
    void addGatingMove(int p) {
      moves.add(GatingMove(child: base, dropPiece: p));
      if (base.castling) {
        moves.add(
          GatingMove(child: base, dropPiece: p, dropOnRookSquare: true),
        );
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

  /// Checks if [square] is attacked by [player].
  /// Works by generating all legal moves for the other player, and therefore is slow.
  bool isAttacked(int square, int player) {
    List<Move> attacks =
        generatePlayerMoves(player, MoveGenParams.squareAttacks(square));
    return attacks.isNotEmpty;
  }

  /// Check if [player]'s king is currently attacked.
  bool kingAttacked(int player) => state.royalSquares[player] != Bishop.invalid
      ? isAttacked(state.royalSquares[player], player.opponent)
      : false;

  /// Finds all the pieces for [player] attacking [square].
  /// Returns a list of the squares those pieces are on.
  Set<int> getAttackers(int square, int player) =>
      generatePlayerMoves(player, MoveGenParams.squareAttacks(square, false))
          .map((e) => e.from)
          .toSet();

  /// Finds all pieces attacking [player]'s king.
  /// Returns a list of the squares those pieces are on.
  Set<int> getKingAttackers(int player) =>
      getAttackers(state.royalSquares[player], player.opponent);

  /// Check the number of times the current position has occurred in the hash table.
  int get hashHits => zobrist.hashHits(state.hash);
}
