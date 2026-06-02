---
phase: 4
title: "Result Screen"
status: done
priority: P1
effort: "1.5h"
dependencies: [1]
---

# Phase 4: Result Screen

## Overview

Fix result findings: `$-50` → `-$50` formatting (#5), show the full finishing
standings not just bet rows (#6), make "Play Again" re-use the previous bets, and
add semantics (#8).

## Requirements
- Functional: Net uses signed formatting; a Final Standings list shows all three
  horses in finishing order (1st/2nd/3rd), including the winner even if unbet;
  "Play Again" repeats the last bets when affordable, else falls back to fresh
  betting; "Back to Home" always returns to fresh betting.
- Non-functional: screen stays presentational re: settlement (no `settleRace`
  call here); reads `outcome.finishOrder` from Phase 1.

## Architecture

**`lib/screens/result_screen.dart`**
- **Net formatting (#5):** replace the inline `'${netPositive?'+':''}\$${net}'`
  with `formatSigned(outcome.netChange)` from `lib/utils/formatting.dart`. Use
  `formatMoney(...)` for the other money values for consistency.
- **Final Standings (#6):** add a `_StandingsCard` that maps `outcome.finishOrder`
  → `GameConfig.racers[id]` and lists 1st/2nd/3rd with medal (🥇🥈🥉), emoji,
  name (in `racer.color`), and a small "winner" tag on 1st. Place it directly
  under the winner banner (before the bet table). The existing `ResultBetTable`
  stays (per-bet Win/Lose) — standings answer "where did each horse finish".
- **Play Again reuse:** the screen needs the live `GameState` to call
  `repeatLastBets()`. Two options (pick the lighter one that fits current wiring):
  - **A (preferred):** `RaceOutcome` already snapshots bets; but repeating needs
    the live wallet. So Race passes the `GameState` along, OR Result keeps using
    `outcome` for display and triggers repeat via a callback. SIMPLEST consistent
    with the navigation contract: have `ResultScreen` accept the `GameState`
    (`final GameState game;`) in addition to `outcome`. Race already holds
    `widget.game`, so `pushReplacement(ResultScreen(outcome: o, game: widget.game))`.
  - Buttons:
    - **Play Again:** `if (game.canRepeatLastBets) game.repeatLastBets();`
      then `Navigator.popUntil(first)`. Home's resume `build` shows the repeated
      stakes. If not affordable, behaves like Back to Home (no repeat) — and
      label/secondary text can hint "not enough to repeat" (optional).
    - **Back to Home:** `Navigator.popUntil(first)` (no repeat).
  - This makes the two buttons genuinely different (review #11 / play-again ask).
- **Semantics (#8):** ensure the winner banner + standings read sensibly; add
  `Semantics(label: ...)` to medal rows if the emoji alone is ambiguous.

**`lib/widgets/result_bet_table.dart`**
- Optional: use `formatMoney` for the stake column for consistency. No structural
  change required (it already handles empty + per-row Win/Lose).

> File-ownership note: `outcome.finishOrder`, `formatSigned`/`formatMoney`,
> `game.repeatLastBets`/`canRepeatLastBets` all come from Phase 1.

> Cross-phase coupling: adding `game` to `ResultScreen`'s constructor changes the
> Race→Result push site (Phase 3) and the navigation contract. Phase 5 confirms
> both sides match; Phase 3 must pass `game: widget.game`. Document this in the
> integration phase so it isn't missed.

## Related Code Files
- Modify: `lib/screens/result_screen.dart`
- Modify (optional, formatting): `lib/widgets/result_bet_table.dart`

## Implementation Steps
1. Add `final GameState game;` to `ResultScreen` constructor.
2. Swap Net to `formatSigned`; money to `formatMoney`.
3. Add `_StandingsCard` driven by `outcome.finishOrder`.
4. Wire Play Again (`repeatLastBets` if affordable) vs Back to Home (no repeat).
5. Add semantics where emoji-only.
6. `flutter analyze` (owned files + foundation) → 0 issues.

## Success Criteria
- [ ] Net renders `-$50` / `+$30`; money values use `formatMoney`
- [ ] Final Standings lists all 3 horses in finishing order incl. the winner
- [ ] "Play Again" repeats prior bets when affordable; "Back to Home" does not
- [ ] `ResultScreen` takes `game` + `outcome`; no `settleRace` call here
- [ ] analyze clean

## Risk Assessment
- Constructor change is a cross-phase contract: Race (Phase 3) must pass `game`.
  Mitigation: explicit note in Phase 5 integration checklist; analyze catches a
  missing arg as a compile error.
- "Play Again" when not affordable must not silently do nothing confusing — fall
  back to plain return-to-betting (same as Back to Home).
