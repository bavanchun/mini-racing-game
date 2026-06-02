# Mini Racing Game — Screen Implementation Contract

Shared contract for the 3 screens. Foundation is DONE and compiles. Do NOT
edit foundation files; only read them.

## Foundation API (already implemented — read, don't change)

`lib/models/racer.dart`
- `class Racer { final int id; final String name; final String emoji; final Color color; }`
- Display the horse with `Text(racer.emoji, style: TextStyle(fontSize: ...))`.

`lib/utils/constants.dart`
- `GameConfig.startingMoney` = 100
- `GameConfig.winMultiplier` = 3
- `GameConfig.racers` → `List<Racer>` (3 horses: Thunder/Blaze/Shadow, ids 0..2)
- `RaceConfig.tick` (Duration 120ms), `RaceConfig.minStep` (0.010), `RaceConfig.maxStep` (0.055)

`lib/models/game_state.dart`
- `class GameState { int money; final Map<int,int> bets; ... }`
  - `int get totalBet`
  - `bool get canStartRace` (totalBet>0 && totalBet<=money)
  - `void setBet(int racerId, int stake)` (stake<=0 clears)
  - `void clearBets()`
  - `RaceOutcome settleRace(Racer winner)` — mutates money, returns outcome, clears bets.
    Accounting: `money = money - totalBet + (stakeOnWinner * 3)`.
- `class RaceOutcome { Racer winner; Map<int,int> bets; int totalStaked; int payout; int netChange; int moneyAfter; bool get didWin; }`

`lib/theme/app_theme.dart`
- `AppColors.turf/turfDark/rail/gold/sky/trackLane/win/lose`
- `AppTheme.light` (wired in main.dart by integrator)

## Navigation contract (IMPORTANT — keep exactly)

A single `GameState game` instance is created in main.dart and passed to Home.

1. **Home → Race:** `await Navigator.push(context, MaterialPageRoute(builder: (_) => RaceScreen(game: game)));`
   then `if (mounted) setState(() {});` (refresh wallet display).
2. **Race → Result:** when a racer finishes first:
   ```dart
   final outcome = game.settleRace(winner);
   if (!mounted) return;
   Navigator.pushReplacement(context,
       MaterialPageRoute(builder: (_) => ResultScreen(outcome: outcome)));
   ```
   `settleRace` must be called EXACTLY ONCE (guard with a `bool _finished`).
3. **Result → Home:** both `Play Again` and `Back to Home` buttons run
   `Navigator.popUntil(context, (route) => route.isFirst);`

## Constructors (exact signatures — integrator depends on these)

- `class HomeBettingScreen extends StatefulWidget { final GameState game; const HomeBettingScreen({super.key, required this.game}); }`
- `class RaceScreen extends StatefulWidget { final GameState game; const RaceScreen({super.key, required this.game}); }`
- `class ResultScreen extends StatelessWidget { final RaceOutcome outcome; const ResultScreen({super.key, required this.outcome}); }`

## File ownership (do not touch other agents' files)

- Home agent: `lib/screens/home_betting_screen.dart`, `lib/widgets/bet_row.dart`
- Race agent: `lib/screens/race_screen.dart`, `lib/widgets/race_track.dart`
- Result agent: `lib/screens/result_screen.dart`, `lib/widgets/result_bet_table.dart`

## Verification

Run `flutter analyze lib/screens/<your_file>.dart lib/widgets/<your_widget>.dart`
(plus the foundation it imports). Zero issues required before reporting DONE.
