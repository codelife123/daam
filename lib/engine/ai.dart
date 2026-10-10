/// Alpha-beta AI for Sri Lankan daam.
///
/// Negamax with iterative deepening, quiescence on forced captures, and
/// move ordering by capture count. Evaluation is material + advancement +
/// mobility + center control, scored from White's perspective.
library;

import 'dart:math';
import 'board.dart';
import 'game.dart';
import 'moves.dart';

class AiConfig {
  final int maxDepth;
  final int timeMs;
  final bool addNoise; // pick randomly among near-best moves (Easy mode)
  const AiConfig({required this.maxDepth, required this.timeMs, this.addNoise = false});

  static const easy = AiConfig(maxDepth: 2, timeMs: 400, addNoise: true);
  static const medium = AiConfig(maxDepth: 4, timeMs: 1200);
  static const hard = AiConfig(maxDepth: 7, timeMs: 2500);
}

class AiPlayer {
  final AiConfig config;
  final Random _rng = Random();
  bool _stop = false;

  AiPlayer(this.config);

  /// Returns the chosen move for the side to move in [game].
  Move chooseMove(GameState game) {
    _stop = false;
    final deadline = DateTime.now().millisecondsSinceEpoch + config.timeMs;
    final moves = game.moves();
    if (moves.length == 1) return moves.first;

    Move? best;
    int bestScore = -1 << 30;

    // Iterative deepening: keep the best move from the deepest finished depth.
    for (int depth = 1; depth <= config.maxDepth; depth++) {
      int alpha = -1 << 30;
      Move? depthBest;
      int depthScore = -1 << 30;
      final ordered = _orderMoves(game.board, moves);
      for (final m in ordered) {
        final child = game.copy();
        child.play(m);
        final score = -_search(child, depth - 1, -1 << 30, -alpha, deadline);
        if (_stop) break;
        if (score > depthScore) {
          depthScore = score;
          depthBest = m;
        }
        if (score > alpha) alpha = score;
      }
      if (_stop) break;
      best = depthBest;
      bestScore = depthScore;
      if (DateTime.now().millisecondsSinceEpoch >= deadline) break;
      if (bestScore > 90000) break; // found forced win
    }

    best ??= moves.first;

    if (config.addNoise) {
      // Easy: sometimes pick a different reasonable move.
      final scored = <(Move, int)>[];
      for (final m in moves.take(20)) {
        final child = game.copy();
        child.play(m);
        scored.add((m, -_search(child, 1, -1 << 30, 1 << 30, deadline)));
      }
      scored.sort((a, b) => b.$2.compareTo(a.$2));
      final pool = scored.take(3).toList();
      return pool[_rng.nextInt(pool.length)].$1;
    }
    return best;
  }

  List<Move> _orderMoves(Board board, List<Move> moves) {
    final copy = List<Move>.from(moves);
    copy.sort((a, b) => b.captures.compareTo(a.captures));
    return copy;
  }

  int _search(GameState game, int depth, int alpha, int beta, int deadline) {
    if ((depth & 7) == 0 &&
        DateTime.now().millisecondsSinceEpoch >= deadline) {
      _stop = true;
      return 0;
    }
    if (game.result != GameResult.ongoing) return _terminalScore(game);

    final moves = game.moves();
    if (depth <= 0) {
      // Quiescence: captures are forced anyway, so just keep searching
      // while captures exist.
      if (moves.isNotEmpty && moves.first.isCapture) {
        return _quiesce(game, alpha, beta, deadline, 0);
      }
      return _evaluate(game.board, game.turn);
    }

    int best = -1 << 30;
    for (final m in _orderMoves(game.board, moves)) {
      final child = game.copy();
      child.play(m);
      final score = -_search(child, depth - 1, -beta, -alpha, deadline);
      if (_stop) return 0;
      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return best;
  }

  int _quiesce(GameState game, int alpha, int beta, int deadline, int qdepth) {
    if (DateTime.now().millisecondsSinceEpoch >= deadline) {
      _stop = true;
      return 0;
    }
    if (game.result != GameResult.ongoing) return _terminalScore(game);
    if (qdepth > 12) return _evaluate(game.board, game.turn);

    final standPat = _evaluate(game.board, game.turn);
    if (standPat >= beta) return beta;
    if (standPat > alpha) alpha = standPat;

    final moves = game.moves();
    if (moves.isEmpty || !moves.first.isCapture) return standPat;

    for (final m in _orderMoves(game.board, moves)) {
      final child = game.copy();
      child.play(m);
      final score = -_quiesce(child, -beta, -alpha, deadline, qdepth + 1);
      if (_stop) return 0;
      if (score >= beta) return beta;
      if (score > alpha) alpha = score;
    }
    return alpha;
  }

  int _terminalScore(GameState game) {
    switch (game.result) {
      case GameResult.whiteWins:
        return game.turn == Side.white ? 100000 : -100000;
      case GameResult.blackWins:
        return game.turn == Side.black ? 100000 : -100000;
      case GameResult.draw:
        return 0;
      case GameResult.ongoing:
        return _evaluate(game.board, game.turn);
    }
  }

  /// Static evaluation, from the perspective of [sideToMove].
  int _evaluate(Board board, Side sideToMove) {
    int score = 0; // positive favors white
    for (int sq = 0; sq < 144; sq++) {
      final code = board.at(sq);
      final side = Pieces.sideOf(code);
      if (side == null) continue;
      final kind = Pieces.kindOf(code)!;
      final r = rowOf(sq), c = colOf(sq);
      int v;
      if (kind == PieceKind.man) {
        v = 100;
        // Advancement toward promotion.
        v += side == Side.white ? (11 - r) * 4 : r * 4;
        // Center files slightly better.
        if (c >= 4 && c <= 7) v += 4;
      } else {
        v = 300;
        if (c >= 3 && c <= 8) v += 6;
      }
      score += side == Side.white ? v : -v;
    }
    // Mobility (cheap proxy): quiet moves available.
    final myQuiet = legalMoves(board, sideToMove)
        .where((m) => !m.isCapture)
        .length;
    score += sideToMove == Side.white ? myQuiet : -myQuiet;
    return sideToMove == Side.white ? score : -score;
  }
}
