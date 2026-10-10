/// Move generation for Sri Lankan draughts.
///
/// Rules implemented:
/// - Men move one square diagonally forward; capture diagonally forward
///   AND backward by jumping over an adjacent enemy onto an empty square.
/// - Kings (dama) are flying: move any number of squares diagonally, and
///   capture by jumping over an enemy from a distance, landing on any empty
///   square beyond it.
/// - Captures are compulsory; the sequence capturing the MOST pieces must
///   be played (maximum capture rule).
/// - Captured pieces are removed immediately, so a square can be crossed
///   again later in the same sequence once it becomes empty.
/// - A man reaching the crownhead promotes immediately, even mid-sequence,
///   and continues capturing as a king (Crownhead Continue rule).
library;

import 'board.dart';

const List<List<int>> diagonals = [
  [-1, -1], [-1, 1], [1, -1], [1, 1],
];

/// A move: ordered list of squares. path[0] is the origin.
/// Quiet move  -> path has 2 squares. Capture -> 3+ (one landing per jump).
class Move {
  final List<int> path;
  final int captures; // number of pieces captured

  Move(this.path, this.captures);

  int get from => path.first;
  int get to => path.last;
  bool get isCapture => captures > 0;

  @override
  String toString() =>
      'Move(${path.map((s) => '(${rowOf(s)},${colOf(s)})').join(' -> ')}, x$captures)';
}

/// Internal: mutable piece state while exploring a capture sequence.
class _Mover {
  Side side;
  PieceKind kind;
  _Mover(this.side, this.kind);
}

/// All legal moves for [side] on [board].
List<Move> legalMoves(Board board, Side side) {
  final captures = <Move>[];
  for (int sq = 0; sq < 144; sq++) {
    final code = board.at(sq);
    if (Pieces.sideOf(code) != side) continue;
    captures.addAll(_captureSequences(board, sq, _Mover(side, Pieces.kindOf(code)!)));
  }
  if (captures.isNotEmpty) {
    int best = 0;
    for (final m in captures) {
      if (m.captures > best) best = m.captures;
    }
    return captures.where((m) => m.captures == best).toList();
  }
  // No captures: quiet moves.
  final quiet = <Move>[];
  for (int sq = 0; sq < 144; sq++) {
    final code = board.at(sq);
    if (Pieces.sideOf(code) != side) continue;
    final kind = Pieces.kindOf(code)!;
    if (kind == PieceKind.man) {
      final r = rowOf(sq), c = colOf(sq);
      final dr = forwardDir(side);
      for (final dc in [-1, 1]) {
        final nr = r + dr, nc = c + dc;
        if (inBounds(nr, nc) && board.atRC(nr, nc) == Pieces.empty) {
          quiet.add(Move([sq, square(nr, nc)], 0));
        }
      }
    } else {
      // Flying king slides.
      final r = rowOf(sq), c = colOf(sq);
      for (final d in diagonals) {
        int nr = r + d[0], nc = c + d[1];
        while (inBounds(nr, nc) && board.atRC(nr, nc) == Pieces.empty) {
          quiet.add(Move([sq, square(nr, nc)], 0));
          nr += d[0];
          nc += d[1];
        }
      }
    }
  }
  return quiet;
}

/// Depth-first search of all capture sequences starting from [from].
List<Move> _captureSequences(Board board, int from, _Mover mover) {
  final results = <Move>[];
  final path = [from];
  _searchCaptures(board, from, mover, path, 0, results);
  return results;
}

void _searchCaptures(Board board, int pos, _Mover mover, List<int> path,
    int taken, List<Move> results) {
  final r = rowOf(pos), c = colOf(pos);
  bool extended = false;

  if (mover.kind == PieceKind.man) {
    for (final d in diagonals) {
      final mr = r + d[0], mc = c + d[1]; // jumped square
      final lr = r + 2 * d[0], lc = c + 2 * d[1]; // landing square
      if (!inBounds(lr, lc)) continue;
      final mid = board.atRC(mr, mc);
      if (Pieces.sideOf(mid) != opponent(mover.side)) continue;
      if (board.atRC(lr, lc) != Pieces.empty) continue;

      extended = true;
      // Apply the jump.
      board.set(pos, Pieces.empty);
      board.setRC(mr, mc, Pieces.empty);
      var kind = mover.kind;
      if (lr == crownhead(mover.side)) kind = PieceKind.king; // Crownhead Continue
      board.setRC(lr, lc, Pieces.of(mover.side, kind));
      path.add(square(lr, lc));

      _searchCaptures(board, square(lr, lc), _Mover(mover.side, kind), path,
          taken + 1, results);

      // Undo.
      path.removeLast();
      board.setRC(lr, lc, Pieces.empty);
      board.setRC(mr, mc, mid);
      board.set(pos, Pieces.of(mover.side, mover.kind));
    }
  } else {
    // Flying king: along each diagonal, the first piece met must be an
    // enemy, and the king may land on any empty square beyond it.
    for (final d in diagonals) {
      int nr = r + d[0], nc = c + d[1];
      while (inBounds(nr, nc) && board.atRC(nr, nc) == Pieces.empty) {
        nr += d[0];
        nc += d[1];
      }
      if (!inBounds(nr, nc)) continue;
      final mid = board.atRC(nr, nc);
      if (Pieces.sideOf(mid) != opponent(mover.side)) continue;
      final mr = nr, mc = nc;
      nr += d[0];
      nc += d[1];
      while (inBounds(nr, nc) && board.atRC(nr, nc) == Pieces.empty) {
        final land = square(nr, nc);
        extended = true;
        board.set(pos, Pieces.empty);
        board.setRC(mr, mc, Pieces.empty);
        board.set(land, Pieces.of(mover.side, PieceKind.king));
        path.add(land);

        _searchCaptures(board, land, _Mover(mover.side, PieceKind.king), path,
            taken + 1, results);

        path.removeLast();
        board.set(land, Pieces.empty);
        board.setRC(mr, mc, mid);
        board.set(pos, Pieces.of(mover.side, PieceKind.king));

        nr += d[0];
        nc += d[1];
      }
    }
  }

  if (!extended && taken > 0) {
    results.add(Move(List<int>.from(path), taken));
  }
}

/// Apply [move] to [board], handling promotion. Returns captured piece count.
int applyMove(Board board, Move move, Side side) {
  final code = board.at(move.from);
  final kind = Pieces.kindOf(code)!;
  board.set(move.from, Pieces.empty);

  // Remove jumped pieces: for each consecutive pair, the jumped square is
  // the midpoint (man) or the single enemy piece on that diagonal (king).
  int captured = 0;
  for (int i = 0; i < move.path.length - 1; i++) {
    final a = move.path[i], b = move.path[i + 1];
    final ar = rowOf(a), ac = colOf(a), br = rowOf(b), bc = colOf(b);
    final dr = (br - ar).sign, dc = (bc - ac).sign;
    int jr = ar + dr, jc = ac + dc;
    int jumped = -1;
    while (jr != br || jc != bc) {
      final code2 = board.atRC(jr, jc);
      if (code2 != Pieces.empty) {
        jumped = square(jr, jc);
        break;
      }
      jr += dr;
      jc += dc;
    }
    if (jumped >= 0) {
      board.set(jumped, Pieces.empty);
      captured++;
    }
  }

  var finalKind = kind;
  if (kind == PieceKind.man) {
    // Crownhead Continue: promotion happens the moment the piece lands on
    // the crownhead, even mid-capture (mirrors _searchCaptures).
    for (final s in move.path.skip(1)) {
      if (rowOf(s) == crownhead(side)) {
        finalKind = PieceKind.king;
        break;
      }
    }
  }
  board.set(move.to, Pieces.of(side, finalKind));
  return captured;
}
