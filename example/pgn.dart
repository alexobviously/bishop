import 'dart:io';

import 'package:bishop/bishop.dart';

void main(List<String> args) async {
  int t1 = DateTime.now().millisecondsSinceEpoch;
  String filename = args.first;
  final data = File(filename).readAsStringSync();
  Map<String, String> metadata = {};
  final r = RegExp(r'(\[(.+)\])+');
  final matches = r.allMatches(data);
  for (final m in matches) {
    String entry = m.group(1)!;
    int splitIndex = entry.indexOf('"');
    String key = entry.substring(1, splitIndex - 1).trim();
    String value = entry.substring(splitIndex + 1, entry.length - 2).trim();
    metadata[key] = value;
  }
  int metaEnd = matches.last.end;
  String game = data.substring(metaEnd).replaceAll('\n', '');
  int i = 0;
  List<String> moves = [];
  Map<int, String> comments = {};
  final numRegex = RegExp(r'([0-9]+\. )');
  while (i < game.length) {
    String substr = game.substring(i);
    if (substr[0] == ' ') {
      i++;
      continue;
    }
    final numMatch = numRegex.firstMatch(substr);
    if (numMatch?.start == 0) {
      i += numMatch!.end;
      continue;
    }
    if (substr[0] == '{') {
      int commentEnd = substr.indexOf('}');
      String comment = substr.substring(1, commentEnd - 1).trim();
      comments[moves.length] = comment;
      i += commentEnd + 1;
      continue;
    }
    int end = substr.indexOf(' ');
    if (end == -1) {
      end = substr.length;
    }
    String move = substr.substring(0, end);
    moves.add(move);
    i += end + 1;
  }
  print(metadata);
  print(moves);
  print(comments);

  print('\n-----\n');
  int t2 = DateTime.now().millisecondsSinceEpoch;

  final g = Game();
  for (String move in moves) {
    g.makeMoveSan(move);
  }
  print(g.ascii());
  print(g.pgn());
  int total = DateTime.now().millisecondsSinceEpoch - t1;
  int parse = t2 - t1;
  int build = total - parse;
  print('Time: ${total}ms (${parse}ms parsing, ${build}ms building)');
}
