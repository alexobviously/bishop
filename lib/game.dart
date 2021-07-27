import 'variant.dart';

class Game {
  final Variant variant;
  late List<int> board;

  Game({required this.variant}) {
    board = List.filled(variant.boardSize.numSquares, 0);
  }
}
