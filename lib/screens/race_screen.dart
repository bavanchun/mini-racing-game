import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/race_track.dart';
import 'result_screen.dart';

/// Animates the three-horse race and navigates to [ResultScreen] when one wins.
///
/// Layout: three [RaceTrack] lanes stacked vertically, each driven by a
/// `_progress` value in [0.0, 1.0]. A [Timer.periodic] advances every racer
/// by a random amount each tick — no Slider widget is used anywhere.
class RaceScreen extends StatefulWidget {
  final GameState game;
  const RaceScreen({super.key, required this.game});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  /// Live positions for each racer, indexed by [Racer.id].
  late List<double> _progress;

  /// Prevents [_onRaceFinished] from firing more than once when two racers
  /// reach >= 1.0 on the same tick (the timer callback is synchronous so there
  /// is no race condition between ticks, only within one tick).
  bool _finished = false;

  Timer? _timer;
  final Random _rng = Random();

  /// Index of the winner once the race ends, used only for the UI highlight
  /// while the navigation push is in flight.
  int? _winnerId;

  @override
  void initState() {
    super.initState();
    _progress = List<double>.filled(GameConfig.racers.length, 0.0);

    // Short countdown pause before the race begins — improves perceived polish.
    Future.delayed(const Duration(milliseconds: 600), _startRace);
  }

  /// Kicks off the periodic timer that drives all racer positions forward.
  void _startRace() {
    if (!mounted) return;
    _timer = Timer.periodic(RaceConfig.tick, _onTick);
  }

  /// Called every [RaceConfig.tick]. Advances every racer independently by a
  /// random step drawn from [RaceConfig.minStep, RaceConfig.maxStep].
  ///
  /// After updating all positions we check for a winner. Checking after ALL
  /// racers have moved ensures simultaneous finishers are handled in one pass
  /// rather than stopping the first racer mid-tick before others advance.
  void _onTick(Timer _) {
    if (_finished) return;

    setState(() {
      for (int i = 0; i < _progress.length; i++) {
        final step = RaceConfig.minStep +
            _rng.nextDouble() * (RaceConfig.maxStep - RaceConfig.minStep);
        _progress[i] = (_progress[i] + step).clamp(0.0, 1.0);
      }
    });

    _checkForWinner();
  }

  /// Determines whether at least one racer has crossed the finish line.
  ///
  /// Tie-break rule: highest progress wins; equal progress resolved by lowest
  /// [Racer.id] — gives a deterministic result regardless of list order.
  void _checkForWinner() {
    if (_finished) return;

    // Collect all finishers from this tick.
    final finishers = <int>[];
    for (int i = 0; i < _progress.length; i++) {
      if (_progress[i] >= 1.0) finishers.add(i);
    }
    if (finishers.isEmpty) return;

    // Highest progress → if still tied, lowest id wins.
    finishers.sort((a, b) {
      final cmp = _progress[b].compareTo(_progress[a]); // descending progress
      return cmp != 0 ? cmp : a.compareTo(b); // ascending id on tie
    });

    _onRaceFinished(finishers.first);
  }

  /// Locks the race, cancels the timer, settles bets, and navigates away.
  ///
  /// The `_finished` guard ensures this runs exactly once even if the timer
  /// fires again between cancel() and disposal.
  void _onRaceFinished(int winnerId) {
    _finished = true;
    _timer?.cancel();
    _timer = null;

    setState(() => _winnerId = winnerId);

    final winner = GameConfig.racers[winnerId];
    final outcome = widget.game.settleRace(winner);

    // Always guard with mounted before using context after an async gap.
    // Even though settleRace is synchronous, the setState above schedules a
    // frame, so we may technically be between frames here.
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(outcome: outcome)),
    );
  }

  @override
  void dispose() {
    // Cancel the timer on disposal to prevent callbacks firing on a dead widget.
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRunning = _timer != null && !_finished;
    final String statusText = _finished
        ? '${GameConfig.racers[_winnerId!].name} wins!'
        : isRunning
            ? 'Racing...'
            : 'Get Ready...';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🏇  Race',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        automaticallyImplyLeading: false, // no back button mid-race
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status banner
            _StatusBanner(
              text: statusText,
              isFinished: _finished,
              winnerColor: _winnerId != null
                  ? GameConfig.racers[_winnerId!].color
                  : null,
            ),

            // Bet summary strip
            _BetSummary(game: widget.game),

            const SizedBox(height: 8),

            // The three race tracks
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: GameConfig.racers.length,
                itemBuilder: (context, index) {
                  final racer = GameConfig.racers[index];
                  return RaceTrack(
                    racer: racer,
                    progress: _progress[racer.id],
                    isWinner: _winnerId == racer.id,
                    animationDuration: RaceConfig.tick,
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets (kept here as they are only used by RaceScreen)
// ---------------------------------------------------------------------------

/// Prominent banner at the top of the screen showing race status.
class _StatusBanner extends StatelessWidget {
  final String text;
  final bool isFinished;
  final Color? winnerColor;

  const _StatusBanner({
    required this.text,
    required this.isFinished,
    this.winnerColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isFinished
        ? (winnerColor ?? AppColors.win).withValues(alpha: 0.15)
        : AppColors.sky.withValues(alpha: 0.1);

    final textColor = isFinished ? (winnerColor ?? AppColors.win) : AppColors.sky;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Compact row showing which racers have bets and for how much.
class _BetSummary extends StatelessWidget {
  final GameState game;
  const _BetSummary({required this.game});

  @override
  Widget build(BuildContext context) {
    final bets = game.bets;
    if (bets.isEmpty) return const SizedBox.shrink();

    final chips = bets.entries.map((e) {
      final racer = GameConfig.racers[e.key];
      return Chip(
        avatar: Text(racer.emoji, style: const TextStyle(fontSize: 14)),
        label: Text(
          '${racer.name}: \$${e.value}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: racer.color.withValues(alpha: 0.15),
        side: BorderSide(color: racer.color, width: 1),
        padding: EdgeInsets.zero,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'Your bets:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          ...chips,
        ],
      ),
    );
  }
}
