import 'dart:io';

import 'package:args/args.dart';
import 'package:bishop/bishop.dart';

import 'play.dart';

final parser = ArgParser()
  ..addFlag('ai', abbr: 'a', negatable: false)
  ..addOption('variant', abbr: 'v', defaultsTo: 'chess')
  ..addOption(
    'movelimit',
    abbr: 'l',
    defaultsTo: '200',
    help: 'Number of half moves before game is terminated, 0 is unlimited.',
  )
  ..addOption('pgn', abbr: 'p', help: 'PGN output file')
  ..addFlag('help', abbr: 'h', negatable: false);

void main(List<String> args) async {
  final parsedArgs = parser.parse(args);
  if (parsedArgs['help']) {
    print(parser.usage);
    return;
  }
  String v = parsedArgs['variant'];
  bool ai = parsedArgs['ai'];
  int moveLimit = int.parse(parsedArgs['movelimit']);
  Variant variant = variantFromString(v) ?? Variant.standard();
  print('Starting game with variant ${variant.name}');
  await Future.delayed(const Duration(seconds: 3));
  Game game = Game(variant: variant);
  Engine engine = Engine(game: game);
  int i = 0;

  while (!game.gameOver) {
    String playerName = Bishop.playerName[game.turn];
    print(game.ascii());
    print(game.fen);
    Move? m;
    if (ai) {
      printYellow('~~ $playerName is thinking..');
      EngineResult res = await engine.search();
      printYellow('Best Move: ${formatEngineResult(res, game)}');
      m = res.move;
    } else {
      m = game.getRandomMove();
    }
    if (m == null) {
      printRed('couldn\'t find a move');
    }
    print('$playerName: ${game.toSan(m!)}');
    game.makeMove(m);
    i++;
    if (moveLimit > 0 && i >= moveLimit) break;
  }
  print(game.ascii());
  printYellow(game.pgn());
  printCyan(game.result?.readable ?? 'Game Over (too long)');
  if (parsedArgs['pgn'] != null) {
    final f = File(parsedArgs['pgn']!);
    f.writeAsStringSync(game.pgn(includeVariant: true));
    printMagenta('Wrote PGN to ${parsedArgs['pgn']}');
  }
}

String formatEngineResult(EngineResult res, Game game) {
  if (!res.hasMove) return 'No Move';
  String san = game.toSan(res.move!);
  return '$san (${res.eval}) [depth ${res.depth}]';
}
