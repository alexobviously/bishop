import 'dart:convert';
import 'dart:io';

import 'package:bishop/bishop.dart';
import 'package:nice_json/nice_json.dart';

import 'play.dart';

Map<String, dynamic> readJson(String filename) {
  final data = File(filename).readAsStringSync();
  return jsonDecode(data);
}

void writeJson(String filename, Map<String, dynamic> data) {
  final file = File(filename);
  final json = niceJson(data);
  file.writeAsStringSync(json);
}

void main(List<String> args) {
  if (args.isNotEmpty && args.contains('export')) {
    List<String> vlist = [...args];
    vlist.remove('export');
    List<Variants> variants = vlist.isEmpty
        ? Variants.values
        : vlist
            .map(
              (e) => Variants.values
                  .firstWhere((v) => e.toLowerCase() == v.name.toLowerCase()),
            )
            .toList();
    for (Variants v in variants) {
      String filename = 'json/${v.name}.json';
      writeJson(filename, v.build().toJson(verbose: false));
      printMagenta('Wrote $filename');
    }
    return;
  }

  final variant = Variant(
    name: 'Example',
    description: 'An example variant for JSON serialisation',
    boardSize: const BoardSize(3, 5),
    startPosition: 'nkn/ppp/3/PPP/NKN w - - 0 1',
    castlingOptions: CastlingOptions.none,
    enPassant: false,
    pieceTypes: {
      'K': PieceType.king(),
      'N': PieceType.knight(),
      'P': PieceType.simplePawn(),
    },
    actions: [ActionDoesNothing(), ActionDoesNothing(something: 'pawn')],
    adapters: [DoesNothingAdapter()],
  );
  writeJson('example_variant.json', variant.toJson());

  final json = readJson('example_variant.json');
  final v = Variant.fromJson(json, adapters: [DoesNothingAdapter()]);
  print(v.actions);
  Game g = Game(variant: v);
  print(g.ascii());
  print(g.generateLegalMoves().map((e) => g.toSan(e)).toList());
}

class ActionDoesNothing extends Action {
  final String? something;
  ActionDoesNothing({this.something})
      : super(action: ActionDefinitions.pass([]));

  @override
  String toString() => 'ActionDoesNothing($something)';
}

class DoesNothingAdapter extends BishopTypeAdapter<ActionDoesNothing> {
  @override
  String get id => 'example.action.doesNothing';

  @override
  ActionDoesNothing build(Map<String, dynamic>? params) =>
      ActionDoesNothing(something: params?['something']);

  @override
  Map<String, dynamic> export(ActionDoesNothing e) => {
        if (e.something != null) 'something': e.something,
      };
}
