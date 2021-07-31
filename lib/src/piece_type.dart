import 'betza.dart';
import 'constants.dart';
import 'move_definition.dart';
import 'variant/variant.dart';

class PieceType {
  final String? betza;
  final List<MoveDefinition> moves;
  final bool royal;
  final bool promotable;
  final bool canPromoteTo;
  final bool enPassantable;
  final bool noSanSymbol; // for pawns, e.g. b4 instead of Pb4

  PieceType({
    this.betza,
    required this.moves,
    this.royal = false,
    this.promotable = false,
    this.canPromoteTo = true,
    this.enPassantable = false,
    this.noSanSymbol = false,
  });

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
  factory PieceType.fromBetza(
    String betza, {
    bool royal = false,
    bool promotable = false,
    bool canPromoteTo = true,
    bool enPassantable = false,
    bool noSanSymbol = false,
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
    );
  }

  factory PieceType.knight() => PieceType.fromBetza('N');
  factory PieceType.bishop() => PieceType.fromBetza('B');
  factory PieceType.rook() => PieceType.fromBetza('R');
  factory PieceType.queen() => PieceType.fromBetza('Q');
  factory PieceType.king() => PieceType.fromBetza('K', royal: true, canPromoteTo: false);
  factory PieceType.pawn() => PieceType.fromBetza(
        'fmWfceFifmnD',
        promotable: true,
        enPassantable: true,
        canPromoteTo: false,
        noSanSymbol: true,
      ); // seriously
  factory PieceType.knibis() => PieceType.fromBetza('mNcB');
  factory PieceType.biskni() => PieceType.fromBetza('mBcN');
  factory PieceType.kniroo() => PieceType.fromBetza('mNcR');
  factory PieceType.rookni() => PieceType.fromBetza('mRcN');
  factory PieceType.archbishop() => PieceType.fromBetza('BN');
  factory PieceType.chancellor() => PieceType.fromBetza('RN');
  factory PieceType.amazon() => PieceType.fromBetza('QN');
}

class PieceDefinition {
  final PieceType type;
  final String symbol;

  PieceDefinition({required this.type, required this.symbol});
  factory PieceDefinition.empty() => PieceDefinition(type: PieceType.empty(), symbol: '.');

  String char(Colour colour) => colour == WHITE ? symbol.toUpperCase() : symbol.toLowerCase();
}
