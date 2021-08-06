# Bishop
#### A chess logic package with flexible variant support.

Bishop is designed with flexibility in mind. The goal is to be able to build and play any arbitrary variant of chess without having to build a new package every time. Right now, this is limited to mostly fairy variants, but support for more complex rules such as drops is coming soon.

As a result of the amount of generalisation required to make a package like this work, performance does take a bit of a hit. As such, it might be difficult to build a strong engine with this. However, it's perfectly sufficient for logic generation and validation, etc. Hopefully the performance can be improved in the future though - this is a work in progress!

Bishop is written in pure dart with no dependencies.

### Features 
* Game logic - making moves, detecting end conditions, etc
* Legal move generation
* FEN & PGN input and output
* Easy and flexible variant definition
* Fairy pieces
* Hands & dropping
* An engine (not strong but fine for testing)

### Upcoming Features
* Insufficient material draws
* Hopper pieces (e.g. Xiangqi cannon)
* X-FEN output (input works)
* Piece gating (e.g. Seirawan Chess)

### A Random Game
Playing a random game is easy!
```dart
Game game = Game(variant: Variant.standard());

while (!game.gameOver) {
    game.makeRandomMove();
}
print(game.ascii());
print(game.pgn());
```

### Generating and Making Moves
Get a list of legal moves, formatted in SAN notation:
```dart
Game game = Game(variant: Variant.grand());
List<Move> moves = game.generateLegalMoves();
print(moves.map((e) => g.toSan(e)).toList());
```

Pick a move with algebraic notation, and play it:
```dart
Game game = Game(variant: Variant.standard());
Move? m = g.getMove('e2e4')!; // returns null if the move isn't found
bool result = game.makeMove(m); // returns false if the move is invalid
```

Start a game from an arbitrary position
```dart
Game game = Game(variant: Variant.standard(), fen: 'rnbq1bnr/ppppkppp/8/4p3/4P3/8/PPPPKPPP/RNBQ1BNR w - - 2 3');
```

### Piece Definition
[Fairy piece types](https://en.wikipedia.org/wiki/Fairy_chess_piece) can be easily defined using [Betza notation](https://www.gnu.org/software/xboard/Betza.html), for example the [Amazon](https://en.wikipedia.org/wiki/Amazon_%28chess%29) can be defined like: `PieceType amazon = PieceType.fromBetza('QN');`. More complicated pieces such as [Musketeer Chess](https://musketeerchess.net/games/musketeer/rules/rules-short.php)'s Fortress can also be easily configured: `PieceType fortress = PieceType.fromBetza('B3vND')`.

If you're feeling particularly adventurous, you can also define a `List<MoveDefinition>` manually and build a `PieceType` with the default constructor.

### Variant Definition
Variants can be arbitrarily defined with quite a lot of different options. For example, standard chess is defined like this:
```dart
Variant chess = Variant(
  name: 'Chess',
  boardSize: BoardSize.standard(),
  startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  castlingOptions: CastlingOptions.standard(),
  outputOptions: OutputOptions.standard(),
  promotion: true,
  promotionRanks: [RANK_1, RANK_8],
  enPassant: true,
  halfMoveDraw: 100,
  firstMoveRanks: [
    [RANK_2], // white
    [RANK_7], // black
  ],
  pieceTypes: {
    'P': PieceType.pawn(),
    'N': PieceType.knight(),
    'B': PieceType.bishop(),
    'R': PieceType.rook(),
    'Q': PieceType.queen(),
    'K': PieceType.king(),
  },
);
```
Of course there is a default `Variant.standard()` constructor for this, and other variants can be built based on this too using `Variant.copyWith()`. For example, Capablanca Chess can be defined like this:
```dart
Variant capablanca = Variant.standard().copyWith(
    name: 'Capablanca Chess',
    boardSize: BoardSize(10, 8),
    startPosition: 'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1',
    castlingOptions: CastlingOptions.capablanca(),
    pieceTypes: standard.pieceTypes
    ..addAll({
        'A': PieceType.archbishop(),
        'C': PieceType.chancellor(),
    }),
);
```

For variants such as [Chess960](https://en.wikipedia.org/wiki/Fischer_random_chess), which can start from many positions, a `startPosBuilder` function can be defined, that returns a FEN string. A builder for Chess960 is included.

### Thanks

Thanks to the following projects for inspiration and reference:
- [Pychess](https://github.com/gbtami/pychess-variants)
- [Fairy Stockfish](https://github.com/ianfab/Fairy-Stockfish)
- [Chess.dart](https://pub.dev/packages/chess)