import 'dart:io';

import 'package:bishop/bishop.dart';
import 'play.dart';

late final GameNavigator navigator;
bool loaded = false;

void main(List<String> args) async {
  stdin.echoMode = false;
  stdin.lineMode = false;
  stdin.asBroadcastStream().listen(_onKey);
  printMagenta('Loading PGN...');
  int t1 = DateTime.now().millisecondsSinceEpoch;
  String filename = args.first;
  final pgn = File(filename).readAsStringSync();
  final pgnData = parsePgn(pgn);
  printRed(pgnData.moves.join(', '));
  navigator = GameNavigator(
    game: pgnData.buildGame(),
  );
  int dur = DateTime.now().millisecondsSinceEpoch - t1;
  printMagenta('Loaded PGN in ${dur}ms');
  printYellow('Use the arrow keys or WASD to navigate. Press q to exit.');
  navigator.stream.listen(_handleNavNode);
  _handleNavNode(navigator.current);
  loaded = true;
}

void _onKey(List<int> charCodes) {
  if (charCodes.first == 113) {
    exit(0);
  }
  if (!loaded) return;
  String charStr = charCodes.join(',');
  if (const ['27,91,68', '65', '97'].contains(charStr)) {
    navigator.previous();
  }
  if (const ['27,91,67', '68', '100'].contains(charStr)) {
    navigator.next();
  }
  if (const ['27,91,65', '87', '119'].contains(charStr)) {
    navigator.goToEnd();
  }
  if (const ['27,91,66', '83', '115'].contains(charStr)) {
    navigator.goToStart();
  }
}

void _handleNavNode(NavigatorNode node) {
  print(node.gameState.ascii());
  if (node.moveMeta != null) {
    printYellow(node.moveString!);
  }
}
