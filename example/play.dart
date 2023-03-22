import 'dart:io';
import 'dart:math';

import 'package:bishop/bishop.dart';
import 'package:colorize/colorize.dart';

import 'json.dart';

void main(List<String> args) async {
  while (variant == null) {
    selectVariant();
  }
  while (colour == null) {
    selectColour();
  }
  selectUseEngine();
  printYellow(
    '''Enter your moves as algebraic strings, e.g. b1c3, e7e8q, etc.
    \'moves\': list available moves.
    \t'moves from [square]': list all moves starting at [square].
    \t'moves to [square]': list all moves ending on [square].
    \t'moves captures': list all capture moves.
    \t'moves quiet': list all non-capture moves.
    \'resign\': resign.
    \'pgn\': prints the PGN so far.
    \'history\': prints move history in algebraic form.
    \'random\': make a random move.
    ''',
  );
  game = Game(variant: variant!);
  if (useEngine) engine = Engine(game: game);
  while (!game.gameOver) {
    if (printState) {
      List<String>? hands = game.variant.handsEnabled
          ? game.handSymbols.map((e) => e.join(' ')).toList()
          : null;
      if (hands != null) print('Hand: ${hands.last}');
      print(game.ascii());
      if (hands != null) print('Hand: ${hands.first}');
      printCyan(game.fen);
    }
    printState = true;
    if (game.turn == colour!) {
      handlePlayerInput();
      if (resigned) break;
    } else {
      bool success = await makeAiMove();
      if (!success) {
        print('game over');
        break;
      }
    }
  }

  printMagenta(game.ascii());
  printCyan(game.fen);
  printPgn();
  printHistory();
  printCyan('Result: ${game.result?.readable}');
}

bool printState = true;
bool resigned = false;

void printPgn() => printYellow(game.pgn());
void printHistory() => printYellow(game.moveHistoryAlgebraic.join(' '));
void printMoves() => printYellow(game.algebraicMoves().join(', '));
void printCaptures() => printYellow(
      game.generateLegalMoves().captures.toAlgebraic(game).join(', '),
    );
void printQuiet() => printYellow(
      game.generateLegalMoves().quiet.toAlgebraic(game).join(', '),
    );
void printMovesFrom(String sq) => variant!.boardSize.isValidSquareName(sq)
    ? printYellow(
        game
            .generateLegalMoves()
            .from(variant!.boardSize.squareNumber(sq))
            .toAlgebraic(game)
            .join(', '),
      )
    : printRed('Invalid square \'$sq\'');
void printMovesTo(String sq) => variant!.boardSize.isValidSquareName(sq)
    ? printYellow(
        game
            .generateLegalMoves()
            .to(variant!.boardSize.squareNumber(sq))
            .toAlgebraic(game)
            .join(', '),
      )
    : printRed('Invalid square \'$sq\'');

void handlePlayerInput() {
  final String input = (stdin.readLineSync() ?? '').toLowerCase();
  if (input == 'pgn') {
    printState = false;
    printPgn();
    return;
  }
  if (input == 'history') {
    printState = false;
    printHistory();
    return;
  }
  if (input == 'moves') {
    printState = false;
    printMoves();
    return;
  }
  if (input.startsWith('moves ')) {
    printState = false;
    final parts = input.split(' ');
    final subcommands = ['from', 'to', 'captures', 'quiet'];
    final subcommand = subcommands.contains(parts[1]) ? parts[1] : null;
    final param = parts.length == 2 ? parts[1] : parts[2];
    switch (subcommand) {
      case 'from':
        printMovesFrom(param);
        return;
      case 'to':
        printMovesTo(param);
        return;
      case 'captures':
        printCaptures();
        return;
      case 'quiet':
        printQuiet();
        return;
      default:
        if (parts.length == 2) {
          printMovesFrom(param);
          return;
        }
        printRed('Invalid subcommand \'${parts[1]}\'');
        return;
    }
  }
  if (input == 'resign') {
    resigned = true;
    return;
  }
  Move? m;
  if (input == 'random' || input == 'r') {
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
    printCyan('Engine thinking...');
    final res = await engine!.search();
    return res.move;
  } else {
    return game.getRandomMove();
  }
}

void selectVariant() {
  printYellow('Select a variant:   (leave blank for standard chess)');
  printCyan(Variants.values.map((e) => e.name).join(', '));
  printMagenta('Enter \'json filename.json\' to load a json variant');
  String input = stdin.readLineSync() ?? '';
  if (input.isEmpty) input = 'standard';
  if (input.startsWith('json')) {
    final json = readJson(input.split(' ').last);
    variant = Variant.fromJson(json);
  } else {
    variant = variantFromString(input);
  }
  if (input == 'random') {
    variant = ([...Variants.values]..shuffle()).first.build();
  }

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
void printMagenta(String text) => print(Colorize(text).lightMagenta());
void printRed(String text) => print(Colorize(text).red());
