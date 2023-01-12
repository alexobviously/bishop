### 1.0.0
- The state of the board is now stored in `BishopState`, instead of a single list in `Game` being modified.

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