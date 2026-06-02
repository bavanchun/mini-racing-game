---
phase: 2
title: "Betting Screen"
status: done
priority: P1
effort: "1.5h"
dependencies: [1]
---

# Phase 2: Betting Screen

## Overview

Fix betting-screen findings: enlarge +/- touch targets (#2), reduce tap-heavy
betting with quick-bet chips (#4), and add accessibility semantics (#8).

## Requirements
- Functional: +/- hit area ≥48×48 dp; quick-bet shortcuts let the player stake
  larger amounts fast; screen-reader users know which horse each control affects.
- Non-functional: keep `setState`-only state; no behaviour change to validation
  (over-bet still blocked, Start still gated by `game.canStartRace`).

## Architecture

**`lib/widgets/bet_row.dart`**
- `_StepButton`: increase tappable area to ≥48×48. Keep the 36 px circle visual,
  but wrap the `InkWell` so its hit target is 48×48 (e.g. `SizedBox(48,48)` around
  a centered 36 px circle, or `ConstrainedBox`/`Padding`). Border radius stays.
- Wrap each `_StepButton` in `Semantics(button: true, label: '<+/->  bet on
  ${racer.name}')`. The bare `Icon` currently announces only "add"/"remove".
- Add `Semantics(label: '${racer.name} stake ${stake} dollars')` (or
  `excludeSemantics` + label) around the `$stake` text so it reads in context.

**`lib/screens/home_betting_screen.dart`**
- Add a compact quick-bet row (small `OutlinedButton`/`ActionChip`s) per the
  betting UI, e.g. **+$50**, **Max** (bet remaining on the focused racer), and
  **Clear** (clears all bets). Simplest scoped version: a single row of chips that
  act on a "selected racer" OR three small chips appended to each `BetRow`.
  Recommended minimal approach: one **Clear All** chip + keep +/- (now $10) AND
  raise step? No — keep step $10 but add a **+$50** affordance.
  Decision for KISS: add two chips under the rows — `Clear` and `Max on <first
  unbet/any>`? That's ambiguous. FINAL: append a small **+50** button to each
  `BetRow` (next to +) so each row has `-  $X  +  +50`, and add one **Clear All**
  text button under the summary. This keeps per-row control and cuts taps.
  - `+50` clamps to wallet headroom exactly like `_increment` (reuse the clamp
    logic; never exceed `money`).
- `Clear All`: `setState(() => widget.game.clearBets());`
- **Refresh on return (`RouteAware`):** make `_HomeBettingScreenState`
  `with RouteAware`; in `didChangeDependencies` subscribe
  `appRouteObserver.subscribe(this, ModalRoute.of(context)! as PageRoute)`, in
  `dispose` `appRouteObserver.unsubscribe(this)`, and implement
  `void didPopNext() => setState(() {})`. This redraws Home with the updated
  wallet AND any bets repeated by "Play Again" when Result pops back.
  - Keep the existing post-`await` `setState` + `WalletStorage.saveMoney` in
    `_startRace` (harmless; persists money). The `didPopNext` handler is what
    guarantees the repeated-bets display.
  - Import `appRouteObserver` from `../utils/route_observer.dart` (Phase 1).
- Semantics: ensure the Start button and wallet have sensible labels (Start
  already has text; wallet `Total Money $X` is fine).

> File-ownership note: do NOT edit `game_state.dart` here — `clearBets`,
> `setBet`, and repeat APIs already exist from Phase 1.

## Related Code Files
- Modify: `lib/widgets/bet_row.dart`, `lib/screens/home_betting_screen.dart`

## Implementation Steps
1. Enlarge `_StepButton` hit area to ≥48×48; add `Semantics` to +/- and stake.
2. Add per-row `+50` quick-bet button (clamped to wallet headroom).
3. Add `Clear All` button under the summary card.
4. Make Home `RouteAware`; subscribe to `appRouteObserver`; `didPopNext → setState`.
5. `flutter analyze` (owned files + foundation) → 0 issues.

## Success Criteria
- [ ] +/- buttons have ≥48×48 hit area (visual can stay 36 px)
- [ ] `+50` quick-bet per row, clamped so total bet never exceeds wallet
- [ ] `Clear All` clears every stake
- [ ] +/- and stake have screen-reader labels naming the horse
- [ ] Home refreshes via `didPopNext` (wallet + repeated bets show on return)
- [ ] Validation unchanged: Start disabled unless `canStartRace`; over-bet blocked
- [ ] analyze clean

## Risk Assessment
- Quick-bet must reuse the exact clamp rule to avoid an over-bet path that bypasses
  validation. Mitigation: extract/reuse the headroom clamp used by `_increment`.
