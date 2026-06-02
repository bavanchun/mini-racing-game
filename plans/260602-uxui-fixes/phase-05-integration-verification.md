---
phase: 5
title: "Integration & Verification"
status: pending
priority: P1
effort: "1h"
dependencies: [2, 3, 4]
---

# Phase 5: Integration & Verification

## Overview

Reconcile the parallel workstreams, prove the build is clean, and visually verify
every fix on the running emulator before committing.

## Requirements
- Functional: app compiles, all tests pass, every in-scope finding visibly fixed.
- Non-functional: no regressions to the verified payout math or navigation loop.

## Integration checklist (cross-phase couplings)
- [ ] `ResultScreen` constructor (`game` + `outcome`) matches the Race push site
      (Phase 3 ↔ Phase 4). Compile error if mismatched — fix immediately.
- [ ] `settleRace(winner, finishOrder)` — all callers (Race + tests) pass 2 args.
- [ ] `formatting.dart` imported wherever money is rendered (Result).
- [ ] No stale references to the old `RaceConfig` step values / `600` literal.

## Verification steps
1. `flutter analyze` → **0 issues** (whole project).
2. `flutter test` → all green (incl. new finishOrder / repeatLastBets tests).
3. Hot-restart on emulator (`R` in the live `flutter run`, or relaunch).
4. **Visual checks (screenshot each):**
   - Home: **no black band** at the bottom (gradient behind nav bar). #1
   - +/- buttons easy to hit; `+50` and `Clear All` work; over-bet still blocked. #2 #4
   - Race: time it — **~6–8s**, smooth glide, winner highlight + ~1.1s pause. #3 #7
   - Result: **Final Standings** shows all 3 in order; Net reads **`-$50`/`+$30`**. #5 #6
   - Play Again → returns to betting with **prior bets pre-filled** (if affordable);
     Back to Home → empty betting. (play-again)
   - Persistence + broke-reset still work (regression).
5. If the Home black band persists, apply fallback (wrap gradient in
   `SizedBox.expand`) and re-verify.

## Related Code Files
- None new — verification + a commit. Touch fixes only if a check fails.

## Implementation Steps
1. Run analyze + test; fix any cross-phase mismatch.
2. Hot-restart + run the visual checklist, capturing screenshots.
3. Address any failed check in the owning file.
4. Re-run analyze + test until green.
5. Commit (`fix: address UX/UI review findings ...`) and push.
6. Mark all phases complete (`ck plan check`).

## Success Criteria
- [ ] `flutter analyze` clean; `flutter test` green; `flutter build` compiles
- [ ] All 8 in-scope findings + play-again verified on-device via screenshots
- [ ] No regression to payout math, persistence, or broke-reset
- [ ] Changes committed and pushed

## Risk Assessment
- Parallel edits could leave a signature mismatch; the analyze step is the
  backstop (compile errors surface immediately).
- Race timing is device-dependent; if outside 6–8s, nudge `RaceConfig` (Phase 1
  file) and re-time.
