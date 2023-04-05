### 1.3.3
- Custom move generation and processing:
  - `MoveGenerator`: optionally supply a list of these in `Variant.moveGenerators`. These can be used to generate custom moves based on the state. You can generate both normal move types (e.g. add an extra move to a piece on a certain square or something), or totally different types of move that can be managed by `MoveProcessor`.
  - `MoveProcessor`: supply a list of these in `Variant.moveProcessors` to process custom move types.
- `StateTransformer`: a way to transform game states based on player perspectives.
  - `Variant.stateTransformer` takes a `StateTransformer` that defines how the state is transformed.
  - `BishopState.transform([int? player])` or `BuiltVariant.transformState()` will return a transformed state (or the same state if there is no transformer). It's possible to define a transformer that takes `player: null` and transforms the state regardless of player. This option exists for cases where you always want to transform
  - `VisionAreaStateTransformer` applies a mask to the board based on a vision radius around pieces. `MaskedState` is a subclass of `BishopState` which contains the [mask] used to create it (for cases where e.g. you want to draw the mask on a board).
  - `HideFlagsStateTransformer` hides the flags for all of the player's or opponent's pieces, depending on configuration.
- King attacks are calculated in advance for mainline moves and can be accessed with `state.meta!.checks!`. They come in the form of a list of squares containing pieces that are attacking the king of each player.
- Gating move logic is no longer part of the standard move logic. `GatingMove` is its own type which contains a child move.

### 1.3.2
- Fixed a castling bug (queenside allowed with piece on b1).
- Various minor improvements to PGN import/export.
- Improvements to `example.dart`: can export PGN and use the engine.
- Fixed some variants not having the 100 half-move rule when they should.
- Variants: Clobber (`MiscVariants.clobber()`) and Clobber 10 (`MiscVariants.clobber10()`).

### 1.3.1
- Further optimisation: excluding piece types early from attack checks (~20% performance boost).

### 1.3.0
- **Bishop is now about 2x faster** thanks to significant optimisations in attack checking.
- Region changes (**breaking**):
  - What used to be `BoardRegion` is now `RectRegion`.
  - `BoardRegion` is now a parent class for `RectRegion` and other board region types.
  - `UnionRegion` and `IntersectRegion` combine multiple `BoardRegions` with union and intersection respectively.
- `RegionPromotion` (`PromotionOptions`): pieces can promote in specific regions.
- `RegionDropBuilder` now allows using region IDs from variant, and separate regions per player (same API as `RegionPromotion`).
- `FirstMoveOptions` (**breaking**): replaces `Variant.firstMoveRanks`, supports more flexible first move options.
- First move checking for most variants no longer uses the rank of the piece. Instead there is an 'initial state' property embedded in the square representation.
  - `FirstMoveOptions.ranks` is still available, and is used by Horde Chess, for example, since not all horde pawns should be double moveable in their initial state.
- Betza parsing now supports `(x,y)` atoms, allowing for pieces jumping more than 3 squares in each direction. For example, the 'Giraffe' is `(4,1)`, and the Knight could be rewritten as `(2,1)` (or `(1,2)`).
- Variants:
  - Legan Chess (`MiscVariants.legan()`): a diagonally arranged chess variant.
  - Grasshopper Chess (`FairyVariants.grasshopper()`): chess with some extra grasshopper pieces.
  - Berolina Chess (`FairyVariants.berolina()`): chess with the Berolina pawn (`PieceType.berolinaPawn()`).
- Fixed PGN parsing on Windows (`\r` related issues).
- A lot of old deprecated constants and functions have been removed.
- The default value of `Variant.castlingOptions` is now `CastlingOptions.none`.
- `play.dart` example: move filtering commands - `moves from x`, `moves to x`, `moves captures`, `moves quiet`.
- `BoardSize.isValidSquareName()`: check if a square name is valid.

### 1.2.10
- Variants:
  - Andernach Chess (`MiscVariants.andernach()`): capturing pieces change colour.
  - Jeson Mor (`MiscVariants.jesonMor()`): knights only, win by entering the central square and leaving it again.
- `ActionTransferOwnership`: changes the colour of the moving piece.
- `ActionExitRegionEnding`: end the game when a piece leaves a region.

### 1.2.9
- Fixed a bug with lame leaper squares being calculated incorrectly.
- Fixed a bug where points-based games could result in draws when the opponent would win regardless next round. `GameResult.soft` defines result types that won't delegalise moves.
- `GameResult.readable`: human-readable string describing the result (e.g. 'White won by checkmate').

### 1.2.8
- Fixed a bug where en passant captured pieces wouldn't increment in `BishopState.pieces`.

### 1.2.7
- `BishopState.capturedPieces()`: used to get the captured pieces in a given state, by comparing to the initial state.

### 1.2.6
- Fixed an issue with parsing PGNs containing clock annotations (thanks @deathcoder).
- Variant: Antichess.
- `Variant.forcedCapture`: defines forced capture rule behaviour.
- `GameEndConditions` changes: `stalemate` and `elimination` are now of type `EndType` instead of `bool`, allowing greater flexibility (win, loss or draw).

### 1.2.5
- Improved efficiency when making moves from SAN strings or parsing PGNs: the check component of the SAN string can now be skipped.

### 1.2.4
- `PieceType.withAction()`, `PieceType.withRegionEffect()`, `Variant.withAction()`, `Variant.withRegion()` fluent helpers.
- `MoveMeta.prettyName` is now `MoveMeta.formatted`.

### 1.2.3
- `GameNavigator`: a helper class that simplifies navigating through a completed game. This is still an early form.
- PGN parsing functionality: `parsePgn()`, `gameFromPgnData()`, `Game.fromPgn()`, `GameNavigator.fromPgn()`.
- `State` now contains a `StateMeta? meta` field: this contains a reference to the variant as well as string representations of moves. This will only be added to mainline moves (i.e. normal calls to `makeMove`, not legality check moves), so it doesn't affect speed, and improves usability.
- Fixed pawns being destroyed by explosions in Atomic Chess.
  - Explosion actions now take an optional list of immune pieces.

### 1.2.2
- `Variant.startPosBuilder` changes: now is a class (`StartPositionBuilder`), so it can be serialised, and start position build functions now take an optional seed.

### 1.2.1
- Fixed a bug that would cause hands parsed from FEN strings to be incorrect.
- Fixed a bug with side-specific oblique moves (e.g. lfN) being mirrored.
- Capturing promoted pieces now behaves as expected, the internal piece type is added to hand, as in Shogi.
- Betza shorthands f, b, l and r are now allowed for oblique moves (behaving as ff, bb, ll, rr).

### 1.2.0
- Refactored `Move` objects, and the logic responsible for making moves in `Game`.
  - `Move` is now an interface that other more specific move types implement.
  - `StandardMove` implements most of the behaviour that the previous `Move` object did.
  - `DropMove` for drops. `PassMove` for the new passing move.
  - Similarly, `MoveDefinition` has been abstracted in the same way, though the implementations don't directly match `Move` implementations.
- Slightly changed the encoding for squares:
  - Colour now has two bits, supporting up to 4 players.
  - Piece type has 8 bits instead of 7, increasing piece limit to 255.
  - A secondary piece type ('internal') is now encoded, also with 8 bits. The primary use case for this is storing the type a piece had before its promotion.
  - 14 bits for flags instead of 4. (46 if you assume your code won't execute on 32 bit vm).
- It's now possible to store custom state variables in the invisible squares outside the board. Technically, it was always possible, but it's now easier to do, and supported.
  - In actions, return an `EffectSetCustomState` to change a state variable. You can define a number of variables equal to the amount of squares on your board, so 64 for a standard chess board.
  - Read these from `trigger.getCustomState()` in triggers, or `Game.getCustomState()` otherwise.
- Support for 'teleport' moves, i.e. moves where the piece can move anywhere on the board. These are built with the Betza atom '*', and support 'c'/'m' modifiers.
- Experimental support for neutral pieces, i.e. pieces that can moved by either player, like the duck in duck chess. Currently the only way to use these is to define a piece with the key '*'.
- `Variant.passOptions`: allow pass moves, where the turn changes but nothing happens. Allows for custom conditions.
- `ActionPointsEnding`: leverages custom state to define a game end condition based on points.
- `ActionImmortality`: allows for pieces of certain types, or with certain flags, to be uncapturable.
- `RegionDropBuilder`: define drop rules that only allow drops within a specified region.
- Variants:
  - Orda (`Orda.orda()`) and Orda Mirror (`Orda.ordaMirror()`).
  - Domination (`MiscVariants.domination()`): keeping pieces in the centre of the board accumulates points for their owner.
  - Dart Chess (`MiscVariants.dart()`): cramped variant on a 6x6 board. Each player has 3 'darts' they can drop onto the board, which block movement and cannot be moved or captured.

### 1.1.2
- `ActionCheckPieceCount`: allows for win conditions based on elimination of arbitrary pieces.
- `Variant.forbidChecks`: if true, it is impossible for anyone to deliver a check.
- Variants:
  - Kinglet (`MiscVariants.kinglet()`): game is won when opponent has no pawns.
  - Three Kings (`MiscVariants.threeKings()`): players have three kings, and capturing any one results in a win.
  - Racing Kings (`CommonVariants.racingKings()`).

### 1.1.1
- Custom drop move generation is now possible with `Variant.handOptions.dropBuilder`.
- Added variant definitions: Mini Xiangqi (`Xiangqi.mini()`), Manchu (`Xiangqi.manchu()`), Hoppel-Poppel (`FairyVariants.hoppelPoppel()`), Shako (`LargeVariants.shako()`), Dobutsu (`Dobutsu.dobutsu()`).
- Fixed a bug in serialisation of pieces with limited promo options.
- Experimental (incomplete) Shogi support.
- `Variant.withCampMate()`: helper method to add the campmate end condition to a variant.
- `Variant.withPieces()` and `Variant.withPiecesRemoved()` helpers.
- The play example can now load JSON variants.

### 1.1.0
- JSON Serialisation support: `Variant.fromJson()` and `Variant.toJson()`.

### 1.0.0
- A powerful new action system with an accessible API for creating custom game logic. Trigger actions on certain events and execute them if their conditions are met.
  - Support for Atomic Chess.
  - Xiangqi flying generals rule implemented.
- Overhaul regarding how promotion works:
  - Promotion move generation is now handled by builder functions, and can be defined in variants with `PromotionOptions`. This allows for more versatile promotion move generation, including cases like limiting the number of pieces of a certain type, conditional promotions, non-rank based promotion areas, etc.
  - `PieceType` definitions now take `PiecePromoOptions` object that encapsulates its promotion behaviour. It is possible to define pieces that only have specific promotion options here (e.g. like Shogi).
  - Grand chess is now working as expected.
- The state of the board is now stored in `BishopState`, instead of a single list in `Game` being modified. This improves code readability and also results in small performance improvements in most cases.
- More descriptive game results. Use `Game.result` to see the exact way the game ended (null if it's still ongoing). Old getters like `Game.checkmate` still exist but `result` is preferred.
- `Variant.gameEndConditions` now takes a `GameEndConditionsSet`, allowing for asymmetric end conditions.
- `GameEndConditions` now allows disabling stalemate (resulting in a loss for the stalemated player), and elimination losses (when all pieces are removed).
  - Support for Horde Chess.
- `Variant.hands` boolean option replaced with `HandOptions`, allowing for variants where hands are enabled but captured pieces aren't added to them (pieces can now be added through actions - see `Variant.spawn()` example).
- `PieceType` and `MoveDefinition` are now immutable, and are normalised with `copyWith` methods instead of mutation.
- Fixed a bug which would invalidate castling moves in Chess960 if the target square was the rook square, and that was attacked (thanks @malaschitz).

### 0.6.4
- Fixed gates being output the wrong way round in FEN strings for fixed gating variants.

### 0.6.3
- Added variant: King of the Hill.
- Support for win regions.
- Added examples/play.dart - interactive CLI application for playing a game.
- Convenience methods on Game - `moveHistory`, `moveHistoryAlgebraic` and `moveHistorySan`.

### 0.6.2
- Switched to standard symbols for Xiangqi, i.e. Elephants are 'B' and Horses are 'N'.

### 0.6.1
- Board regions and region effects - these allow custom behaviour to be defined for pieces that are in specific areas of the board, and the ability to restrict piece types to regions.
- Fixed a bug in gating move generation on non standard sized boards.
- Xiangqi support: variant and piece definitions, regions and effects.
- Fixed a bug where the SAN format for pawn captures might be wrong (thanks @malaschitz).
- Fixed Chess960 castling moves not being generated for kings on g1 (thanks @malaschitz).
- Fixed Crazyhouse bugs: pawns being droppable on the first rank, and promoted pieces not being captured as pawns (thanks @malaschitz).
- Fixed a extremely rare case where a rook on the file of another uncastled rook of the same colour would affect the castling rights of that other rook (thanks @malaschitz).

### 0.6.0
- Support for hopper pieces, such as the Grasshopper and Xiangqi Cannon, and Betza modifiers 'p' and 'g'.
- Fixed a bug with capture only sliding moves not generating correctly.

### 0.5.2
- Fixed a bug in premove generation where quiet moves to opponent occupied squares weren't generating (e.g. pawn step forward onto opponent's piece).
- Added some extension functions for `List<Move>`, for filtering moves more fluently.

### 0.5.1
- Some convenience methods on `Variant`: `pieceSymbols` and `commonPieceSymbols`.
- Built in `CastlingOptions` are now `static const`.
- `CastlingOptions.copyWith()` and `MaterialConditions.copyWith()`;

### 0.5.0
- `Variant` is now an immutable data type, which is converted to `BuiltVariant` when it's used in `Game`.
- `fenBuilder` parameter in `Game` constructor, overrides `variant.startPosBuilder`.
- `Game.makeMoveString()` and `Game.makeMultipleMoves()`.
- `variantFromString()` utility function.

### 0.4.0
- Improved structure and formatting of codebase.
- There are some minor breaking changes, mostly related to CONSTANT_NAMES being changed to camelCase, and otherwise being more logically grouped. Some factory constructors were also changed to static constants, e.g. `MaterialConditions.standard()` is now `MaterialConditions.standard`.

### 0.3.3
- Fixed flex gating not generating no-drop moves
- Added support for variants that end after a number of checks (e.g. Three-Check)

### 0.3.2
- Support for fixed gating (e.g. gating in Muskteeer chess)
- Support for directional modifiers for oblique pieces in Betza parser (e.g. fN is now possible)

### 0.3.1
- Insufficient material draws
- Improved FEN validation
- Fixed a Zobrist hashing bug (on captures)
- Various minor improvements

### 0.3.0
- Gating drops and the Seirawan Chess variant
- Virgin file tracking
- Lots more documentation
- Allow a custom seed to be specified (for Zobrist hashing)
- Fixed SAN for castling with check

### 0.2.10
- Another small variant (mini - 6x6)
- `buildRandomPosition()` for generating arbitrary random positions, see Variant.miniRandom for an example
- Fixed a bug in which drop moves were not being legalised
- Fixed SAN disambiguators for pawns
- Various minor improvements

### 0.2.9
- Fixed FEN validation for small boards
- Added some documentation

### 0.2.8
- Fixed another 960 castling bug (370 / BNRKRBNQ)

### 0.2.7
- Fixed a castling bug in some 960 positions (e.g. 938 / RKRNBBQN)

### 0.2.6
- Support loading incomplete FEN strings
- `Game.validateFen()` function
- `CastlingOptions.useRookAsTarget`: formats algebraic moves correctly for Chess960

### 0.2.5
- Premove generation
- `Game.loadFen()` function

### 0.2.4
- Fixed engine not wanting to checkmate you
- Micro variant

### 0.2.3
- Basic engine
- Fixed CastlingOptions assertion

### 0.2.2
- Mini variant
- Independent side castling (e.g. only queenside for Minichess)
- Piece values

### 0.2.1
- Added `Game.boardSymbols()`, for use with the **squares** package

### 0.2.0
- Renamed package to Bishop
- Piece drops & hands (Crazyhouse support)

### 0.1.1
- Zobrist hashing & repetition draws

### 0.1.0
- Hello Bishop