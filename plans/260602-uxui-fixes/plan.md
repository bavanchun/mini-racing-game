---
title: "UX/UI Fixes — Mini Racing Game"
description: ""
status: in_progress
priority: P2
branch: "main"
tags: []
blockedBy: []
blocks: []
created: "2026-06-02T09:40:12.755Z"
createdBy: "ck:plan"
source: skill
---

# UX/UI Fixes — Mini Racing Game

## Overview

Fix the High + Medium findings from the UX/UI review
(`plans/reports/uxui-review-20260602-mini-racing-game.md`). Decisions locked with
user: race becomes ~6–8s with smooth motion + photo-finish pause; "Play Again"
re-uses previous bets if affordable; low-priority cosmetics (haptics, mute,
transitions, emoji variety, contrast audit) are out of scope.

Findings in scope: (1) black band on Home, (2) +/- touch targets, (3) race drama,
(4) tap-heavy betting, (5) `$-50` formatting, (6) full finishing standings,
(7) status-banner lag, (8) accessibility semantics, plus play-again-reuse-bets.

### Execution model (`--parallel`)

Phase 1 establishes shared contracts (model + constants + formatting util + app
shell). Phases 2–4 then run **in parallel** with strict file ownership (no shared
files). Phase 5 integrates, analyzes, tests, and visually verifies on the emulator.

### File ownership (no overlaps across parallel phases)

| Phase | Owns | Mode |
|-------|------|------|
| 1 Foundation | `lib/models/game_state.dart`, `lib/utils/constants.dart`, `lib/utils/formatting.dart` (new), `lib/main.dart`, `test/game_state_test.dart` | sequential (blocks 2–4) |
| 2 Betting | `lib/screens/home_betting_screen.dart`, `lib/widgets/bet_row.dart` | parallel |
| 3 Race | `lib/screens/race_screen.dart`, `lib/widgets/race_track.dart` | parallel |
| 4 Result | `lib/screens/result_screen.dart`, `lib/widgets/result_bet_table.dart` | parallel |
| 5 Integration | analyze/test/verify, commit | sequential (after 2–4) |

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Foundation & App Shell](./phase-01-foundation-app-shell.md) | Done |
| 2 | [Betting Screen](./phase-02-betting-screen.md) | Done |
| 3 | [Race Screen](./phase-03-race-screen.md) | Done |
| 4 | [Result Screen](./phase-04-result-screen.md) | Done |
| 5 | [Integration & Verification](./phase-05-integration-verification.md) | In progress (code/build/test green; on-device visual pass pending) |

## Dependencies

No cross-plan dependencies (no other unfinished plans in scope).

Internal: Phases 2, 3, 4 are all `blockedBy` Phase 1. Phase 5 is `blockedBy`
Phases 2, 3, 4.

## Validation Log

### Session 1 — 2026-06-02 (`/ck:plan validate`)

**Verification (Full tier, 5 phases):** 12 claims checked against live code —
`settleRace(winner)` 1-arg (game_state), `RaceConfig` (constants), `_StepButton`
36×36 (bet_row), `600`ms countdown + `_finished`/`_progress`/`_onRaceFinished`
(race_screen), inline net format string (result_screen), `ensureInitialized`
(main). **Verified: 12 · Failed: 0 · Unverified: 0.** Plan structurally accurate.

**Interview — 3 questions, all confirmed plan defaults:**
- Bet input → **+$50 per row + Clear All** (keep +/- at $10). No change.
- Result layout → **Final Standings + per-bet table** (both). No change.
- Finish order → **snapshot by progress** when winner crosses (no race-to-line).
  Confirms Phase 3's `finishOrder` sort approach. No change.

**Outcome:** no plan revisions required; all decisions ratified.

### Whole-Plan Consistency Sweep

Re-read `plan.md` + all 5 phase files. Checked: `settleRace` 2-arg signature
consistent across Phase 1/3/tests; `ResultScreen({game, outcome})` consistent in
contract + Phase 3 push site + Phase 4 body; `appRouteObserver` consistent in
Phase 1 (create+wire) + Phase 2 (subscribe); `formatSigned`/`formatMoney` created
in 1, used in 4; `RaceConfig` retune + `photoFinishDelay`/`countdown` defined in 1,
consumed in 3; finishOrder produced in 3, stored in 1's `RaceOutcome`, shown in 4.
**No unresolved contradictions.** Plan eligible for implementation.

## Contract changes introduced in Phase 1 (consumed by 2–4)

- `RaceOutcome` gains `final List<int> finishOrder;` — racer ids ranked 1st→last.
- `GameState.settleRace(Racer winner, List<int> finishOrder)` — new 2nd arg.
- `GameState` gains `Map<int,int> lastBets` (snapshot taken in `settleRace` before
  `clearBets`), `bool get canRepeatLastBets`, and `void repeatLastBets()`.
- New `lib/utils/formatting.dart`: `formatMoney(int)` → `"$50"`,
  `formatSigned(int)` → `"+$30"` / `"-$50"`.
- `RaceConfig` retuned for ~6–8s + a `photoFinishDelay`.
- **Route refresh (affects Phases 1 & 2):** new
  `lib/utils/route_observer.dart` exporting
  `final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();`.
  Phase 1 wires it into `MaterialApp(navigatorObservers: [appRouteObserver])`.
  Phase 2 makes Home `RouteAware` and subscribes so `didPopNext()` calls
  `setState` — this is what reliably refreshes Home's wallet AND the
  Play-Again-repeated bets when Result pops back (the old `await`-based refresh
  fires too early, before repeat runs).
- **Navigation contract change (affects Phases 3 & 4):** `ResultScreen` gains a
  `final GameState game;` — new constructor is
  `ResultScreen({super.key, required this.game, required this.outcome})`.
  Phase 3 MUST push it as
  `pushReplacement(ResultScreen(game: widget.game, outcome: outcome))`.
  Phase 4 owns the `ResultScreen` body. Both must match — Phase 5 verifies.
