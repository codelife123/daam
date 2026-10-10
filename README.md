# Daam (දාම්) — Sri Lankan Checkers

The only checkers app that plays real Sri Lankan daam, in Sinhala.

## Rules

Sri Lankan draughts on a 12×12 board, 30 pieces per side:

- Men move one square diagonally forward; capture diagonally **forward and backward**.
- **Flying kings (dama)**: move any number of squares diagonally, capture from a distance.
- **Compulsory maximum capture**: if a capture exists it must be taken; the longest capture sequence is mandatory.
- **Crownhead Continue**: a man reaching the back row promotes mid-capture and keeps capturing as a king.

## Run

```bash
flutter pub get
flutter test          # rules engine tests
flutter run           # on a device or emulator
```

## Project layout

- `lib/engine/` — pure-Dart rules engine (board, move generation, game state, alpha-beta AI). No Flutter dependency; fully unit-tested.
- `lib/screens/game_screen.dart` — 12×12 board UI, tap-to-move, AI in a background isolate.
- `lib/l10n.dart` — Sinhala (default) + English strings.
- `lib/main.dart` — home, how-to-play, settings, stats.

## Roadmap

- [x] Weekend 1: rules engine + tests, board UI, vs-AI, 2-player, Sinhala UI
- [ ] AdMob integration (banner on menu, interstitial between games) — add real ad unit IDs in `lib/ads.dart`
- [ ] Play Store listing: title "Daam – Sri Lankan Checkers (දාම්)", screenshots, Sinhala description
- [ ] Later: online multiplayer, leaderboards, themes
