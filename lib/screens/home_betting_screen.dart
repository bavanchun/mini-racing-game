import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/route_observer.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import '../services/wallet_storage.dart';
import '../widgets/app_background.dart';
import '../widgets/bet_row.dart';
import 'race_screen.dart';

/// The entry point / lobby screen where the player places bets before a race.
///
/// Owns a single mutable [GameState] instance passed from main.dart. After
/// [RaceScreen] completes (via `await`), we call `setState` so the wallet
/// balance and any cleared bets reflect the settled race outcome.
///
/// Also subscribes to [appRouteObserver] via [RouteAware] so that when the
/// Result screen pops back (possibly after a "Play Again" repeat), `didPopNext`
/// triggers a rebuild — reliably refreshing the wallet and repeated bets even
/// if the `await` in `_startRace` already resolved earlier (which it does when
/// Race is *replaced* by Result using pushReplacement).
class HomeBettingScreen extends StatefulWidget {
  final GameState game;

  const HomeBettingScreen({super.key, required this.game});

  @override
  State<HomeBettingScreen> createState() => _HomeBettingScreenState();
}

class _HomeBettingScreenState extends State<HomeBettingScreen> with RouteAware {
  /// How many dollars each +/- button press changes a stake.
  static const int _step = 10;

  /// Fixed amount added by the per-row quick-bet button.
  static const int _quickBetAmount = 50;

  // ── RouteAware lifecycle ──────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe so didPopNext fires when a screen on top of Home is popped.
    appRouteObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when the screen that was pushed on top of this one pops back.
  /// Rebuilds so the wallet balance and any "Play Again" repeated bets are
  /// shown immediately, regardless of when the original `await` resolved.
  @override
  void didPopNext() => setState(() {});

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Current stake for [racerId], defaulting to 0 if none has been placed yet.
  int _stakeFor(int racerId) => widget.game.bets[racerId] ?? 0;

  /// Remaining money the player can still bet (may not go negative).
  int get _remaining => widget.game.money - widget.game.totalBet;

  // ── bet mutation ──────────────────────────────────────────────────────────

  /// Increase the stake on [racer] by [_step], but never let totalBet exceed
  /// the player's wallet — silently clamping prevents over-betting without
  /// crashing. A SnackBar notifies the player when the ceiling is hit.
  void _increment(int racerId) {
    final headroom = _headroom();
    if (headroom <= 0) {
      _showOverBetSnackBar();
      return;
    }
    final added = headroom < _step ? headroom : _step;
    setState(() {
      widget.game.setBet(racerId, _stakeFor(racerId) + added);
    });
  }

  /// Decrease the stake on [racer] by [_step], clamping at 0.
  void _decrement(int racerId) {
    final current = _stakeFor(racerId);
    if (current <= 0) return;
    setState(() {
      widget.game.setBet(racerId, current - _step);
    });
  }

  /// Add [_quickBetAmount] to the stake for [racerId], clamped to the same
  /// wallet headroom rule as [_increment] — total bets can never exceed money.
  void _quickBet(int racerId) {
    final headroom = _headroom();
    if (headroom <= 0) {
      _showOverBetSnackBar();
      return;
    }
    final added = headroom < _quickBetAmount ? headroom : _quickBetAmount;
    setState(() {
      widget.game.setBet(racerId, _stakeFor(racerId) + added);
    });
  }

  /// How much money is still available to bet.
  /// Extracted so both [_increment] and [_quickBet] share the exact same rule.
  int _headroom() => widget.game.money - widget.game.totalBet;

  void _showOverBetSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You can't bet more than your wallet holds!"),
        backgroundColor: AppColors.lose,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── navigation ────────────────────────────────────────────────────────────

  /// Launch the race, then refresh state when control returns to this screen.
  /// The `await` means we wait for the full Race + Result flow to pop back here.
  Future<void> _startRace() async {
    SoundService.playStart(); // race-start cue (fire-and-forget)
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RaceScreen(game: widget.game)),
    );
    // RaceScreen calls settleRace and ResultScreen pops back to us.
    // Refresh wallet balance and cleared bets after settling, then persist.
    if (mounted) setState(() {});
    WalletStorage.saveMoney(widget.game.money);
  }

  // ── reset wallet ──────────────────────────────────────────────────────────

  /// Reset the player's wallet to the starting amount and clear any bets.
  /// Only shown when the player has run out of money.
  void _resetWallet() {
    setState(() {
      widget.game.money = GameConfig.startingMoney;
      widget.game.clearBets();
    });
    WalletStorage.saveMoney(widget.game.money);
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('🐎 Place Your Bets'),
      ),
      body: SafeArea(
        child: widget.game.money <= 0
            ? _buildBrokeState(context)
            : _buildBettingUI(context),
      ),
    );
  }

  // ── broke state ───────────────────────────────────────────────────────────

  /// Friendly screen shown when the player's wallet is empty.
  Widget _buildBrokeState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😢', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              "You're out of money!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.lose,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Better luck next time. Reset your wallet to play again.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _resetWallet,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Wallet'),
            ),
          ],
        ),
      ),
    );
  }

  // ── main betting UI ───────────────────────────────────────────────────────

  Widget _buildBettingUI(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalBet = widget.game.totalBet;
    final canStart = widget.game.canStartRace;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Wallet card ────────────────────────────────────────────────
          _WalletCard(money: widget.game.money),

          const SizedBox(height: 20),

          // ── Section label ──────────────────────────────────────────────
          Text(
            'Choose your horses:',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.turfDark,
            ),
          ),
          const SizedBox(height: 8),

          // ── One BetRow per racer ───────────────────────────────────────
          for (final racer in GameConfig.racers)
            BetRow(
              racer: racer,
              stake: _stakeFor(racer.id),
              step: _step,
              onDecrement: () => _decrement(racer.id),
              onIncrement: () => _increment(racer.id),
              onQuickBet: () => _quickBet(racer.id),
            ),

          const SizedBox(height: 16),

          // ── Summary card ───────────────────────────────────────────────
          _SummaryCard(totalBet: totalBet, remaining: _remaining),

          // ── Clear All ─────────────────────────────────────────────────
          // Lets the player wipe all stakes in one tap rather than
          // decrementing every row individually.
          if (totalBet > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => widget.game.clearBets()),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lose,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ── Start Race button ──────────────────────────────────────────
          // Disabled when canStartRace is false (no bets or over-budget).
          ElevatedButton.icon(
            onPressed: canStart ? _startRace : null,
            icon: const Text('🏁', style: TextStyle(fontSize: 20)),
            label: const Text('Start Race'),
            style: ElevatedButton.styleFrom(
              // Override disabled appearance to make it visually obvious.
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 8),

          if (!canStart && totalBet == 0)
            Text(
              'Place at least \$$_step on a horse to start.',
              style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

// ── Extracted private widgets (keep the main class under 200 lines) ──────────

/// Prominent wallet display shown at the top of the betting screen.
class _WalletCard extends StatelessWidget {
  final int money;

  const _WalletCard({required this.money});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.turfDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Money',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '\$$money',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live summary card showing total bet placed and remaining balance.
class _SummaryCard extends StatelessWidget {
  final int totalBet;
  final int remaining;

  const _SummaryCard({required this.totalBet, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: AppColors.rail,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SummaryItem(
              label: 'Total Bet',
              value: '\$$totalBet',
              valueColor: totalBet > 0 ? AppColors.lose : Colors.grey,
              textTheme: textTheme,
            ),
            Container(width: 1, height: 36, color: Colors.grey.shade300),
            _SummaryItem(
              label: 'Remaining',
              value: '\$$remaining',
              valueColor: remaining > 0 ? AppColors.win : Colors.grey,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final TextTheme textTheme;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
