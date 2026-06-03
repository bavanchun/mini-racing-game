# UX/UI Evaluation — Mini Racing Game

Date: 2026-06-02 · Method: live black-box test on Pixel 8 emulator (Android 15) +
full read of all UI source. Screenshots in `/tmp/ux-review/`.

## Overall verdict

Strong for a course lab. Cohesive "race day" visual identity, clear information
hierarchy, consistent color-coding of racers across all three screens, and good
real-time feedback. The race screen is genuinely game-like (lanes, color dots,
checkered finish, progress fill, countdown). Main weaknesses: one real layout bug
on Home, sub-spec touch targets, and a race that finishes too fast to enjoy.

Rough grade against the rubric: works correctly ✅, UI clarity strong (≈26/30),
logic verified live ✅. Biggest UX upside is in the "watch the race" moment.

## Strengths (keep)

- **Theme cohesion** — sky→turf→cream gradient, gold money accent, dark-green app
  bars. Consistent and pleasant.
- **Color identity per racer** (Thunder red / Blaze blue / Shadow green) carried
  across betting rows, race lanes, result table, and winner banner — excellent
  mental model; user tracks "their" horse easily.
- **Feedback is immediate**: Start disabled + hint text until a valid bet; live
  "Total Bet / Remaining"; "−" greyed at $0; red SnackBar on over-bet; stake turns
  gold when > 0.
- **Result screen** is information-rich and well-ordered: winner banner → personal
  win/lose card → bet table with WIN/LOSE badges → financial summary → gold wallet.
- **Edge states handled**: broke state ("You're out of money" + Reset), empty bet
  table fallback.
- Money logic verified live: bet $50, all lost → $200 → $150 (−$50). Correct.

## Findings (prioritized)

### High

1. **Black band at bottom of Home screen only.** Reproducible (see `01`,`02`,`05`).
   Race and Result draw the gradient edge-to-edge behind the system navigation
   bar; Home shows a solid black strip there instead. Visual inconsistency on the
   first screen users see. Likely Android-15 edge-to-edge handling on the `home`
   route. Fix: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` +
   transparent system nav bar in `main`, and/or wrap the background in
   `SizedBox.expand`. (Root cause ~60% confident — verify on fix.)

2. **Touch targets too small.** `_StepButton` (+/−) is 36×36 dp; Material/WCAG
   minimum is 48×48. Easy to mis-tap (I missed the Start button twice during
   testing for a related reason). Bump to ≥48×48 hit area.

3. **Race finishes too fast / low drama.** ~3 s but the horses visually jump and
   the result appears almost immediately. The core "watch the race" payoff is the
   emotional center of a betting game — currently underdelivered. Lengthen the
   race (smaller steps / longer track), ease the motion, and/or add a brief
   "photo finish" pause before navigating to results.

### Medium

4. **Betting is tap-heavy.** Only +/− in $10 steps → betting $100 = 10 taps. Add
   quick chips (e.g. +$50, Max, Clear) or a TextField (the spec explicitly allowed
   a TextField as an alternative to +/−).

5. **Net value formatting**: shows `$-50`; should read `-$50`.

6. **Result table omits non-bet horses.** Only staked racers appear, so the
   winning horse can be absent from the table. Show all three with a finishing
   order (or at least always include the winner) for a clearer recap.

7. **Status banner lag.** `_startRace()` sets the timer but doesn't `setState`, so
   the banner stays "Get Ready…" until the first tick (~120 ms) flips it to
   "Racing…". Trivial: call `setState` when starting.

8. **Accessibility gaps.** +/− buttons have no `Semantics` label tied to the horse
   (screen reader says only "add"/"remove"); horses are emoji-only with no
   semantic label. Add `Semantics(label: 'Increase bet on ${racer.name}')` etc.

### Low / polish

9. **All horses use the same 🐎 glyph** — only the color dot + name differentiate.
   Consider per-horse tint, a number, or jockey-silhouette to strengthen identity.

10. **No haptics** on bet change / win / lose — cheap, high-perceived-polish win
    (`HapticFeedback.selectionClick()` / `.heavyImpact()`).

11. **"Play Again" == "Back to Home"** (both `popUntil` first). Redundant. Make
    "Play Again" re-run with the same bets (if affordable) so the labels differ.

12. **No mute / sound toggle**; no screen-transition animation (default Material).

13. **Contrast**: red `Thunder` (#E53935) name on cream — borderline for small
    text; verify WCAG AA (≈3:1 for bold ≥18px is fine, but worth a check). Gold on
    dark-green and white badges are good.

## Heuristic scorecard

| Heuristic | Rating | Note |
|-----------|:------:|------|
| Visibility of system status | 4/5 | Strong feedback; minor banner lag |
| Match real world | 5/5 | Betting/odds metaphor clear |
| User control / freedom | 3/5 | No back mid-race (intended); redundant result buttons |
| Consistency & standards | 4/5 | Great color system; Home bg bug breaks it |
| Error prevention | 5/5 | Over-bet blocked, Start gated |
| Recognition vs recall | 5/5 | Bets echoed on race + result |
| Flexibility / efficiency | 2/5 | Tap-heavy betting, no shortcuts |
| Aesthetic & minimalist | 4/5 | Clean; race could be more cinematic |
| Help users recover | 4/5 | Broke-reset present |
| Accessibility | 2/5 | Small targets, no semantics, emoji-only |

## Quick wins (impact ÷ effort)

1. Fix Home black band (edge-to-edge) — high impact, ~10 min.
2. Enlarge +/− to 48×48 — high, ~5 min.
3. Slow + ease the race + photo-finish pause — high, ~30 min.
4. Betting quick-chips / TextField — medium, ~30 min.
5. `-$50` formatting + banner `setState` + haptics — low effort, nice polish.

## Unresolved questions

- Intended race duration / how cinematic should the race feel?
- Primary grading platform (Android / iOS / web)? Affects edge-to-edge priority and
  whether web audio-autoplay limits matter.
- Should "Play Again" reuse the previous bets, or always return to fresh betting?
