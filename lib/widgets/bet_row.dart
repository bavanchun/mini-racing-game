import 'package:flutter/material.dart';

import '../models/racer.dart';
import '../theme/app_theme.dart';

/// Một hàng đơn trong UI cược đại diện cho một [racer].
///
/// Hiển thị emoji ngựa, tên của tay đua trong màu nhấn của nó,
/// [stake] hiện tại, và các nút -/+/+50 để điều chỉnh cược.
///
/// Parent chịu trách nhiệm clamping: callbacks [onDecrement] / [onIncrement] /
/// [onQuickBet] được kích hoạt và parent quyết định liệu thay đổi
/// có hợp lệ trước khi gọi `setState`. Điều này giữ tất cả logic xác thực ở một
/// nơi (màn hình) thay vì nhân bản qua các hàng.
class BetRow extends StatelessWidget {
  final Racer racer;

  /// Số tiền cược hiện tại được đặt trên tay đua này (đã đọc từ GameState).
  final int stake;

  /// Số tiền mỗi lần nhấn nút +/- thay đổi cược.
  final int step;

  /// Được gọi khi người chơi nhấn "-". Parent clamp đến >= 0.
  final VoidCallback onDecrement;

  /// Được gọi khi người chơi nhấn "+". Parent ngăn over-betting.
  final VoidCallback onIncrement;

  /// Được gọi khi người chơi nhấn "+50". Parent clamp đến headroom ví.
  final VoidCallback onQuickBet;

  const BetRow({
    super.key,
    required this.racer,
    required this.stake,
    required this.step,
    required this.onDecrement,
    required this.onIncrement,
    required this.onQuickBet,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Emoji ngựa — đủ lớn để nổi bật về mặt thị giác.
            Text(
              racer.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),

            // Tên tay đua, được màu với màu nhấn của tay đua.
            Expanded(
              child: Text(
                racer.name,
                style: textTheme.titleMedium?.copyWith(
                  color: racer.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Nút giảm — xám đi khi cược đã bằng 0.
            // Được bọc trong Semantics để screen readers thông báo tên ngựa
            // thay vì chỉ "remove button".
            Semantics(
              button: true,
              label: 'Remove bet on ${racer.name}',
              excludeSemantics: true,
              child: _StepButton(
                icon: Icons.remove,
                onTap: stake > 0 ? onDecrement : null,
                color: AppColors.lose,
              ),
            ),

            // Hiển thị cược hiện tại trong container chiều rộng cố định để layout
            // giữ ổn định khi số tăng (ví dụ, 0 → 100).
            // excludeSemantics ngăn "$X" thô được đọc mà không có
            // ngữ cảnh; wrapper Semantics đặt tên cho ngựa + số tiền.
            Semantics(
              label: '${racer.name} stake \$$stake dollars',
              excludeSemantics: true,
              child: SizedBox(
                width: 52,
                child: Text(
                  '\$$stake',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: stake > 0 ? AppColors.gold : Colors.grey,
                  ),
                ),
              ),
            ),

            // Nút tăng.
            Semantics(
              button: true,
              label: 'Add bet on ${racer.name}',
              excludeSemantics: true,
              child: _StepButton(
                icon: Icons.add,
                onTap: onIncrement,
                color: AppColors.win,
              ),
            ),

            const SizedBox(width: 6),

            // Nút quick-bet +50 — style chip văn bản nhỏ hơn để phân biệt
            // thị giác từ các nút bước, cùng họ màu xanh lá.
            Semantics(
              button: true,
              label: 'Add 50 dollars to bet on ${racer.name}',
              excludeSemantics: true,
              child: _QuickBetButton(
                onTap: onQuickBet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút icon hình tròn nhỏ dùng cho các điều khiển +/-.
///
/// Vùng chạm tappable được đệm đến ≥48×48 dp (mục tiêu chạm tối thiểu của Material)
/// trong khi hình tròn hiển thị giữ ở 36 px. Điều này cải thiện tính sử dụng
/// mà không thay đổi thiết kế thị giác.
///
/// Nhận [onTap] nullable để nó có thể bị vô hiệu hóa (xám) khi hành động
/// không được phép (ví dụ, giảm khi cược đã bằng 0).
class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    // SizedBox(48,48) đảm bảo InkWell điền đầy mục tiêu chạm 48×48
    // trong khi Container bên trong giữ ở 36×36 cho hình tròn thị giác.
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? color.withAlpha(30) : Colors.grey.withAlpha(20),
              border: Border.all(
                color: isEnabled ? color : Colors.grey,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isEnabled ? color : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip quick-bet "+50" nhỏ gọn được thêm sau nút tăng.
///
/// Sử dụng OutlinedButton với font nhỏ để nó giữ nhẹ hơn về mặt thị giác
/// so với các hình tròn +/- chính nhưng vẫn rõ ràng có thể chạm.
class _QuickBetButton extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickBetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(48, 36),
          side: BorderSide(color: AppColors.win, width: 1.5),
          foregroundColor: AppColors.win,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('+50'),
      ),
    );
  }
}
