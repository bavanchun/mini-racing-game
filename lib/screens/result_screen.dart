import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/result_bet_table.dart';

/// Displays the final standings and payout breakdown after a race.
///
/// Purely presentational — receives an immutable [RaceOutcome] that was
/// already settled by the Race screen. Never calls [GameState.settleRace].
class ResultScreen extends StatelessWidget {
  final RaceOutcome outcome;

  const ResultScreen({super.key, required this.outcome});

  /// Both navigation actions pop back to the Home screen (the first route).
  void _goHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WinnerBanner(outcome: outcome),
              const SizedBox(height: 16),
              _PlayerOutcomeCard(outcome: outcome),
              const SizedBox(height: 16),
              _BetResultsCard(outcome: outcome),
              const SizedBox(height: 16),
              _SummaryCard(outcome: outcome),
              const SizedBox(height: 28),
              _ActionButtons(onTap: () => _goHome(context)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Winner banner
// ---------------------------------------------------------------------------

/// Large headline announcing the winning horse.
class _WinnerBanner extends StatelessWidget {
  final RaceOutcome outcome;

  const _WinnerBanner({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final winner = outcome.winner;

    return Card(
      color: AppColors.turfDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          children: [
            Text(
              winner.emoji,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 8),
            Text(
              '🏆 ${winner.name} wins!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: winner.color,
                shadows: const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player outcome (won / lost)
// ---------------------------------------------------------------------------

/// Tells the player whether they personally won and how much they received.
class _PlayerOutcomeCard extends StatelessWidget {
  final RaceOutcome outcome;

  const _PlayerOutcomeCard({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final didWin = outcome.didWin;

    return Card(
      color: didWin
          ? AppColors.win.withAlpha(30)
          : AppColors.lose.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Text(
              didWin ? '🎉' : '😔',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    didWin ? 'You won!' : 'Better luck next time!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: didWin ? AppColors.win : AppColors.lose,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (didWin)
                    Text(
                      'You receive \$${outcome.payout} back.',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    )
                  else
                    const Text(
                      'Your stakes did not back the winner.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bet results table card
// ---------------------------------------------------------------------------

/// Wraps [ResultBetTable] in a titled card.
class _BetResultsCard extends StatelessWidget {
  final RaceOutcome outcome;

  const _BetResultsCard({required this.outcome});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'Your Bets',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            ResultBetTable(outcome: outcome),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Race summary card
// ---------------------------------------------------------------------------

/// Financial summary: staked, payout, net, and remaining wallet.
class _SummaryCard extends StatelessWidget {
  final RaceOutcome outcome;

  const _SummaryCard({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final netPositive = outcome.netChange >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Race Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Total Staked',
              value: '\$${outcome.totalStaked}',
              valueColor: Colors.black87,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Returned',
              value: '\$${outcome.payout}',
              valueColor: Colors.black87,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Net',
              value: '${netPositive ? '+' : ''}\$${outcome.netChange}',
              valueColor: netPositive ? AppColors.win : AppColors.lose,
              bold: true,
            ),
            const Divider(height: 24, thickness: 1),
            // Total money — prominently highlighted in gold.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Money',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '\$${outcome.moneyAfter}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single label/value pair for the summary card.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action buttons
// ---------------------------------------------------------------------------

/// "Play Again" (primary) and "Back to Home" (outlined) — both navigate home.
class _ActionButtons extends StatelessWidget {
  final VoidCallback onTap;

  const _ActionButtons({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: onTap,
          child: const Text('Play Again'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.turf,
            side: const BorderSide(color: AppColors.turf, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}
