/// Board representation for Sri Lankan draughts (daam).
///
/// 12x12 board, dark squares only. Squares are encoded as `r * 12 + c`.
/// Dark squares satisfy `(r + c) % 2 == 1`.
///
/// Initial setup: 30 pieces per side on the dark cells of the first five
/// rows (rows 0-4 black, rows 7-11 white). White moves first.
library;

enum Side { white, black }

Side opponent(Side s) => s == Side.white ? Side.black : Side.white;

enum PieceKind { man, king }

/// Piece codes stored on the board grid.
class Pieces {
  static const int empty = 0;
  static const int whiteMan = 1;
  static const int whiteKing = 2;
  static const int blackMan = 3;
  static const int blackKing = 4;

  static int of(Side side, PieceKind kind) =>
      side == Side.white ? (kind == PieceKind.man ? whiteMan : whiteKing)
                         : (kind == PieceKind.man ? blackMan : blackKing);

  static Side? sideOf(int code) {
    if (code == whiteMan || code == whiteKing) return Side.white;
    if (code == blackMan || code == blackKing) return Side.black;
    return null;
  }

  static PieceKind? kindOf(int code) {
    if (code == whiteMan || code == blackMan) return PieceKind.man;
    if (code == whiteKing || code == blackKing) return PieceKind.king;
    return null;
  }
}

int rowOf(int sq) => sq ~/ 12;
int colOf(int sq) => sq % 12;
int square(int r, int c) => r * 12 + c;

bool inBounds(int r, int c) => r >= 0 && r < 12 && c >= 0 && c < 12;
bool isDark(int r, int c) => (r + c) % 2 == 1;

/// Back row (crownhead) for a side: white promotes on row 0, black on row 11.
int crownhead(Side side) => side == Side.white ? 0 : 11;

/// Forward direction for a side: white moves toward row 0 (dr = -1).
int forwardDir(Side side) => side == Side.white ? -1 : 1;

/// Mutable board. The engine clones it freely during search.
class Board {
  final List<int> cells = List<int>.filled(144, Pieces.empty);

  Board();

  Board.clone(Board other) {
    cells.setAll(0, other.cells);
  }

  int at(int sq) => cells[sq];
  int atRC(int r, int c) => cells[square(r, c)];
  void set(int sq, int code) => cells[sq] = code;
  void setRC(int r, int c, int code) => cells[square(r, c)] = code;

  /// Standard Sri Lankan starting position.
  void setup() {
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 12; c++) {
        if (isDark(r, c)) setRC(r, c, Pieces.blackMan);
      }
    }
    for (int r = 7; r < 12; r++) {
      for (int c = 0; c < 12; c++) {
        if (isDark(r, c)) setRC(r, c, Pieces.whiteMan);
      }
    }
  }

  int countSide(Side side) =>
      cells.where((code) => Pieces.sideOf(code) == side).length;

  Board copy() => Board.clone(this);
}
