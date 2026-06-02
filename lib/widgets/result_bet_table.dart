import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/racer.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatting.dart';

/// Renders the per-racer bet breakdown from a finished race.
///
/// Each row shows the racer that was staked, the stake amount, and whether
/// that racer won or lost. Winning rows are highlighted green, losing rows red.
class ResultBetTable extends StatelessWidget {
  final RaceOutcome outcome;

  const ResultBetTable({super.key, required this.outcome});

  @override
  Widget build(BuildContext context) {
    final entries = outcome.bets.entries.toList();

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No bets were placed.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: [
        _TableHeader(),
        const Divider(height: 1, thickness: 1),
        ...entries.map((entry) => _BetRow(
              entry: entry,
              winner: outcome.winner,
            )),
      ],
    );
  }
}

/// Column header row for the bet table.
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: Colors.grey[700],
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Racer', style: style)),
          Expanded(flex: 2, child: Text('Stake', style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Result', style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

/// A single row displaying the stake and outcome for one racer.
class _BetRow extends StatelessWidget {
  final MapEntry<int, int> entry;
  final Racer winner;

  const _BetRow({required this.entry, required this.winner});

  @override
  Widget build(BuildContext context) {
    // Safely look up the racer; skip row if id is out of range.
    final racers = GameConfig.racers;
    if (entry.key < 0 || entry.key >= racers.length) {
      return const SizedBox.shrink();
    }

    final racer = racers[entry.key];
    final isWin = racer.id == winner.id;
    final resultColor = isWin ? AppColors.win : AppColors.lose;
    final resultLabel = isWin ? 'WIN' : 'LOSE';
    final rowBg = isWin
        ? AppColors.win.withAlpha(20)
        : AppColors.lose.withAlpha(10);

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Racer: emoji + name colored with the racer's accent color.
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(racer.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  racer.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: racer.color,
                  ),
                ),
              ],
            ),
          ),
          // Stake amount — formatMoney keeps currency rendering consistent.
          Expanded(
            flex: 2,
            child: Text(
              formatMoney(entry.value),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          // WIN / LOSE badge.
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: resultColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resultLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
