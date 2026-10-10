/// Game state: board, side to move, history, and termination rules.
library;

import 'board.dart';
import 'moves.dart';

enum GameResult { ongoing, whiteWins, blackWins, draw }

class GameState {
  final Board board = Board();
  Side turn = Side.white;
  GameResult result = GameResult.ongoing;
  String resultReason = '';
  final List<Move> history = [];
  int quietHalfMoves = 0; // half-moves since last capture or promotion

  GameState() {
    board.setup();
  }

  GameState.empty();

  List<Move> moves() => legalMoves(board, turn);

  /// Plays [move] (must be one of [moves]). Updates turn and result.
  void play(Move move) {
    final wasMan = Pieces.kindOf(board.at(move.from)) == PieceKind.man;
    final captured = applyMove(board, move, turn);
    history.add(move);
    if (captured > 0 || (wasMan && rowOf(move.to) == crownhead(turn))) {
      quietHalfMoves = 0;
    } else {
      quietHalfMoves++;
    }
    turn = opponent(turn);
    _updateResult();
  }

  void _updateResult() {
    final sideToMove = turn;
    if (board.countSide(sideToMove) == 0) {
      _win(opponent(sideToMove), 'all pieces captured');
      return;
    }
    if (legalMoves(board, sideToMove).isEmpty) {
      _win(opponent(sideToMove), 'no legal moves');
      return;
    }
    if (quietHalfMoves >= 80) {
      result = GameResult.draw;
      resultReason = '80 quiet half-moves';
    }
  }

  void _win(Side winner, String reason) {
    result = winner == Side.white ? GameResult.whiteWins : GameResult.blackWins;
    resultReason = reason;
  }

  GameState copy() {
    final g = GameState.empty();
    g.board.cells.setAll(0, board.cells);
    g.turn = turn;
    g.result = result;
    g.resultReason = resultReason;
    g.history.addAll(history);
    g.quietHalfMoves = quietHalfMoves;
    return g;
  }
}
