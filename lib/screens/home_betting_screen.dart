import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/route_observer.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import '../services/user_storage.dart';
import '../services/wallet_storage.dart';
import '../widgets/app_background.dart';
import '../widgets/bet_row.dart';
import 'race_screen.dart';

/// Điểm nhập / màn hình sảnh nơi người chơi đặt cược trước cuộc đua.
///
/// Sở hữu một instance [GameState] có thể thay đổi đơn được truyền từ main.dart. Sau
/// [RaceScreen] hoàn thành (qua `await`), chúng ta gọi `setState` để số dư
/// ví và bất kỳ cược đã xóa phản ánh outcome cuộc đua đã giải quyết.
///
/// Cũng đăng ký với [appRouteObserver] qua [RouteAware] để khi màn hình
/// Result pop back (có thể sau khi lặp "Play Again"), `didPopNext`
/// kích hoạt rebuild — refresh đáng tin cậy ví và cược lặp lại ngay cả
/// nếu `await` trong `_startRace` đã giải quyết sớm hơn (điều nó làm khi
/// Race được *thay thế* bởi Result dùng pushReplacement).
class HomeBettingScreen extends StatefulWidget {
  final int initialMoney;
  final String? username;

  const HomeBettingScreen({
    super.key, 
    required this.initialMoney,
    this.username,
  });

  @override
  State<HomeBettingScreen> createState() => _HomeBettingScreenState();
}

class _HomeBettingScreenState extends State<HomeBettingScreen> with RouteAware {
  late final GameState _game = GameState(money: widget.initialMoney);
  
  /// Số đô la mỗi lần nhấn nút +/- thay đổi cược.
  static const int _step = 10;

  /// Số tiền cố định được thêm bởi nút quick-bet mỗi hàng.
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

  /// Được gọi khi màn hình được đẩy lên trên màn hình này pop back.
  /// Rebuilds để số dư ví và bất kỳ cược lặp lại "Play Again" được
  /// hiển thị ngay lập tức, bất kể khi nào `await` gốc giải quyết.
  @override
  void didPopNext() => setState(() {});

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Cược hiện tại cho [racerId], mặc định là 0 nếu chưa đặt cược nào.
  int _stakeFor(int racerId) => _game.bets[racerId] ?? 0;

  /// Số tiền còn lại người chơi vẫn có thể cược (không được âm).
  int get _remaining => _game.money - _game.totalBet;

  // ── bet mutation ──────────────────────────────────────────────────────────

  /// Tăng cược trên [racer] bằng [_step], nhưng không bao giờ để totalBet vượt quá
  /// ví của người chơi — clamping âm thầm ngăn over-betting mà không
  /// crash. SnackBar thông báo người chơi khi đạt trần.
  void _increment(int racerId) {
    final headroom = _headroom();
    if (headroom <= 0) {
      _showOverBetSnackBar();
      return;
    }
    final added = headroom < _step ? headroom : _step;
    setState(() {
      _game.setBet(racerId, _stakeFor(racerId) + added);
    });
  }

  /// Giảm cược trên [racer] bằng [_step], clamping ở 0.
  void _decrement(int racerId) {
    final current = _stakeFor(racerId);
    if (current <= 0) return;
    setState(() {
      _game.setBet(racerId, current - _step);
    });
  }

  /// Thêm [_quickBetAmount] vào cược cho [racerId], clamped theo cùng
  /// quy tắc headroom ví như [_increment] — tổng cược không bao giờ vượt quá tiền.
  void _quickBet(int racerId) {
    final headroom = _headroom();
    if (headroom <= 0) {
      _showOverBetSnackBar();
      return;
    }
    final added = headroom < _quickBetAmount ? headroom : _quickBetAmount;
    setState(() {
      _game.setBet(racerId, _stakeFor(racerId) + added);
    });
  }

  /// Có bao nhiêu tiền vẫn có sẵn để cược.
  /// Được trích xuất để cả [_increment] và [_quickBet] chia sẻ cùng quy tắc chính xác.
  int _headroom() => _game.money - _game.totalBet;

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

  /// Khởi chạy cuộc đua, sau đó refresh state khi điều khiển trả về màn hình này.
  /// `await` có nghĩa là chúng ta chờ luồng Race + Result đầy đủ pop back về đây.
  Future<void> _startRace() async {
    SoundService.playStart(); // tín hiệu bắt đầu cuộc đua (fire-and-forget)
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RaceScreen(game: _game)),
    );
    // RaceScreen gọi settleRace và ResultScreen pop back về chúng ta.
    // Refresh số dư ví và cược đã xóa sau khi giải quyết, sau đó persist.
    if (mounted) setState(() {});
    if (widget.username != null) {
      WalletStorage.saveMoney(widget.username!, _game.money);
    }
  }

  // ── reset wallet ──────────────────────────────────────────────────────────

  /// Reset ví của người chơi về số tiền khởi đầu và xóa mọi cược.
  /// Chỉ hiển thị khi người chơi hết tiền.
  void _resetWallet() {
    setState(() {
      _game.money = GameConfig.startingMoney;
      _game.clearBets();
    });
    if (widget.username != null) {
      WalletStorage.saveMoney(widget.username!, _game.money);
    }
  }

  // ── logout ───────────────────────────────────────────────────────────────

  /// Đăng xuất người dùng hiện tại.
  Future<void> _logout() async {
    await UserStorage.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('🐎 Place Your Bets'),
        actions: widget.username != null
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Đăng xuất',
                  onPressed: _logout,
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: _game.money <= 0
            ? _buildBrokeState(context)
            : _buildBettingUI(context),
      ),
    );
  }

  // ── broke state ───────────────────────────────────────────────────────────

  /// Màn hình thân thiện hiển thị khi ví của người chơi trống.
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
    final totalBet = _game.totalBet;
    final canStart = _game.canStartRace;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Wallet card ────────────────────────────────────────────────
          _WalletCard(money: _game.money),

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
                onPressed: () => setState(() => _game.clearBets()),
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

/// Hiển thị ví nổi bật ở trên cùng của màn hình cược.
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

/// Card tóm tắt trực tiếp hiển thị tổng cược đã đặt và số dư còn lại.
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
