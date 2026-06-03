import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatting.dart';
import '../widgets/app_background.dart';
import '../widgets/result_bet_table.dart';

/// Hiển thị bảng xếp hạng cuối cùng và phân tích chi tiết payout sau cuộc đua.
///
/// Nhận một [RaceOutcome] bất biến đã được giải quyết bởi màn hình Race — nó
/// không bao giờ gọi [GameState.settleRace]. Cũng nhận [GameState] trực tiếp để
/// "Play Again" có thể khôi phục cược trước khi ví vẫn có thể chi trả.
/// Nó là StatefulWidget chỉ để nó có thể phát tín hiệu âm thanh thắng/thua một lần khi
/// được hiển thị lần đầu.
class ResultScreen extends StatefulWidget {
  final GameState game;
  final RaceOutcome outcome;

  const ResultScreen({
    super.key,
    required this.game,
    required this.outcome,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    // Play the appropriate cue once, based on whether the player won.
    if (widget.outcome.didWin) {
      SoundService.playWin();
    } else {
      SoundService.playLose();
    }
  }

  /// "Play Again": khôi phục cược trước khi ví có thể chi trả, sau đó đi
  /// home để màn hình Home đọc lại [GameState.bets] đã được điền.
  /// Fallback về navigation home thường khi ví quá thấp.
  void _playAgain(BuildContext context) {
    if (widget.game.canRepeatLastBets) {
      widget.game.repeatLastBets();
    }
    // Navigate home in both branches — Home will show either the restored bets
    // or a clean slate, depending on what happened above.
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  /// "Back to Home": luôn trả về cược mới với không khôi phục cược.
  void _backToHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.outcome;
    final canRepeat = widget.game.canRepeatLastBets;

    return GradientScaffold(
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
              _StandingsCard(outcome: outcome),
              const SizedBox(height: 16),
              _PlayerOutcomeCard(outcome: outcome),
              const SizedBox(height: 16),
              _BetResultsCard(outcome: outcome),
              const SizedBox(height: 16),
              _SummaryCard(outcome: outcome),
              const SizedBox(height: 28),
              _ActionButtons(
                canRepeat: canRepeat,
                onPlayAgain: () => _playAgain(context),
                onBackHome: () => _backToHome(context),
              ),
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

/// Headline lớn thông báo con ngựa thắng.
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
// Final standings card
// ---------------------------------------------------------------------------

/// Shows all three racers ranked in finish order (1st → 3rd) so the player
/// can see where every horse placed, not just whether their bets won.
class _StandingsCard extends StatelessWidget {
  final RaceOutcome outcome;

  const _StandingsCard({required this.outcome});

  static const List<String> _medals = ['🥇', '🥈', '🥉'];
  static const List<String> _positions = ['1st', '2nd', '3rd'];

  @override
  Widget build(BuildContext context) {
    final racers = GameConfig.racers;
    final order = outcome.finishOrder;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Final Standings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(order.length, (i) {
              final id = order[i];
              // Guard against an out-of-range id from a malformed outcome.
              if (id < 0 || id >= racers.length) return const SizedBox.shrink();
              final racer = racers[id];
              final medal = i < _medals.length ? _medals[i] : '  ';
              final posLabel = i < _positions.length ? _positions[i] : '${i + 1}th';
              final isWinner = i == 0;

              return Semantics(
                label: '$posLabel: ${racer.name}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // Medal emoji — aria label provided by Semantics above.
                      Text(medal, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        racer.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          racer.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: racer.color,
                          ),
                        ),
                      ),
                      // Small "winner" tag on the 1st-place entry.
                      if (isWinner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gold,
                              width: 1.2,
                            ),
                          ),
                          child: const Text(
                            'winner',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
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
                      // Use formatMoney for consistent currency rendering.
                      'You receive ${formatMoney(outcome.payout)} back.',
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
              // formatMoney ensures consistent "$N" currency rendering.
              value: formatMoney(outcome.totalStaked),
              valueColor: Colors.black87,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Returned',
              value: formatMoney(outcome.payout),
              valueColor: Colors.black87,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Net',
              // formatSigned produces "+$30" / "-$50" so the sign and the "$"
              // are in the correct order (fixes the "$-50" rendering bug).
              value: formatSigned(outcome.netChange),
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
                    formatMoney(outcome.moneyAfter),
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

/// "Play Again" (primary) and "Back to Home" (outlined) with distinct behavior:
/// Play Again restores the previous stakes when the wallet allows; Back to Home
/// always navigates to fresh betting with no bet restoration.
class _ActionButtons extends StatelessWidget {
  final bool canRepeat;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackHome;

  const _ActionButtons({
    required this.canRepeat,
    required this.onPlayAgain,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: onPlayAgain,
          child: const Text('Play Again'),
        ),
        // Hint: when prior bets cannot be repeated due to insufficient funds,
        // a subtle note clarifies why "Play Again" starts fresh.
        if (!canRepeat)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Not enough to repeat last bets — starting fresh',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onBackHome,
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
