import 'package:flutter/material.dart';

import '../models/racer.dart';
import '../theme/app_theme.dart';

/// Render một làn tay đua đơn: đường đua đất với marker vạch đích ở
/// bên phải và emoji ngựa trôi trái → phải khi [progress] tăng
/// từ 0.0 (khởi đầu) đến 1.0 (vạch đích).
///
/// Di chuyển sử dụng [AnimatedPositioned] bên trong [Stack] — cố ý
/// không có widget Slider ở đây; pattern "fake slider" là yêu cầu lab.
///
/// [progress] phải trong [0.0, 1.0]. Parent điều khiển cập nhật qua setState.
class RaceTrack extends StatelessWidget {
  final Racer racer;

  /// Vị trí hiện tại: 0.0 = cổng khởi đầu, 1.0 = vạch đích.
  final double progress;

  /// Liệu tay đua này có thắng hay không (kích hoạt highlight thị giác).
  final bool isWinner;

  /// Thời lượng tick — AnimatedPositioned sử dụng cái này để ngựa trôi
  /// mượt mà giữa các tick timer thay vì nhảy.
  final Duration animationDuration;

  static const double _laneHeight = 72.0;
  static const double _horseSize = 38.0;
  static const double _finishWidth = 28.0;
  static const double _sidePadding = 8.0;

  const RaceTrack({
    super.key,
    required this.racer,
    required this.progress,
    this.isWinner = false,
    required this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng nhãn tay đua phía trên đường đua
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: racer.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  racer.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? AppColors.gold : Colors.black87,
                  ),
                ),
                if (isWinner) ...[
                  const SizedBox(width: 6),
                  const Text(
                    '🏆 WINNER!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Làn thực tế với ngựa di chuyển
          LayoutBuilder(
            builder: (context, constraints) {
              final laneWidth = constraints.maxWidth;
              // Khoảng cách di chuyển có thể dùng: từ padding trái đến cạnh trái
              // vạch đích. Dành _sidePadding ở bên trái và _finishWidth ở
              // bên phải để progress=1.0 đặt ngựa trực tiếp lên cờ.
              final travelWidth =
                  laneWidth - _sidePadding - _finishWidth - _horseSize;
              final horseLeft = _sidePadding + (progress.clamp(0.0, 1.0) * travelWidth);

              return Container(
                height: _laneHeight,
                decoration: BoxDecoration(
                  color: AppColors.trackLane,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isWinner ? AppColors.gold : racer.color,
                    width: isWinner ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Kết cấu đất: sọc ngang tinh tế
                    Positioned.fill(
                      child: CustomPaint(painter: _DirtStripePainter()),
                    ),

                    // Cột ô vuông vạch đích ở bên phải xa
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: _finishWidth,
                      child: CustomPaint(painter: _CheckeredPainter()),
                    ),

                    // Icon cờ trên cùng vạch đích
                    Positioned(
                      right: 4,
                      top: 4,
                      child: const Text('🏁', style: TextStyle(fontSize: 16)),
                    ),

                    // Điền tiến độ (dải màu phía sau ngựa để hiển thị khoảng cách)
                    AnimatedPositioned(
                      duration: animationDuration,
                      curve: Curves.linear,
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: horseLeft + _horseSize / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: racer.color.withValues(alpha: 0.18),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // Emoji ngựa — đây LÀ "fake slider thumb"
                    AnimatedPositioned(
                      duration: animationDuration,
                      curve: Curves.linear,
                      left: horseLeft,
                      top: (_laneHeight - _horseSize) / 2,
                      width: _horseSize,
                      height: _horseSize,
                      // Nhãn ngữ nghĩa cho phép screen readers xác định tay đua nào
                      // glyph này đại diện khi nó di chuyển qua đường đua.
                      child: Semantics(
                        label: racer.name,
                        child: Center(
                          child: Text(
                            racer.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Vẽ sọc ngang tinh tế để tạo cảm giác kết cấu cho đường đua đất.
class _DirtStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DirtStripePainter old) => false;
}

/// Vẽ cột vạch đích ô vuông đen trắng cổ điển.
class _CheckeredPainter extends CustomPainter {
  static const double _cellSize = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final blackPaint = Paint()..color = Colors.black87;
    final whitePaint = Paint()..color = Colors.white;

    int row = 0;
    for (double y = 0; y < size.height; y += _cellSize, row++) {
      int col = 0;
      for (double x = 0; x < size.width; x += _cellSize, col++) {
        final isBlack = (row + col) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, _cellSize, _cellSize),
          isBlack ? blackPaint : whitePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckeredPainter old) => false;
}
