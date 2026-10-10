/// Game screen: 12x12 board, tap-to-move, vs AI or local 2-player.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/ai.dart';
import '../engine/board.dart';
import '../engine/game.dart';
import '../engine/moves.dart';
import '../l10n.dart';

/// Passed to the isolate for AI computation.
class _AiRequest {
  final int difficulty; // 0 easy, 1 medium, 2 hard
  final GameState game;
  _AiRequest(this.difficulty, this.game);
}

Move _aiEntry(_AiRequest req) {
  final cfg = [AiConfig.easy, AiConfig.medium, AiConfig.hard][req.difficulty];
  return AiPlayer(cfg).chooseMove(req.game);
}

enum GameMode { vsComputer, twoPlayer }

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int difficulty;
  final S strings;
  final AppLocale locale;

  const GameScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.strings,
    required this.locale,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState game;
  late List<Move> legal;
  int? selected;
  bool aiThinking = false;
  Side humanSide = Side.white;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    setState(() {
      game = GameState();
      legal = game.moves();
      selected = null;
      aiThinking = false;
      humanSide = Side.white;
    });
    _maybeAiMove();
  }

  bool get _humanTurn =>
      widget.mode == GameMode.twoPlayer || game.turn == humanSide;

  Future<void> _maybeAiMove() async {
    if (widget.mode != GameMode.vsComputer) return;
    if (game.result != GameResult.ongoing) return;
    if (game.turn == humanSide) return;
    setState(() => aiThinking = true);
    final move = await compute(_aiEntry, _AiRequest(widget.difficulty, game.copy()));
    if (!mounted) return;
    setState(() {
      aiThinking = false;
      _applyMove(move);
    });
  }

  void _applyMove(Move move) {
    game.play(move);
    legal = game.moves();
    selected = null;
    _recordResultIfOver();
    _maybeAiMove();
  }

  Future<void> _recordResultIfOver() async {
    if (game.result == GameResult.ongoing) return;
    final prefs = await SharedPreferences.getInstance();
    final key = widget.mode == GameMode.vsComputer ? 'ai' : 'p2';
    if (game.result == GameResult.draw) {
      await prefs.setInt('${key}_draws', (prefs.getInt('${key}_draws') ?? 0) + 1);
    } else {
      final humanWon = (game.result == GameResult.whiteWins) == (humanSide == Side.white);
      final k = humanWon ? 'wins' : 'losses';
      await prefs.setInt('${key}_$k', (prefs.getInt('${key}_$k') ?? 0) + 1);
    }
  }

  void _onTapSquare(int sq) {
    if (!_humanTurn || aiThinking) return;
    if (game.result != GameResult.ongoing) return;

    final code = game.board.at(sq);
    if (selected == null) {
      if (Pieces.sideOf(code) == game.turn) {
        setState(() => selected = sq);
      }
      return;
    }
    if (sq == selected) {
      setState(() => selected = null);
      return;
    }
    if (Pieces.sideOf(code) == game.turn) {
      setState(() => selected = sq);
      return;
    }
    // Try to move selected -> sq.
    final candidates =
        legal.where((m) => m.from == selected && m.to == sq).toList();
    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.captures.compareTo(a.captures));
      setState(() => _applyMove(candidates.first));
    } else if (Pieces.sideOf(code) == game.turn) {
      setState(() => selected = sq);
    } else {
      setState(() => selected = null);
    }
  }

  Set<int> get _targets {
    if (selected == null) return {};
    return legal.where((m) => m.from == selected).map((m) => m.to).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    String status;
    if (game.result == GameResult.whiteWins) {
      status = widget.mode == GameMode.vsComputer
          ? (humanSide == Side.white ? s.youWin : s.youLose)
          : s.get('whiteWins');
    } else if (game.result == GameResult.blackWins) {
      status = widget.mode == GameMode.vsComputer
          ? (humanSide == Side.black ? s.youWin : s.youLose)
          : s.get('blackWins');
    } else if (game.result == GameResult.draw) {
      status = s.get('draw');
    } else if (aiThinking) {
      status = s.thinking;
    } else {
      status = game.turn == Side.white ? s.get('whiteTurn') : s.get('blackTurn');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          if (game.result == GameResult.ongoing)
            TextButton(
              onPressed: () {
                setState(() {
                  game.result = humanSide == Side.white
                      ? GameResult.blackWins
                      : GameResult.whiteWins;
                  game.resultReason = 'resign';
                  legal = [];
                });
                _recordResultIfOver();
              },
              child: Text(s.resign, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(status,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _BoardView(
                    board: game.board,
                    selected: selected,
                    targets: _targets,
                    version: game.history.length,
                    onTap: _onTapSquare,
                  ),
                ),
              ),
            ),
          ),
          if (game.result != GameResult.ongoing)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _newGame,
                    child: Text(s.rematch),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.menu),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BoardView extends StatelessWidget {
  final Board board;
  final int? selected;
  final Set<int> targets;
  final int version; // game.history.length — forces repaint after each move
  final void Function(int sq) onTap;

  const _BoardView({
    required this.board,
    required this.selected,
    required this.targets,
    required this.version,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(details.globalPosition);
        final cell = box.size.width / 12;
        final c = (local.dx / cell).floor().clamp(0, 11);
        final r = (local.dy / cell).floor().clamp(0, 11);
        onTap(r * 12 + c);
      },
      child: CustomPaint(
        painter: _BoardPainter(
            board: board,
            selected: selected,
            targets: targets,
            version: version),
        size: Size.infinite,
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final Board board;
  final int? selected;
  final Set<int> targets;
  final int version;

  _BoardPainter(
      {required this.board,
      required this.selected,
      required this.targets,
      required this.version});

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 12;
    final light = Paint()..color = const Color(0xFFE8D0A9);
    final dark = Paint()..color = const Color(0xFF8B5E34);
    final highlight = Paint()..color = const Color(0xFF7BC96F).withValues(alpha: 0.55);
    final targetPaint = Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.65);

    for (int r = 0; r < 12; r++) {
      for (int c = 0; c < 12; c++) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        canvas.drawRect(rect, isDark(r, c) ? dark : light);
        final sq = r * 12 + c;
        if (sq == selected) canvas.drawRect(rect, highlight);
        if (targets.contains(sq)) {
          canvas.drawCircle(rect.center, cell * 0.18, targetPaint);
        }
        final code = board.at(sq);
        final side = Pieces.sideOf(code);
        if (side != null) {
          final isKing = Pieces.kindOf(code) == PieceKind.king;
          final piecePaint = Paint()
            ..color = side == Side.white ? Colors.white : Colors.black87;
          final border = Paint()
            ..color = side == Side.white ? Colors.black54 : Colors.white70
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawCircle(rect.center, cell * 0.42, piecePaint);
          canvas.drawCircle(rect.center, cell * 0.42, border);
          if (isKing) {
            final tp = TextPainter(
              text: const TextSpan(text: '♛', style: TextStyle(fontSize: 20)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas,
                rect.center - Offset(tp.width / 2, tp.height / 2));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.version != version ||
      old.selected != selected ||
      old.targets != targets;
}
