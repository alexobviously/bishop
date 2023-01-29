<p align="center">
<img src="https://raw.githubusercontent.com/alexobviously/bishop/master/images/banner.png" height="100" alt="Bishop" />
</p>

#### A chess logic package with flexible variant support.

Bishop is designed with flexibility in mind. The goal is to be able to build and play any arbitrary variant of chess without having to build a new package every time. It supports a variety of fairy piece variants, with pieces that move in unconventional ways, and piece definition with Betza notation. It also supports variants with altered rules, such as King of the Hill and Atomic chess, Asian games like Xiangqi, and variants with various implementations of hands and gating like Crazyhouse, Seirawan and Musketeer. It's also possible to implement fairly complex custom logic with the actions system.

Of course, it also supports standard chess.

Bishop is written in pure dart with no dependencies.

Take a look at the [Squares](https://pub.dev/packages/squares) package for a Flutter chessboard widget
designed to be interoperable with Bishop.


## Contents
[Feature Overview](#features)

[Basic Functionality](#a-random-game)

[Move Generation](#move-generation)

[Piece Defintion](#piece-definition)

[Variant Defintion](#variant-definition)

[Regions](#regions)

[Actions](#actions)

***

## Features 
* Game logic - making moves, detecting end conditions, etc
* Legal move generation
* FEN & PGN input and output
* Easy and flexible variant definition
* Different board sizes
* Fairy pieces
  * Arbitrary move configuration
  * Betza parsing
  * Hoppers like the Xiangqi Cannon
* Hands & dropping
* Versatile promotion handling, supporting cases like optional promotion, piece limits and pieces with different options
* Powerful action system with an accessible API for building custom game logic, for example:
  * Exploding pieces like Atomic chess
  * Spawning pieces on the board, moving existing pieces around
  * Invalidating moves based on arbitrary conditions, e.g. Xiangqi's flying generals rule
* Flex gating (e.g. Seirawan)
* Fixed gating (e.g. Musketeer)
* Different game end conditions for variants like three-check
* Board regions for piece movement restriction (e.g. Xiangqi palaces), piece behaviour changes (e.g. Xiangqi soldier) and win conditions (e.g. King of the Hill)
* A basic engine that works with any definable variant (not strong but fine for testing)

### Planned Features
* Janggi, Shogi and their variants
* Support for Bughouse, and similar games
* JSON import/export for variant portability
* Chasing rules, such as those Xiangqi has

### Built-in Variants
Chess, Chess960/Fischer Random, Crazyhouse, Atomic, Horde, Capablanca, Grand, Seirawan, Three Check, King of the Hill, Musketeer, Xiangqi, and a variety of small board versions of chess.

***

## A Random Game
Playing a random game is easy!
```dart
final game = Game();

while (!game.gameOver) {
    game.makeRandomMove();
}
print(game.ascii());
print(game.pgn());
```

***

## Move Generation
Get a list of legal moves, formatted in SAN notation:
```dart
Game game = Game(variant: Variant.grand());
List<Move> moves = game.generateLegalMoves();
print(moves.map((e) => g.toSan(e)).toList());
```

Pick a move with algebraic notation, and play it:
```dart
Game game = Game();
Move? m = g.getMove('e2e4')!; // returns null if the move isn't found
bool result = game.makeMove(m); // returns false if the move is invalid
```

Start a game from an arbitrary position
```dart
Game game = Game(fen: 'rnbq1bnr/ppppkppp/8/4p3/4P3/8/PPPPKPPP/RNBQ1BNR w - - 2 3');
```

***

## Piece Definition
[Fairy piece types](https://en.wikipedia.org/wiki/Fairy_chess_piece) can be easily defined using [Betza notation](https://www.gnu.org/software/xboard/Betza.html), for example the [Amazon](https://en.wikipedia.org/wiki/Amazon_%28chess%29) can be defined like: `PieceType amazon = PieceType.fromBetza('QN');`. More complicated pieces such as [Musketeer Chess](https://musketeerchess.net/games/musketeer/rules/rules-short.php)'s Fortress can also be easily configured: `PieceType fortress = PieceType.fromBetza('B3vND')`.

If you're feeling particularly adventurous, you can also define a `List<MoveDefinition>` manually and build a `PieceType` with the default constructor.

***

## Variant Definition
Variants can be arbitrarily defined with quite a lot of different options. For example, standard chess is defined like this:
```dart
Variant chess = Variant(
    name: 'Chess',
    boardSize: BoardSize.standard,
    startPosition: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    castlingOptions: CastlingOptions.standard,
    materialConditions: MaterialConditions.standard,
    outputOptions: OutputOptions.standard,
    promotionOptions: PromotionOptions.standard,
    enPassant: true,
    halfMoveDraw: 100,
    repetitionDraw: 3,
    firstMoveRanks: [
      [Bishop.rank2], // white
      [Bishop.rank7], // black
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
};
```
Of course there is a default `Variant.standard()` constructor for this, and other variants can be built based on this too using `Variant.copyWith()`. For example, Capablanca Chess can be defined like this:
```dart
Variant capablanca = Variant.standard().copyWith(
    name: 'Capablanca Chess',
    boardSize: BoardSize(10, 8),
    startPosition:
        'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1',
    castlingOptions: CastlingOptions.capablanca,
    pieceTypes: {
      ...standard.pieceTypes,
      'A': PieceType.archbishop(),
      'C': PieceType.chancellor(),
    },
  );
}
```

For variants such as [Chess960](https://en.wikipedia.org/wiki/Fischer_random_chess), which can start from many positions, a `startPosBuilder` function can be defined, that returns a FEN string. A builder for Chess960 is included.

***

## Regions
It is possible to easily define regions on the board that affect gameplay in certain ways.
Currently supported:
* Winning the game on entering a region. For example, King of the Hill where the game ends when a player's king enters the centre.
* Changing the behaviour of a piece if it's in a region. For example, soldiers in Xiangqi behave differently depending on which side of the river they're on.
* Restricting the movement of pieces. For example, the advisors and generals in Xiangqi that cannot move out of their palace, and elephants that can't cross the river.

To define region behaviour, you need one or more `BoardRegion` defintions in `Variant.regions`, and `RegionEffect`s in the pieces you want to use them, using the keys used to define them.

A good simple example is the King of the Hill variant, in which a single region is defined in the centre of the board, and when a player moves their king into it, they win.
The definition is below:

```dart
factory Variant.kingOfTheHill() {
  final standard = Variant.standard();
  Map<String, PieceType> pieceTypes = {...standard.pieceTypes};
  pieceTypes['K'] = PieceType.fromBetza(
    'K',
    royal: true,
    promoOptions: PiecePromoOptions.none,
    regionEffects: [RegionEffect.winGame(white: 'hill', black: 'hill')],
  );
  return standard.copyWith(
    name: 'King of the Hill',
    pieceTypes: pieceTypes,
    regions: {
      'hill': BoardRegion(
        startFile: Bishop.fileD,
        endFile: Bishop.fileE,
        startRank: Bishop.rank4,
        endRank: Bishop.rank5,
      ),
    },
  );
}
```

Here is a more complex definition of a variant in which bishops cannot leave their side of the board, and knights turn into kniroos (pieces with knight+rook movement) when they cross to the opponent's side:
```dart
final standard = Variant.standard();
Map<String, PieceType> pieceTypes = {...standard.pieceTypes};
pieceTypes['B'] = PieceType.bishop().copyWith(
  regionEffects: [
    RegionEffect.movement(white: 'whiteSide', black: 'blackSide')
  ],
);
pieceTypes['N'] = PieceType.knight().copyWith(
  regionEffects: [
    RegionEffect.changePiece(
      pieceType: PieceType.kniroo(),
      whiteRegion: 'blackSide',
      blackRegion: 'whiteSide',
    )
  ],
);
final v = Variant.standard().copyWith(
  regions: {
    'whiteSide':
        BoardRegion(startRank: Bishop.rank1, endRank: Bishop.rank4),
    'blackSide':
        BoardRegion(startRank: Bishop.rank5, endRank: Bishop.rank8),
  },
  pieceTypes: pieceTypes,
);
```

For a more familiar example of a variant with complex region effects, see the Xiangqi definition.

***

## Actions

### Basics

Actions are used to define complex custom behaviour that is not covered by other parameters. Actions are functions that take the state of the game and a move, and return a list of modifications. These modifications can be things such as adding and removing pieces from hands and gates, setting the result of the game, and most importantly, changing the contents of squares.
Actions can also be used to validate moves with custom logic, allowing for more complex piece behaviour.

Actions have four parameters:
* `event`: What type of event triggers this action.
* `precondition`: A condition that is checked before any action from the triggering event is executed, i.e. it will judge the state of the game as it was before actions started being executed.
* `condition`: A condition that is checked during the sequence of executing actions, i.e. it will judge the state of the game as it is, having been modified by any previous actions in the sequence before it.
* `action`: The function that actually acts on a game state and returns a list of modifications (`ActionEffect`s).

### Conditions

Note that it's also possible to include the behaviour of `condition` in `action`, by simply checking it in there and returning an empty list. The existence of `condition` is for ease of use, while `precondition` is primarily for efficiency.

In general, if your condition does not depend on the outcome of previous actions (likely the case unless your variant has several actions), then you should put it in `precondition`.

A condition is a function that takes in an `ActionTrigger` and returns a `bool`, which determines whether the action will execute. A simple example:
```dart
ActionCondition isCapture = (ActionTrigger trigger) => trigger.move.capture;
```
The above condition will allow its following action to execute if the move triggering the condition is a capture. Since this action doesn't depend on the state of the board, only the move, it can always be a `precondition`.

### Action Functions

Now to actually enacting effects from actions!

Here's an example of an `ActionDefinition` that adds a pawn to the moving player's hand:
```dart
ActionDefinition addPawnToHand = (ActionTrigger trigger) => [
  EffectAddToHand(
    trigger.piece.colour,
    trigger.variant.pieceIndexLookup['P']!,
  ),
];
```
Pretty simple, right? It returns a list of effects that tell Bishop how you want to modify the state. These handle all the logical intricacies, such as tracking pieces and modifying hashes, to make the process of building actions simpler. In this case the list returns a single `EffectAddToHand` that adds the piece with symbol `P` to the moving player's (`trigger.piece.colour`'s) hand.

This can then be put together in an `Action` for a variant like this:
```dart
Action pawnAdder = Action(
  event: ActionEvent.afterMove,
  action: addPawnToHand,
),

Variant v = Variant.standard().copyWith(
  actions: [pawnAdder], 
  handOptions: HandOptions.enabledOnly,
);
```

### Piece-specific actions

Let's say we want a pawn to be added to the player's hand as defined above, but only when a Knight is moved. This can obviously be achieved by modifying the function, or adding a condition, but Bishop also offers another API for this common use case.

```dart
Variant v = Variant.standard().copyWith(
  pieceTypes: {
    'N': PieceType.knight().copyWith(actions: [pawnAdder]),
    /// ...all other piece types
  },
  handOptions: HandOptions.enabledOnly,
);
```

For reference, the other way to do this would be to keep the action in `Variant.actions` and define it as:
```dart
Action pawnAdder = Action(
  event: ActionEvent.afterMove,
  precondition: Conditions.movingPieceIs('N'),
  action: addPawnToHand,
),
```

It's basically a matter of taste which of these you decide to use.

If you want to see more complex examples, look at `Action.flyingGenerals` (Xiangqi's rule that prevents the generals from facing each other), and `Variant.atomic` (a variant in which pieces explode on capture).

***

### Thanks

Thanks to the following projects for inspiration and reference:
- [Pychess](https://github.com/gbtami/pychess-variants)
- [Fairy Stockfish](https://github.com/ianfab/Fairy-Stockfish)
- [Chess.dart](https://pub.dev/packages/chess)