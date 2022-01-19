### 0.3.2
- Supprot for fixed gating (e.g. gating in Muskteeer chess)
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
- *buildRandomPosition()* for generating arbitrary random positions, see Variant.miniRandom for an example
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
- *Game.validateFen()* function
- *CastlingOptions.useRookAsTarget*: formats algebraic moves correctly for Chess960

### 0.2.5
- Premove generation
- *Game.loadFen()* function

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
- Added *Game.boardSymbols()*, for use with the **squares** package

### 0.2.0
- Renamed package to Bishop
- Piece drops & hands (Crazyhouse support)

### 0.1.1
- Zobrist hashing & repetition draws

### 0.1.0
- Hello Bishop