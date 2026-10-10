# Sri Lankan Draughts (Daam) — rules reference for the engine

Verified 2026-10-10 against Ludii Portal "Dam (Sri Lanka)" (ref. Parker 1909),
board-and-pieces checkers survey, Wikipedia Malaysian/Singaporean checkers
(Dam/Dum — same family), Wikipedia International draughts, and the FMJD Annexes 2024.
This is a reference spec for the main agent building the Flutter rules engine —
not a user-facing message.

## Board and setup
- 12x12 board, play on dark squares only (72 playable squares).
- 30 pieces per side, filling all dark squares of each side's first five rows
  (5 rows x 6 dark squares = 30). Two central rows empty.
- Light pieces move first.

## Movement
- Men move one square diagonally FORWARD to an empty square. (Note: Parker 1909
  allows men to also move backward; every modern FMJD-family 12x12 variant has
  forward-only movement with backward capture. Recommend forward-only for the
  app; this is the one rule worth confirming with Hans against local play.)
- Men capture by jumping over an ADJACENT enemy piece, FORWARD or BACKWARD, to the
  empty square immediately beyond it.
- Captures are compulsory. If several capture options exist, the player MUST take
  the sequence capturing the most pieces (compulsory maximum capture). A king
  counts as one piece for counting. Ties -> player's choice.
- Multi-jump: a capturing piece continues jumping as long as captures are
  available, as one turn. Captured pieces stay on the board as obstacles during
  the multi-jump and are removed only when the turn ends. The same piece may not
  be jumped twice in one turn.

## Promotion
- A man that ENDS its move on the farthest rank is crowned a king (dama).
- A man passing THROUGH the farthest rank mid-capture without ending there is
  NOT crowned; it continues the capture as a man and may keep jumping backwards.

## Kings (flying kings)
- Move any number of squares along an unblocked diagonal, forward or backward,
  landing on any empty square.
- Capture: jump over a single enemy piece with at least one empty square beyond,
  landing on ANY empty square beyond it. May not jump over own pieces or two
  pieces in a row.
- A king may change direction between captures in a multi-jump (modern
  international rule; Parker 1909 restricts direction changes to board-edge
  landings — use the modern version).
- A promoted man may not move again in the same turn.

## End of game
- Win: capture all opponent pieces, or leave the opponent with no legal move.
- Draw (MVP): by agreement, or 25 consecutive moves with no capture and no man
  moved (keeps games from stalling vs AI). Simple and honest for v1.

## Test positions (dark-square coordinates: file a-l, rank 1-12)
1. Compulsory max capture: white man c5, black men d6, f8; white king h4 ...
   (engine test: c5xd6 must NOT be chosen when a 2-capture line exists elsewhere).
2. Backward capture: white man e4, black man d5, empty c6 -> e4xc6 legal backwards.
3. Pass-through promotion: white man e10, black men f11, h9 with empties g12, i8:
   e10xf11 lands g12 (promotion rank) — must continue as a MAN if a further
   capture exists, no crowning until the move ends.
4. Flying king landing choice: black king g7, white man e5, empties d4 c3 b2 a1:
   g7xe5 may land on ANY of d4/c3/b2/a1.
5. Blocked king: king may not jump two adjacent enemy pieces.
6. Captured piece as obstacle: multi-jump path may not re-jump a piece captured
   earlier in the same turn, and landing squares occupied by captured-but-not-yet-
   removed pieces are blocked.
