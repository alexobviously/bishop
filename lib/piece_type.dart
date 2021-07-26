import 'betza.dart';
import 'move_definition.dart';

class PieceType {
  final String? betza;
  final List<MoveDefinition> quietMoves;
  final List<MoveDefinition> captureMoves;
  final bool royal;

  PieceType({
    this.betza,
    required this.quietMoves,
    required this.captureMoves,
    this.royal = false,
  });

  factory PieceType.fromBetza(String betza, {bool royal = false}) {
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
    );
  }

  factory PieceType.knight() => PieceType.fromBetza('N');
  factory PieceType.bishop() => PieceType.fromBetza('B');
  factory PieceType.rook() => PieceType.fromBetza('R');
  factory PieceType.queen() => PieceType.fromBetza('Q');
  factory PieceType.king() => PieceType.fromBetza('K', royal: true);
  factory PieceType.pawn() => PieceType.fromBetza('fmWfceFifmnD'); // seriously
  factory PieceType.knibis() => PieceType.fromBetza('mNcB');
}

main(List<String> args) {
  PieceType pt = PieceType.king();
  print(pt.quietMoves);
  print(pt.captureMoves);
}
