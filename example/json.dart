import 'dart:convert';
import 'dart:io';

import 'package:bishop/bishop.dart';

void main() {
  // final file = File('asd.txt');
  // file.writeAsStringSync('adfag');
  // for (Variants v in Variants.values) {
  //   final file = File('json/${v.name}.json');
  //   final map = v.build().toJson();
  //   final json = JsonEncoder.withIndent(' ').convert(map);
  //   file.writeAsStringSync(json);
  // }
  final f = File('json/xiangqi.json');
  final str = f.readAsStringSync();
  final json = jsonDecode(str);
  // print(json);
  final v = Variant.fromJson(json);
  Game g = Game(variant: v);
  print(g.generateLegalMoves().map((e) => g.toSan(e)).toList());
}
