import 'betza.dart';
import 'constants.dart';
import 'move_definition.dart';
import 'variant/variant.dart';

/// Specifies a piece type, with all of its moves and attributes.
class PieceType {
  /// A Betza notation string that defines the piece.
  /// See: https://www.gnu.org/software/xboard/Betza.html
  final String? betza;

  /// All of the different move groups this piece can make.
  final List<MoveDefinition> moves;

  /// Royal pieces can be checkmated, and can castle.
  final bool royal;

  /// Whether this piece type can be promoted.
  final bool promotable;

  /// Whether this piece type can be promoted to by a promotable piece.
  final bool canPromoteTo;

  /// Whether this piece can set the en passant flag.
  final bool enPassantable;

  /// If true, the piece symbol will be omitted in SAN representations of moves.
  /// For example, pawn moves should be like 'b4', rather than 'Pb4'.
  final bool noSanSymbol;

  /// The value of the piece, in centipawns (a pawn is 100).
  /// Can be overridden in a `Variant`.
  final int value;

  const PieceType({
    this.betza,
    required this.moves,
    this.royal = false,
    this.promotable = false,
    this.canPromoteTo = true,
    this.enPassantable = false,
    this.noSanSymbol = false,
    this.value = DEFAULT_PIECE_VALUE,
  });

  /// Initialise the `PieceType`.
  void init(BoardSize boardSize) {
    for (MoveDefinition m in moves) {
      m.normalised = m.direction.v * boardSize.h * 2 + m.direction.h;
      if (m.lame) {
        m.lameDirection = Direction(m.direction.h ~/ 2, m.direction.v ~/ 2);
        m.lameNormalised = m.lameDirection!.v * boardSize.north + m.lameDirection!.h;
      }
    }
  }

  factory PieceType.empty() => PieceType(moves: [], canPromoteTo: false);

  /// Generate a piece type with all of its moves from [Betza notation](https://www.gnu.org/software/xboard/Betza.html).
  factory PieceType.fromBetza(
    String betza, {
    bool royal = false,
    bool promotable = false,
    bool canPromoteTo = true,
    bool enPassantable = false,
    bool noSanSymbol = false,
    int value = DEFAULT_PIECE_VALUE,
  }) {
    List<Atom> atoms = Betza.parse(betza);
    List<MoveDefinition> moves = [];
    for (Atom atom in atoms) {
      for (Direction d in atom.directions) {
        MoveDefinition md = MoveDefinition(
          direction: d,
          range: atom.range,
          modality: atom.modality,
          enPassant: atom.enPassant,
          firstOnly: atom.firstOnly,
          lame: atom.lame,
        );
        moves.add(md);
      }
    }
    return PieceType(
      betza: betza,
      moves: moves,
      royal: royal,
      promotable: promotable,
      canPromoteTo: canPromoteTo,
      enPassantable: enPassantable,
      noSanSymbol: noSanSymbol,
      value: value,
    );
  }

  factory PieceType.knight() => PieceType.fromBetza('N', value: 300);
  factory PieceType.bishop() => PieceType.fromBetza('B', value: 300);
  factory PieceType.rook() => PieceType.fromBetza('R', value: 500);
  factory PieceType.queen() => PieceType.fromBetza('Q', value: 900);
  factory PieceType.king() => PieceType.fromBetza('K', royal: true, canPromoteTo: false);
  factory PieceType.pawn() => PieceType.fromBetza(
        'fmWfceFifmnD',
        promotable: true,
        enPassantable: true,
        canPromoteTo: false,
        noSanSymbol: true,
        value: 100,
      ); // seriously

  /// A pawn with no double move and no en passant.
  factory PieceType.simplePawn() => PieceType.fromBetza(
        'fmWfcF',
        promotable: true,
        canPromoteTo: false,
        noSanSymbol: true,
        value: 100,
      );
  factory PieceType.knibis() => PieceType.fromBetza('mNcB');
  factory PieceType.biskni() => PieceType.fromBetza('mBcN');
  factory PieceType.kniroo() => PieceType.fromBetza('mNcR');
  factory PieceType.rookni() => PieceType.fromBetza('mRcN');
  factory PieceType.bisroo() => PieceType.fromBetza('mBcR');
  factory PieceType.roobis() => PieceType.fromBetza('mRcB');
  factory PieceType.archbishop() => PieceType.fromBetza('BN', value: 900);
  factory PieceType.chancellor() => PieceType.fromBetza('RN', value: 900);
  factory PieceType.amazon() => PieceType.fromBetza('QN', value: 1200);
}

/// A definition of a `PieceType`, specific to a `Variant`.
/// You don't ever need to build these, they are generated in variant initialisation.
class PieceDefinition {
  final PieceType type;
  final String symbol;
  final int value;

  @override
  String toString() => 'PieceDefinition($symbol)';

  const PieceDefinition({
    required this.type,
    required this.symbol,
    required this.value,
  });

  factory PieceDefinition.empty() =>
      PieceDefinition(type: PieceType.empty(), symbol: '.', value: 0);

  String char(Colour colour) => colour == WHITE ? symbol.toUpperCase() : symbol.toLowerCase();
}
