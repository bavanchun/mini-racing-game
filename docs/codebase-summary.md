# Codebase Summary

Flutter mini horse-racing betting game. ~13 Dart files, `setState`-only.

## Files

| File | Lines (approx) | Purpose |
|------|------|---------|
| `lib/main.dart` | 45 | Async boot: load saved wallet → create `GameState` → `MaterialApp` → Home |
| `lib/models/racer.dart` | 25 | Immutable racer (id, name, emoji, color) |
| `lib/models/game_state.dart` | 110 | Wallet, bets map, validation, 3× payout (`settleRace`), `RaceOutcome` |
| `lib/utils/constants.dart` | 55 | `GameConfig` (roster, startingMoney=100, winMultiplier=3), `RaceConfig` (tick/steps) |
| `lib/theme/app_theme.dart` | 75 | `AppColors` palette + `AppTheme.light` |
| `lib/screens/home_betting_screen.dart` | 270 | Betting lobby: wallet, bet rows, validation, broke-reset, start |
| `lib/screens/race_screen.dart` | 230 | Timer-driven fake-slider race, winner detection |
| `lib/screens/result_screen.dart` | 265 | Winner banner, results table, payout summary, sound cue |
| `lib/widgets/bet_row.dart` | 130 | One racer's bet row with +/- |
| `lib/widgets/race_track.dart` | 180 | One animated lane (track, finish line, horse) |
| `lib/widgets/result_bet_table.dart` | 140 | Per-bet Win/Lose table |
| `lib/widgets/app_background.dart` | 55 | Shared gradient backdrop + `GradientScaffold` |
| `lib/services/wallet_storage.dart` | 40 | SharedPreferences wallet persistence (bonus) |
| `lib/services/sound_service.dart` | 30 | start/win/lose audio cues (bonus) |

## Tests

- `test/game_state_test.dart` — betting rules + 3× payout (win / lose / multi-bet).
- `test/widget_test.dart` — app boots into betting screen with starting wallet.

## Status

`flutter analyze` → 0 issues. `flutter test` → 7/7 pass. `flutter build web` → success.

## Conventions

- Dart `snake_case` filenames; private widgets prefixed `_` inside their file.
- Each file kept focused (most < 200 lines; screens slightly above due to extracted
  private sub-widgets in the same file).
- Bonus services fail soft — never crash gameplay.
