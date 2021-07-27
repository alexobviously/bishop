import 'betza.dart';
import 'constants.dart';
import 'move_definition.dart';
import 'variant.dart';

class PieceType {
  final String? betza;
  final List<MoveDefinition> quietMoves;
  final List<MoveDefinition> captureMoves;
  final bool royal;
  final bool promotable;

  PieceType({
    this.betza,
    required this.quietMoves,
    required this.captureMoves,
    this.royal = false,
    this.promotable = false,
  });

  void normalise(BoardSize boardSize) {
    for (MoveDefinition m in quietMoves) {
      m.normalised = m.direction.v * boardSize.h + m.direction.h;
    }
    for (MoveDefinition m in captureMoves) {
      m.normalised = m.direction.v * boardSize.h + m.direction.h;
    }
  }

  factory PieceType.empty() => PieceType(quietMoves: [], captureMoves: []);
  factory PieceType.fromBetza(String betza, {bool royal = false, bool promotable = false}) {
    List<Atom> atoms = Betza.parse(betza);
    List<MoveDefinition> quietMoves = [];
    List<MoveDefinition> captureMoves = [];
    for (Atom atom in atoms) {
      for (Direction d in atom.directions) {
        MoveDefinition md = MoveDefinition(
          direction: d,
          range: atom.range,
          enPassant: atom.enPassant,
          firstOnly: atom.firstOnly,
          lame: atom.lame,
        );
        if (atom.quiet) quietMoves.add(md);
        if (atom.capture) captureMoves.add(md);
      }
    }
    return PieceType(
      betza: betza,
      quietMoves: quietMoves,
      captureMoves: captureMoves,
      royal: royal,
      promotable: promotable,
    );
  }

  factory PieceType.knight() => PieceType.fromBetza('N');
  factory PieceType.bishop() => PieceType.fromBetza('B');
  factory PieceType.rook() => PieceType.fromBetza('R');
  factory PieceType.queen() => PieceType.fromBetza('Q');
  factory PieceType.king() => PieceType.fromBetza('K', royal: true);
  factory PieceType.pawn() => PieceType.fromBetza('fmWfceFifmnD', promotable: true); // seriously
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
