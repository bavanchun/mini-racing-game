---
phase: 3
title: "Race Screen"
status: done
priority: P1
effort: "1.5h"
dependencies: [1]
---

# Phase 3: Race Screen

## Overview

Make the race the dramatic centerpiece: ~6–8s smooth motion + a photo-finish
pause (#3), fix the status-banner lag (#7), compute the full finishing order for
the Result screen (#6 data source), and add race-status semantics (#8).

## Requirements
- Functional: race lasts ~6–8s and glides smoothly; on finish, highlight the
  winner and pause (`photoFinishDelay`) before navigating; pass the full finishing
  order into `settleRace`.
- Non-functional: keep `Timer.periodic` + `AnimatedPositioned` (no Slider); keep
  the `_finished` single-fire guard and `dispose` timer cancel.

## Architecture

**`lib/screens/race_screen.dart`**
- Timing now comes from the retuned `RaceConfig` (Phase 1) — no literals here.
  Replace the hardcoded `600` countdown with `RaceConfig.countdown`.
- **Banner lag (#7):** in `_startRace()`, call `setState(() {})` after assigning
  `_timer` so the banner flips "Get Ready…" → "Racing…" immediately (currently it
  waits for the first tick). Guard with `mounted`.
- **Finishing order (#6):** when the race ends, build the full order:
  ```dart
  final order = List<int>.generate(_progress.length, (i) => i)
    ..sort((a, b) {
      final c = _progress[b].compareTo(_progress[a]); // desc progress
      return c != 0 ? c : a.compareTo(b);             // lowest id on tie
    });
  // winner is order.first (matches existing tie-break)
  ```
  Pass to `widget.game.settleRace(winner, order)`.
- **Photo finish (#3):** in `_onRaceFinished`, after `setState(() => _winnerId=…)`
  and `settleRace`, delay before navigating:
  ```dart
  await Future.delayed(RaceConfig.photoFinishDelay);
  if (!mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => ResultScreen(game: widget.game, outcome: outcome)),
  );
  ```
  NOTE the `game:` arg — `ResultScreen` gains `game` in Phase 4 (see plan.md
  contract). This is the one cross-phase coupling between 3 and 4.
  The lane already highlights the winner (gold border + 🏆 WINNER!), so the pause
  shows it off. Keep the `_finished` guard so re-entry can't double-navigate.
- **Smoothness:** with the shorter tick + smaller steps from Phase 1, the existing
  `AnimatedPositioned(duration: RaceConfig.tick, curve: Curves.linear)` already
  glides. Keep `Curves.linear` (eased per-tick looks stuttery). No structural
  change needed beyond consuming the new config.
- **Semantics (#8):** wrap `_StatusBanner` text in `Semantics(liveRegion: true,
  label: statusText)` so the race status is announced.

**`lib/widgets/race_track.dart`**
- No required change (already finish-line-accurate and Slider-free). Optional:
  ensure the horse glyph reads via `Semantics(label: racer.name)` — low cost,
  include it.

> File-ownership note: `settleRace` 2-arg signature + `RaceConfig.photoFinishDelay`
> /`countdown` come from Phase 1; do not edit `game_state.dart`/`constants.dart`.

## Related Code Files
- Modify: `lib/screens/race_screen.dart`
- Modify (optional, semantics): `lib/widgets/race_track.dart`

## Implementation Steps
1. Replace countdown literal with `RaceConfig.countdown`.
2. Add `setState` in `_startRace` (banner lag fix).
3. Build full `finishOrder`; pass to `settleRace(winner, order)`.
4. Add `photoFinishDelay` pause before `pushReplacement` (mounted-guarded).
5. Add live-region semantics to the status banner.
6. `flutter analyze` (owned files + foundation) → 0 issues.

## Success Criteria
- [ ] Race lasts ~6–8s and motion is smooth (no big jumps)
- [ ] Winner highlighted, then ~1.1s photo-finish pause before Results
- [ ] `settleRace(winner, finishOrder)` called once with the full order
- [ ] Banner shows "Racing…" immediately when the race starts
- [ ] Timer still cancelled in `dispose`; single-fire guard intact
- [ ] analyze clean

## Risk Assessment
- The new `Future.delayed` adds an async gap before navigation; if the user backs
  out during the pause the `mounted` guard prevents a crash. Verify `_finished`
  still blocks a second navigation.
- Tuning may land outside 6–8s on fast devices; Phase 5 measures actual duration
  and nudges `RaceConfig` if needed.
