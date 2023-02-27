import 'dart:async';
import 'package:bishop/bishop.dart';

class GameNavigator {
  GameNavigator({
    Game? game,
    Variant? variant,
    String? startPosition,
    bool startAtEnd = false,
  }) : _game = game ?? Game(variant: variant, fen: startPosition) {
    NavigatorNode? cur;
    for (final state in _game.history) {
      final n = NavigatorNode(gameState: state, parent: cur);
      cur?.addChild(n);
      if (cur == null || startAtEnd) line.add(n);
      cur = n;
    }
  }

  factory GameNavigator.fromPgn(String pgn, {bool startAtEnd = false}) =>
      GameNavigator(game: parsePgn(pgn).buildGame(), startAtEnd: startAtEnd);

  final Game _game;
  List<NavigatorNode> line = [];
  NavigatorNode get root => line.first;
  NavigatorNode get current => line.last;
  List<NavigatorNode> get branches => current.children;
  int get index => line.length - 1;
  List<NavigatorNode> get mainLine => root.mainLine;

  late final _streamController = StreamController<NavigatorNode>.broadcast();
  Stream<NavigatorNode> get stream => _streamController.stream;

  void _emitState() => _streamController.add(current);

  NavigatorNode? next({
    int branch = 0,
    bool move = true,
    bool emit = true,
  }) {
    if (current.children.length < branch + 1) return null;
    final node = current.children[branch];
    if (move) {
      line.add(node);
    }
    if (emit) _emitState();
    return node;
  }

  NavigatorNode? previous({
    bool move = true,
    bool emit = true,
  }) {
    if (line.length < 2) return null;
    final node = line[line.length - 2];
    if (move) {
      line.removeLast();
    }
    if (emit) _emitState();
    return node;
  }

  NavigatorNode go(int target, {bool emit = true}) {
    while (index != target) {
      final node = index > target ? previous(emit: false) : next(emit: false);
      if (node == null) break;
    }
    if (emit) _emitState();
    return current;
  }

  NavigatorNode goToStart() => go(0);
  NavigatorNode goToEnd() => go(mainLine.length);
}

class NavigatorNode {
  List<NavigatorNode> children = [];
  NavigatorNode? parent;
  final BishopState gameState;

  MoveMeta? get moveMeta => gameState.meta?.moveMeta;
  String? get moveString => moveMeta != null
      ? '${gameState.moveNumber}. ${gameState.turn == Bishop.white ? '..' : ''}${moveMeta!.prettyName}'
      : null;

  NavigatorNode({
    List<NavigatorNode>? children,
    this.parent,
    required this.gameState,
  }) : children = [...?children];

  void addChild(NavigatorNode child, {int? position}) =>
      position == null ? children.add(child) : children.insert(position, child);

  void addChildFirst(NavigatorNode child) => addChild(child, position: 0);

  void setParent(NavigatorNode parent) => this.parent = parent;

  List<NavigatorNode> get mainLine => [
        this,
        if (children.isNotEmpty) ...children.first.mainLine,
      ];
}
