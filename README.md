<p align="center">
<img src="https://raw.githubusercontent.com/alexobviously/bishop/master/images/banner.png" height="100" alt="Bishop" />
</p>

#### A chess logic package with flexible variant support.

Bishop is designed with flexibility in mind. The goal is to be able to build and play any arbitrary variant of chess without having to build a new package every time. It supports a variety of fairy piece variants, with pieces that move in unconventional ways, and piece definition with Betza notation. It also supports variants with altered rules, such as King of the Hill and Atomic chess, Asian games like Xiangqi, and variants with various implementations of hands and gating like Crazyhouse, Seirawan and Musketeer. It's also possible to implement fairly complex custom logic with the actions system.

Of course, it also supports standard chess.

Bishop is written in pure dart with no dependencies.

Take a look at the [Squares](https://pub.dev/packages/squares) package for a Flutter chessboard widget
designed to be interoperable with Bishop.

Feel free to request variants or rules - just [create an issue](https://github.com/alexobviously/bishop/issues).


## Contents
[Feature Overview](#features)

[Basic Functionality](#a-random-game)

[Move Generation](#move-generation)

[Piece Defintion](#piece-definition)

[Variant Defintion](#variant-definition)

[Regions](#regions)

[Actions](#actions)

[JSON Serialisation](#json-serialisation)

***

## Features 
* Game logic - making moves, detecting end conditions, etc
* Legal move generation
* FEN & PGN input and output
* Easy and flexible variant definition
* Importing and exporting variants as JSON for portability
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
* Forced captures (e.g. Antichess)
* Different game end conditions for variants like Three-Check, Racing Kings or King of the Hill
* Board regions for piece movement restriction (e.g. Xiangqi palaces), piece behaviour changes (e.g. Xiangqi soldier) and win conditions (e.g. King of the Hill)
* A basic engine that works with any definable variant (not strong but fine for testing)

### Planned Features
* Janggi, Shogi and their variants
* Draughts, and chained moves in general
* Support for Bughouse, and similar games
* Chasing rules, such as those Xiangqi has
* Pieces with multi-leg moves
* Variants with multiple moves per turn (e.g. double move, Duck Chess)
* A lot more: see the [issue tracker](https://github.com/alexobviously/bishop/issues) and feel free to submit your own requests

### Built-in Variants
There are over 50 built-in variants in total.  
Chess, Chess960, Crazyhouse, Atomic, Horde, Racing Kings, Antichess, Capablanca, Grand, Seirawan, Three Check, King of the Hill, Musketeer, Xiangqi (+ Mini Xiangqi & Manchu), Three Kings, Kinglet, Hoppel-Poppel, Orda (+ Mirror), Shako, Dobutsu, Andernach, Jeson Mor, a variety of small board variants, and many more.

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

There are lots of examples in [piece_type.dart](https://github.com/alexobviously/bishop/blob/master/lib/src/piece_type.dart) to learn from, but here's a basic rundown.

### Movement Atoms

Single capital letters represent a basic movement direction. Here are the basic directions:

```
G Z C H C Z G     W = Wazir     (1,0)
Z A N D N A Z     F = Ferz      (1,1)
C N F W F N C     D = Dabbaba   (2,0)
H D W * W D H     N = Knight    (2,1)
C N F W F N C     A = Alfil     (2,2)
Z A N D N A Z     C = Camel     (3,1)
G Z C H C Z G     Z = Zebra     (3,2)
```

These can be combined like `NC`, which would define the Unicorn from Musketeer Chess, which moves as either a Knight or a Camel. There is also the `K` (king) shorthand, which is equal to `WF`.

Bishop's implementation of Betza parsing also supports directional atoms in parentheses like `(4,1)` (the 'Giraffe'), so a Knight could also be defined as `PieceType.fromBetza('(2,1)')` (or `(1,2)`).

Bishop also implements a special movement atom `*`, which means movement to any square on the board is allowed. This is not part of any Betza standard, but I hereby propose it! It allows defining the Duck from [Duck Chess](https://www.chess.com/terms/duck-chess) as `m*`.

### Move Modality

By default, any atoms specified will produce both quiet (non-capturing) and capturing moves. The modifiers `m` and `c` specify moves that either only capture or never capture. For example, `mNcB` defines a 'Knibis', a piece that moves like a knight but captures like a bishop.

### Range

The range of a movement atom is specified by a number after it. For example, `F2` means a piece that can move two squares diagonally.  
* The range is taken to be 1 by default, so `W` is the same as `W1`.  
* 0 means infinite range, so `W0` is a rook.  
* This works for any atom! So `N0` is a 'Nightrider', a piece that can make many Knight moves in the same direction. `(4,1)2` makes one or two Giraffe moves (although you would need a huge board for this to be useful).  
* Pieces with range are known as 'sliders', and they can be blocked, i.e. they can't jump over pieces.  
* Shorthands `R`, `B` and `Q` (rook, bishop and queen) are equal to `W0`, `F0` and `W0F0` (or `RB`) respectively.  
* The old Betza repeated atom shorthand, e.g. `WW` meaning `W0` is _considered obsolete and does not work in Bishop_.  

### Directional Modifiers

What if you want a knight that can only move forward, like the [Shogi Knight](https://en.wikipedia.org/wiki/Shogi#Movement)? That can be defined with `fN`. A rook that only moves horizontally is `sR`. A bishop that only moves right is `rB`.

More complex directional modifiers are available, like `fsN` - a knight that only moves forwards but only on the horizontal moves, or `rbN`, a knight that only moves to one square behind it on the right (from d4 to e2).\

I won't go through all of the modifiers here because there are a lot. See the Betza [reference](https://www.gnu.org/software/xboard/Betza.html).

### Functional Modifiers

* `n` (lame leaper/non-jumper): moves with this modifier cannot jump over pieces. For example, `nN` is the Xiangqi knight - it moves like a chess knight, but if there is a piece in the way in the longer direction, it cannot make the move.
* `i` (first move only): atoms with this modifier can only be made if it is the piece's first move.
* `e` (en-passant): atoms with this modifier can capture en-passant. This modifier doesn't exclude normal captures.
* `p` (unlimited hopper): applied to sliding moves to change them so that they must jump over a piece. Pieces making these moves can land anywhere after the jump, but _must_ jump over a piece. The most well known example is probably the Xiangqi cannon: `mRcpR` (moves as a rook, captures as a rook but must jump a piece first).
* `g` (limited hopper): like `p`, but the piece can only land on the square directly after the piece it jumps over, like the Grasshopper: `gQ`.

### Combining Modifiers / Example

Modifiers only apply to the atom directly following them. Other than that, the order of operations is unimportant; `igfrR` is the same as `gfriR`. Bear in mind that some of the directional modifiers are two characters long - `fr` is not the same as `rf` (for oblique pieces).

Let's break down the standard chess pawn, since it is surprisingly complicated and probably the inspiration for half of these modifiers.

`'fmWfceFifmnD'`:
* `fmW`: moves orthogonally forward exactly one square (`fW`), doesn't capture this way (`m`).
* `fceF`: captures diagonally forward exactly one square (`fF`), doesn't move this way (`c`), can en-passant (`e`).
* `ifmnD`: moves forward exactly two squares (`fD`), doesn't capture this way (`m`), can be blocked by a piece halfway through the move (`n`), can only make this move as the piece's first move (`i`).

### Things Bishop doesn't support (yet)

Some of the modern Betza notation extensions allow specifying a whole load of other behaviour. Some of these are planned for the relatively near future for Bishop.

Most importantly, chained/multi-leg moves will be included soon.

Some features like the 'destroy own piece' modifier or drop restrictions aren't a priority since Bishop has more flexible ways to define these with things like actions and drop builders. It is possible that some of these will be included as 'shortcuts' that are compiled to actions etc in the variant building process.

As usual, if you're reading this and wishing some specific modifier was included, feel free to file an issue or start a discussion on the repo page.

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
Variant capablanca = Variant.standard().withPieces({
    'A': PieceType.archbishop(),
    'C': PieceType.chancellor(),
  }).copyWith(
    name: 'Capablanca Chess',
    boardSize: BoardSize(10, 8),
    startPosition:
        'rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1',
    castlingOptions: CastlingOptions.capablanca,
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
* Allowing promotion only in a specific area (use `Variant.promotionOptions: RegionPromotion()`).
* Allowing drops only in a specific area.

To define region behaviour, you need one or more `BoardRegion` defintions in `Variant.regions`, and `RegionEffect`s in the pieces you want to use them, using the keys used to define them. For simple rectangular regions, you will usually want `RectRegion` (which also has factory constructors for common cases, e.g. a whole rank, a whole file). There are also `UnionRegion` and `IntersectRegion`, which allow combining multiple regions into one.

A good simple example is the King of the Hill variant, in which a single region is defined in the centre of the board, and when a player moves their king into it, they win.
The definition is below:

```dart
static Variant kingOfTheHill() =>
      Variant.standard().copyWith(name: 'King of the Hill').withPieces({
        'K': PieceType.king().withRegionEffect(
          RegionEffect.winGame(white: 'hill', black: 'hill'),
        ),
      }).withRegion(
        'hill',
        RectRegion(
          startFile: Bishop.fileD,
          endFile: Bishop.fileE,
          startRank: Bishop.rank4,
          endRank: Bishop.rank5,
        ),
      );
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
        RectRegion(startRank: Bishop.rank1, endRank: Bishop.rank4),
    'blackSide':
        RectRegion(startRank: Bishop.rank5, endRank: Bishop.rank8),
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
    'N': PieceType.knight().withAction(pawnAdder),
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

## JSON Serialisation
It's possible to import and export Bishop variants in JSON format, simply use the `Variant.fromJson()` constructor, and export with `Variant.toJson()`. In most cases, this will be straightforward, and require no further configuration.

There are some parameters, namely `PromotionOptions` and `Action` classes, that require type adapters to be registered if custom implementations are built. Note that this isn't necessary if you don't want to use serialisation, and most likely only the most complex apps with user-generated variants will need this. This is relatively straightforward though - simply create a `BishopTypeAdapter` that implements the JSON import and export functionality and include it in either `Variant.adapters` or the `adapters` parameter in `fromJson`/`toJson`. See [example/json.dart](https://github.com/alexobviously/bishop/blob/master/example/json.dart) for a demonstration of how to do this. Also, all built-in variants are included in JSON form in [example/json](https://github.com/alexobviously/bishop/blob/master/example/json) for reference.

Serialisation currently has a few limitations:
* Piece types that aren't built with `PieceType.fromBetza()` aren't supported yet.
* Parameterised conditions in Actions currently cannot be exported, because they are just function closures. For example, `ActionCheckRoyalsAlive` optionally takes a `condition`; if this condition is set, then the action will not be exported with the variant. If it isn't set, then there will be no problems. This will probably result in conditions being refactored into a form that works with type adapters.

***

### Thanks

Thanks to the following projects for inspiration and reference:
- [Pychess](https://github.com/gbtami/pychess-variants)
- [Fairy Stockfish](https://github.com/ianfab/Fairy-Stockfish)
- [Chess.dart](https://pub.dev/packages/chess)