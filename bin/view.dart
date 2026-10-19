import 'dart:io';

import 'package:bishop/bishop.dart';

// TODO: rewrite with package:args when we break up packages

void main(List<String> args) {
  bool unicode = false;
  bool showMoves = false;
  String? variantName;
  final positional = <String>[];

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '-h' || arg == '--help') {
      _printUsage();
      exit(0);
    } else if (arg == '-u' || arg == '--unicode') {
      unicode = true;
    } else if (arg == '-m' || arg == '--moves') {
      showMoves = true;
    } else if (arg == '-v' || arg == '--variant') {
      if (i + 1 < args.length) {
        variantName = args[++i];
      } else {
        stderr.writeln('Error: Missing variant name after $arg');
        exit(1);
      }
    } else if (arg.startsWith('--variant=')) {
      variantName = arg.substring('--variant='.length);
    } else {
      positional.add(arg);
    }
  }

  String? fenInput;
  if (positional.isNotEmpty) {
    fenInput = positional.join(' ').trim();
  } else if (!stdin.hasTerminal) {
    fenInput = stdin.readLineSync()?.trim();
  }

  Variant? variant;
  if (variantName != null) {
    final matched = Variants.match(variantName);
    if (matched == null) {
      stderr.writeln('Error: Unknown variant "$variantName".');
      stderr.writeln(
        'Available variants: ${Variants.values.map((v) => v.name).join(', ')}',
      );
      exit(1);
    }
    variant = matched.build();
  }

  Game game;
  try {
    game = Game(
      variant: variant,
      fen: fenInput != null && fenInput.isNotEmpty ? fenInput : null,
    );
  } catch (e) {
    stderr.writeln('Error loading game: $e');
    exit(1);
  }

  print(game.ascii(unicode));
  print('');
  print('FEN:       ${game.fen}');
  print('Turn:      ${game.turn == Bishop.white ? 'White' : 'Black'}');
  print('Castling:  ${game.state.castlingRights.formatted}');
  print('Status:    ${_formatStatus(game)}');

  final moves = game.generateLegalMoves();
  print('Legal:     ${moves.length} moves');
  if (showMoves && moves.isNotEmpty) {
    final sanMoves = moves.map((m) => game.toSan(m, moves: moves)).toList();
    print('\nMoves:\n  ${sanMoves.join(', ')}');
  }
}

String _formatStatus(Game game) {
  if (game.checkmate) {
    return 'Checkmate (${game.turn == Bishop.white ? 'Black' : 'White'} wins)';
  }
  if (game.stalemate) {
    return 'Stalemate (Draw)';
  }
  if (game.inCheck) {
    return 'Check';
  }
  return 'In play';
}

void _printUsage() {
  print('''
Bishop ASCII Board Viewer

Usage:
  bin/view [options] [FEN]

Options:
  -u, --unicode           Render board using Unicode chess glyphs
  -m, --moves             Print all legal moves in SAN
  -v, --variant <name>    Specify chess variant (e.g. chess960, crazyhouse, horde)
  -h, --help              Show this help message

Examples:
  bin/view "r1bq1rk1/pp2npbp/2np2p1/2p5/4P2P/2NPB1P1/PPP1QPB1/R3K2R w KQq - 0 1"
  bin/view -u -m "5rk1/8/8/8/8/8/8/R3K3 w Qq - 0 1"
  echo "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1" | bin/view
''');
}
