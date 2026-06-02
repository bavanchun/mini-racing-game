# 🐎 Mini Racing Game (Flutter)

A mini **horse-racing betting game** built with Flutter for the **PRM393** course
(Modules 1–4). The player bets money on three horses, watches them race with
random speeds, and wins or loses based on which horse finishes first.

It is a **UI + game-logic** project — no game engine, physics, or collision
detection. Movement is a "fake slider" built from `Container` + `AnimatedPositioned`.

## Gameplay

```
Home / Betting  →  Race  →  Result  →  (Play Again | Back to Home)
```

1. **Home / Betting** — see your wallet (starts at **$100**), place stakes on any of
   the 3 horses with +/- controls, then **Start Race**.
2. **Race** — 3 parallel tracks; each horse advances by a random amount every tick.
   First to the finish line wins.
3. **Result** — winner, a per-bet results table (Win/Lose), payout, and your new
   wallet balance.

### Betting rules

| Rule | Behaviour |
|------|-----------|
| Starting wallet | `$100` |
| Min to start | At least one stake placed |
| Max total bet | Cannot exceed your wallet (over-betting is blocked) |
| Payout | Winning stake returns **3×** (`money - totalBet + stakeOnWinner × 3`) |
| Losing stake | Forfeited |
| Out of money | A "Reset Wallet" button restores `$100` |

## Tech & concepts demonstrated

- `StatefulWidget` + `setState` (no state-management package — per lab spec)
- Layout with `Column`, `Row`, `Stack`
- `Navigator.push` / `pushReplacement` / `popUntil`
- Dart `Random`, `Timer.periodic`, `if/else`, functions
- Fake-slider animation via `AnimatedPositioned` (Slider widget intentionally **not** used)

## Bonus features

- 💾 **Persistent wallet** via `shared_preferences` (money survives app restarts)
- 🎨 **Styled UI** — "race day" gradient backdrop + themed cards
- 🔊 **Sound cues** — start / win / lose (synthesized WAV assets, `audioplayers`)

## Project structure

```
lib/
├── main.dart                       # App root, loads saved wallet, hosts GameState
├── models/
│   ├── racer.dart                  # Racer (id, name, emoji, color)
│   └── game_state.dart             # Wallet, bets, 3x payout logic, RaceOutcome
├── screens/
│   ├── home_betting_screen.dart    # Betting lobby
│   ├── race_screen.dart            # Animated race
│   └── result_screen.dart          # Standings + payout
├── widgets/
│   ├── bet_row.dart                # One racer's bet row (+/-)
│   ├── race_track.dart             # One animated lane
│   ├── result_bet_table.dart       # Bet-results table
│   └── app_background.dart         # Shared gradient backdrop
├── services/
│   ├── wallet_storage.dart         # SharedPreferences wrapper (bonus)
│   └── sound_service.dart          # Sound cue player (bonus)
├── theme/app_theme.dart            # Colours + ThemeData
└── utils/constants.dart            # Roster + game tuning
```

## Run it

```bash
flutter pub get
flutter run            # pick a device (Android / iOS / Chrome)
```

## Develop

```bash
flutter analyze        # static analysis (clean)
flutter test           # unit + widget tests
```

See [`docs/`](docs/) for architecture and a codebase summary.
