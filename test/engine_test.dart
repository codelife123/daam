/// Engine tests for Sri Lankan daam rules.
library;

import 'package:daam/engine/ai.dart';
import 'package:daam/engine/board.dart';
import 'package:daam/engine/game.dart';
import 'package:daam/engine/moves.dart';
import 'package:flutter_test/flutter_test.dart';

int sq(int r, int c) => r * 12 + c;

GameState emptyGame(Side turn) {
  final g = GameState.empty();
  g.turn = turn;
  return g;
}

void main() {
  group('setup', () {
    test('30 pieces per side, white to move', () {
      final g = GameState();
      expect(g.board.countSide(Side.white), 30);
      expect(g.board.countSide(Side.black), 30);
      expect(g.turn, Side.white);
    });

    test('initial position has legal moves for white', () {
      final g = GameState();
      expect(g.moves(), isNotEmpty);
      expect(g.moves().every((m) => !m.isCapture), isTrue);
    });
  });

  group('man movement', () {
    test('man moves diagonally forward only', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteMan);
      final moves = g.moves();
      final tos = moves.map((m) => m.to).toSet();
      // (8,5) is dark; forward for white is dr=-1: (7,4) and (7,6).
      expect(tos, {sq(7, 4), sq(7, 6)});
    });

    test('blocked man has no moves', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteMan);
      g.board.set(sq(7, 4), Pieces.blackMan);
      g.board.set(sq(7, 6), Pieces.blackMan);
      // (7,4) occupied by enemy but landing (6,3) empty -> capture exists
      final moves = g.moves();
      expect(moves.every((m) => m.isCapture), isTrue);
    });
  });

  group('captures', () {
    test('capture is compulsory', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteMan);
      g.board.set(sq(7, 4), Pieces.blackMan); // can be captured
      g.board.set(sq(9, 8), Pieces.whiteMan); // has a quiet move
      final moves = g.moves();
      expect(moves, isNotEmpty);
      expect(moves.every((m) => m.isCapture), isTrue);
    });

    test('maximum capture rule picks longest sequence', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteMan);
      // Short option: jump (7,4) -> (6,3).
      g.board.set(sq(7, 4), Pieces.blackMan);
      // Long option: (8,5) x (7,6) -> (6,7) x (5,8) -> (4,9).
      g.board.set(sq(7, 6), Pieces.blackMan);
      g.board.set(sq(5, 8), Pieces.blackMan);
      // Make sure landing squares are free and paths don't clash.
      final moves = g.moves();
      expect(moves, isNotEmpty);
      expect(moves.every((m) => m.captures == 2), isTrue);
    });

    test('man captures backward', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(6, 5), Pieces.whiteMan);
      g.board.set(sq(7, 4), Pieces.blackMan); // behind the white man
      final moves = g.moves();
      expect(moves.any((m) => m.to == sq(8, 3)), isTrue);
    });

    test('multi-jump removes all captured pieces', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteMan);
      g.board.set(sq(7, 6), Pieces.blackMan);
      g.board.set(sq(5, 8), Pieces.blackMan);
      final moves = g.moves().where((m) => m.captures == 2).toList();
      expect(moves, isNotEmpty);
      g.play(moves.first);
      expect(g.board.at(sq(7, 6)), Pieces.empty);
      expect(g.board.at(sq(5, 8)), Pieces.empty);
      expect(g.board.countSide(Side.black), 0);
    });
  });

  group('kings', () {
    test('flying king slides any distance', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteKing);
      final tos = g.moves().map((m) => m.to).toSet();
      expect(tos.contains(sq(5, 2)), isTrue);
      expect(tos.contains(sq(0, 1)), isFalse); // not on the king's diagonal
      expect(tos.contains(sq(3, 0)), isTrue); // diagonal up-left end
    });

    test('flying king captures from a distance', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteKing);
      g.board.set(sq(5, 2), Pieces.blackMan);
      final caps = g.moves().where((m) => m.isCapture).toList();
      expect(caps, isNotEmpty);
      // King may land on any empty square beyond (5,2): (4,1),(3,0).
      final landings = caps.map((m) => m.to).toSet();
      expect(landings, contains(sq(4, 1)));
      expect(landings, contains(sq(3, 0)));
    });

    test('king cannot jump over own piece', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteKing);
      g.board.set(sq(6, 3), Pieces.whiteMan);
      g.board.set(sq(4, 1), Pieces.blackMan);
      final caps = g.moves().where((m) => m.isCapture).toList();
      expect(caps, isEmpty);
    });
  });

  group('promotion', () {
    test('man promotes on crownhead', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(1, 2), Pieces.whiteMan);
      final moves = g.moves().where((m) => m.to == sq(0, 1)).toList();
      expect(moves, isNotEmpty);
      g.play(moves.first);
      expect(g.board.at(sq(0, 1)), Pieces.whiteKing);
    });

    test('crownhead continue: promotes mid-capture and keeps capturing', () {
      final g = emptyGame(Side.white);
      // White man at (2,5); jumps (1,4)->(0,3) promoting, then as king
      // captures (1,2) landing (2,1)... build a real sequence:
      // (2,5) x (1,4) -> (0,3) [promotes] x (1,2) -> (2,1).
      g.board.set(sq(2, 5), Pieces.whiteMan);
      g.board.set(sq(1, 4), Pieces.blackMan);
      g.board.set(sq(1, 2), Pieces.blackMan);
      final moves = g.moves();
      final seq = moves.where((m) => m.captures == 2).toList();
      expect(seq, isNotEmpty, reason: 'expected a 2-capture sequence, got $moves');
      g.play(seq.first);
      expect(g.board.at(seq.first.to), Pieces.whiteKing);
      expect(g.board.countSide(Side.black), 0);
    });
  });

  group('game end', () {
    test('side with no pieces loses immediately', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(5, 4), Pieces.whiteMan);
      g.board.set(sq(4, 3), Pieces.blackMan);
      g.board.set(sq(3, 2), Pieces.empty);
      // White captures the only black piece.
      final caps = g.moves().where((m) => m.isCapture).toList();
      expect(caps, isNotEmpty);
      g.play(caps.first);
      expect(g.result, GameResult.whiteWins);
    });

    test('blocked side loses', () {
      final g = emptyGame(Side.white);
      // Black man at (0,1) boxed in: forward squares occupied, landings
      // beyond occupied or off-board.
      g.board.set(sq(0, 1), Pieces.blackMan);
      g.board.set(sq(1, 0), Pieces.whiteMan);
      g.board.set(sq(1, 2), Pieces.whiteMan);
      g.board.set(sq(2, 3), Pieces.whiteKing);
      g.board.set(sq(2, 1), Pieces.whiteKing);
      // Far-away white man so white has a move that doesn't unblock black.
      g.board.set(sq(9, 6), Pieces.whiteMan);
      expect(legalMoves(g.board, Side.black), isEmpty);
      final mv = g.moves().firstWhere((m) => m.from == sq(9, 6));
      g.play(mv);
      expect(g.result, GameResult.whiteWins);
    });
  });

  group('ai', () {
    test('ai returns a legal move', () {
      final g = GameState();
      final ai = AiPlayer(AiConfig.easy);
      final move = ai.chooseMove(g);
      // Structural comparison: chooseMove builds its own move list.
      final fresh = g.moves();
      expect(
          fresh.any((m) =>
              m.from == move.from &&
              m.to == move.to &&
              m.captures == move.captures),
          isTrue);
    });

    test('ai takes a forced winning capture', () {
      final g = emptyGame(Side.white);
      g.board.set(sq(8, 5), Pieces.whiteMan);
      g.board.set(sq(7, 4), Pieces.blackMan);
      g.board.set(sq(9, 8), Pieces.whiteMan);
      final ai = AiPlayer(AiConfig.medium);
      final move = ai.chooseMove(g);
      expect(move.isCapture, isTrue);
      expect(move.to, sq(6, 3));
    });

    test('medium ai completes a game move quickly', () {
      final g = GameState();
      final ai = AiPlayer(AiConfig.medium);
      final sw = Stopwatch()..start();
      ai.chooseMove(g);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });
  });
}
