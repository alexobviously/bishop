import 'dart:io';
import 'dart:math';

import 'package:bishop/bishop.dart';
import 'package:colorize/colorize.dart';

void main(List<String> args) async {
  while (variant == null) {
    selectVariant();
  }
  while (colour == null) {
    selectColour();
  }
  selectUseEngine();
  printYellow(
    'Enter your moves as algebraic strings, e.g. b1c3, e7e8q, etc.\n\'moves\': list available moves.\n\'resign\': resign.\n\'pgn\': prints the PGN so far.\n\'random\': make a random move.',
  );
  game = Game(variant: variant!);
  if (useEngine) engine = Engine(game: game);
  while (!game.gameOver) {
    if (printState) {
      print(game.ascii());
      printCyan(game.fen);
    }
    printState = true;
    if (game.turn == colour!) {
      handlePlayerInput();
    } else {
      bool success = await makeAiMove();
      if (!success) {
        print('game over');
        break;
      }
    }
  }
  print(game.ascii());
  printCyan(game.fen);
  printPgn();
}

bool printState = true;

void printPgn() => printYellow(game.pgn());
void printMoves() => printYellow(game.algebraicMoves().join(', '));

void handlePlayerInput() {
  final String input = (stdin.readLineSync() ?? '').toLowerCase();
  if (input == 'pgn') {
    printState = false;
    printPgn();
    return;
  }
  if (input == 'moves') {
    printState = false;
    printMoves();
    return;
  }
  Move? m;
  if (input == 'random') {
    m = game.getRandomMove();
  } else {
    m = game.getMove(input);
  }
  if (m == null) {
    printRed('Invalid move');
  } else {
    printYellow('${Bishop.playerName[game.turn]}: ${game.toSan(m)}');
    game.makeMove(m);
  }
}

Future<bool> makeAiMove() async {
  Move? m = await getAiMove();
  if (m != null) {
    printYellow('${Bishop.playerName[game.turn]}: ${game.toSan(m)}');
    game.makeMove(m);
    return true;
  }
  return false;
}

Future<Move?> getAiMove() async {
  if (useEngine) {
    final res = await engine!.search();
    return res.move;
  } else {
    return game.getRandomMove();
  }
}

void selectVariant() {
  printYellow('Select a variant:   (leave blank for standard chess)');
  printCyan(Variants.values.map((e) => e.name).join(', '));
  String input = stdin.readLineSync() ?? '';
  if (input.isEmpty) input = 'standard';
  variant = variantFromString(input);

  if (variant == null) {
    printRed('Invalid variant');
  } else {
    printCyan('${variant!.name} selected');
  }
}

void selectColour() {
  printYellow(
    'Play as white or black?   [w or b work, leave blank for random]',
  );
  final input = (stdin.readLineSync() ?? '').toLowerCase();
  if (['w', 'white'].contains(input)) {
    colour = Bishop.white;
  } else if (['b', 'black'].contains(input)) {
    colour = Bishop.black;
  } else if (input.isEmpty) {
    colour = Random().nextInt(2);
  } else {
    printRed('Invalid colour');
  }
  if (colour != null) {
    printCyan('${Bishop.playerName[colour!]} selected');
  }
}

void selectUseEngine() {
  printYellow(
    'Play against an engine?   [y or yes to enable, anything else for random mover]',
  );
  final input = (stdin.readLineSync() ?? '').toLowerCase();
  useEngine = ['y', 'yes'].contains(input);
  printCyan('Playing against ${useEngine ? 'Engine' : 'Random Mover'}');
}

Variant? variant;
int? colour;
late bool useEngine;
Engine? engine;
late Game game;

void printCyan(String text) => print(Colorize(text).cyan());
void printYellow(String text) => print(Colorize(text).yellow());
void printRed(String text) => print(Colorize(text).red());
