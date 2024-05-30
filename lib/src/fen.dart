import 'package:bishop/bishop.dart';

// WARNING: almost everything in this file is temporary and slightly cursed.
// I plan to totally restructure position loading etc in the near future,
// but for now all these structures are necessary.

/// Load a position from a FEN string.
/// If [strict] is enabled, a full string must be provided, including turn,
/// ep square, etc.
ParseFenResult parseFen({
  required String fen,
  required BuiltVariant variant,
  bool strict = false,
  bool initialPosition = false,
  int? seed,
}) {
  List<int>? initialBoard;
  if (!initialPosition) {
    initialBoard = parseFen(
      fen: variant.data.getStartPosition(seed: seed),
      variant: variant,
      initialPosition: true,
    ).state.board;
  }
  bool squareHasInitialPiece(int square, int piece) =>
      initialPosition || initialBoard?[square].piece == piece;
  final size = variant.boardSize;
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
  String castlingStr = (strict || sections.length > 2) ? sections[2] : '-';
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
      fileStrings.removeAt(fileStrings.length - 1),
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
            throw BishopException('Invalid FEN: gate ($i) overflow'
                '[$c, ${squareIndex + empty - 1}]');
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
  List<int> castlingSquares = List.filled(Bishop.numPlayers, Bishop.invalid);

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
        throw ('Invalid FEN: rank overflow [$c, $sq]');
      }
      // it's a piece
      int pieceIndex = pieceLookup[symbol]!;
      Colour colour = c == symbol ? Bishop.white : Bishop.black;
      if (symbol == '*') colour = Bishop.neutralPassive; // todo: not this
      Square piece = makePiece(pieceIndex, colour);
      board[sq] = squareHasInitialPiece(sq, piece)
          ? piece.setInitialState(true)
          : piece;
      pieces[piece.piece]++;
      if (variant.pieces[pieceIndex].type.royal) {
        royalSquares[colour] = sq;
      }
      if (variant.pieces[pieceIndex].type.castling) {
        castlingSquares[colour] = sq;
      }
      sq++;
    }
  }

  List<List<int>> virginFiles = [[], []];
  if (variant.outputOptions.virginFiles) {
    String castlingStrMod = castlingStr; // so we can modify _castling in place
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
  final castling = variant.castling
      ? setupCastling(
          castlingString: castlingStr,
          castlingSquares: castlingSquares,
          board: board,
          variant: variant,
        )
      : CastlingSetup.none;
  final state = BishopState(
    board: board,
    turn: turn,
    halfMoves: int.parse(halfMoves),
    fullMoves: int.parse(fullMoves),
    epSquare: ep,
    castlingRights: castling.castlingRights,
    royalSquares: royalSquares,
    castlingSquares: castlingSquares,
    virginFiles: virginFiles,
    hands: hands,
    gates: gates,
    pieces: pieces,
    checks: checks,
    meta: StateMeta(variant: variant),
  );
  return ParseFenResult(state, castling);
}

class ParseFenResult {
  final BishopState state;
  final CastlingSetup castling;
  const ParseFenResult(this.state, this.castling);
}

class CastlingSetup {
  final int castlingRights;
  final int? castlingFile;
  final int? castlingTargetK;
  final int? castlingTargetQ;
  final List<String>? castlingFileSymbols;

  const CastlingSetup({
    required this.castlingRights,
    this.castlingFile,
    this.castlingTargetK,
    this.castlingTargetQ,
    this.castlingFileSymbols,
  });

  static const none = CastlingSetup(castlingRights: 0);
}

CastlingSetup setupCastling({
  required String castlingString,
  required List<int> castlingSquares,
  required List<int> board,
  required BuiltVariant variant,
}) {
  if (castlingString == '-') {
    return CastlingSetup.none;
  }
  if (!isAlpha(castlingString) ||
      (castlingString.length > 4 && !variant.outputOptions.virginFiles)) {
    throw ('Invalid castling string');
  }
  List<String>? castlingFileSymbols;
  int? castlingFile;
  int? castlingTargetK;
  int? castlingTargetQ;
  final size = variant.boardSize;
  CastlingRights cr = 0;
  for (String c in castlingString.split('')) {
    // there is probably a better way to do all of this
    bool white = c == c.toUpperCase();
    castlingFile = size.file(castlingSquares[white ? 0 : 1]);
    if (Castling.symbols.containsKey(c)) {
      cr += Castling.symbols[c]!;
    } else {
      int cFile = fileFromSymbol(c);
      bool kingside = cFile > size.file(castlingSquares[white ? 0 : 1]);
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
        if (piece == variant.castlingPiece) {
          kingside = true;
        } else if (piece == variant.rookPiece) {
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
    String k = castlingTargetK != null ? fileSymbol(castlingTargetK) : 'k';
    String q = castlingTargetQ != null ? fileSymbol(castlingTargetQ) : 'q';
    castlingFileSymbols = [k.toUpperCase(), q.toUpperCase(), k, q];
  }
  return CastlingSetup(
    castlingRights: cr,
    castlingFile: castlingFile,
    castlingTargetK: castlingTargetK,
    castlingTargetQ: castlingTargetQ,
    castlingFileSymbols: castlingFileSymbols,
  );
}
