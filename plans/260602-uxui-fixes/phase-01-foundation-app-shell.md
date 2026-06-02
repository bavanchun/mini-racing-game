---
phase: 1
title: "Foundation & App Shell"
status: done
priority: P1
effort: "1.5h"
dependencies: []
---

# Phase 1: Foundation & App Shell

## Overview

Establish the shared contracts every screen depends on: finishing-order data,
play-again-reuse state, a money-formatting util, retuned race timing, and the
edge-to-edge app shell fix. Blocks Phases 2–4.

## Requirements
- Functional: RaceOutcome carries full finishing order; GameState can repeat the
  last bets; money formats consistently with sign; Home draws edge-to-edge (no
  black nav-bar band); race timing supports a ~6–8s smooth race + photo finish.
- Non-functional: no behavioural change to the verified 3× payout math; existing
  tests updated to the new `settleRace` signature.

## Architecture

**`lib/models/game_state.dart`**
- Add `final List<int> finishOrder;` to `RaceOutcome` (racer ids, index 0 = 1st).
- Change `RaceOutcome` constructor to require `finishOrder`.
- Add to `GameState`:
  - `Map<int,int> lastBets = {};`
  - In `settleRace(Racer winner, List<int> finishOrder)`: snapshot
    `lastBets = Map.from(bets);` BEFORE `clearBets()`, and pass `finishOrder`
    into the returned `RaceOutcome`.
  - `bool get canRepeatLastBets => lastBets.isNotEmpty &&
       lastBets.values.fold(0,(a,b)=>a+b) <= money;`
  - `void repeatLastBets()` → `bets..clear()..addAll(lastBets)` (only if
    affordable; caller guards with `canRepeatLastBets`).
- Payout math UNCHANGED: `money = money - totalBet + stakeOnWinner * 3`.

**`lib/utils/formatting.dart` (new)**
```dart
String formatMoney(int v) => '\$$v';
String formatSigned(int v) => v < 0 ? '-\$${-v}' : '+\$$v';
```

**`lib/utils/constants.dart`**
- Retune `RaceConfig` for ~6–8s smooth motion. Smoother = shorter tick + smaller
  steps. Target: `tick = 80ms`, `minStep = 0.006`, `maxStep = 0.018`
  (avg ≈0.012 → ~83 ticks → ~6.6s). Keep within [0,1].
- Add `static const Duration photoFinishDelay = Duration(milliseconds: 1100);`
- Add `static const Duration countdown = Duration(milliseconds: 600);` (extract
  the existing magic number so Race screen references it).

**`lib/main.dart`** — edge-to-edge fix (finding #1)
- In `main()` after `ensureInitialized()`:
  ```dart
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  ```
- Import `package:flutter/services.dart`.
- This makes the gradient show behind the system nav bar on all screens
  (removes the Home black band). Verify in Phase 5.
- Wire the route observer (below) into `MaterialApp`:
  `navigatorObservers: [appRouteObserver]`.

**`lib/utils/route_observer.dart` (new)** — fixes the stale-Home refresh bug
```dart
import 'package:flutter/widgets.dart';
/// Lets screens refresh when a pushed route pops back to them.
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();
```
Rationale: Home's `await Navigator.push(Race)` completes when Race is
*replaced* by Result (early), so a post-await `setState` runs before
"Play Again" repeats the bets. `didPopNext()` (Phase 2) is the correct trigger.

**`test/game_state_test.dart`**
- Update all `settleRace(winner)` calls to `settleRace(winner, finishOrder)`
  (e.g. `[winner.id, otherId1, otherId2]`).
- Add tests: `finishOrder` is preserved in outcome; `repeatLastBets` restores the
  previous stakes; `canRepeatLastBets` is false when the snapshot exceeds wallet.

## Related Code Files
- Create: `lib/utils/formatting.dart`, `lib/utils/route_observer.dart`
- Modify: `lib/models/game_state.dart`, `lib/utils/constants.dart`,
  `lib/main.dart`, `test/game_state_test.dart`

## Implementation Steps
1. Add `finishOrder` + `lastBets` + repeat API to `game_state.dart`; change
   `settleRace` signature.
2. Create `formatting.dart`.
3. Retune `RaceConfig` + add `photoFinishDelay`/`countdown` in `constants.dart`.
4. Add edge-to-edge calls + import to `main.dart`.
5. Update + extend `game_state_test.dart`.
6. `flutter analyze` (foundation files) → 0 issues. `flutter test` → green.

## Success Criteria
- [ ] `RaceOutcome.finishOrder` exists; `settleRace` takes 2 args; payout math unchanged
- [ ] `GameState.repeatLastBets` / `canRepeatLastBets` implemented
- [ ] `formatting.dart` created with `formatMoney`/`formatSigned`
- [ ] `RaceConfig` retuned (~6–8s) + `photoFinishDelay` + `countdown`
- [ ] `main.dart` edge-to-edge enabled
- [ ] `route_observer.dart` created + wired into `MaterialApp.navigatorObservers`
- [ ] `flutter analyze` clean; `flutter test` passes (with updated signatures)

## Risk Assessment
- Changing `settleRace` signature breaks callers (Race screen + tests). Mitigation:
  Phase 3 + tests updated in the same plan; analyze in Phase 5 catches stragglers.
- Edge-to-edge root cause was ~60% confident in review; if the black band persists
  after this fix, fall back to wrapping the gradient in `SizedBox.expand` and
  re-test (noted in Phase 5).
