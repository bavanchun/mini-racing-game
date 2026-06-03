import 'package:flutter/material.dart';

/// Một đối thủ duy nhất trong cuộc đua (một trong ba con ngựa).
///
/// Mô tả bất biến về *ai* đang đua. Vị trí đua thực tế được theo dõi
/// riêng trong màn hình Race để cùng một danh sách có thể được tái sử dụng mỗi vòng.
class Racer {
  /// Id ổn định (0, 1, 2) được dùng làm key cho cược và kết quả.
  final int id;

  /// Tên hiển thị được hiện trên màn hình cược và kết quả.
  final String name;

  /// Glyph emoji dùng để vẽ con ngựa trên đường đua của nó (Material Icons không có
  /// ngựa, nên glyph cho chúng ta một con ngựa thực sự, sắc nét trên mọi nền tảng).
  final String emoji;

  /// Màu nhấn cho đường đua và hàng cược của tay đua này.
  final Color color;

  const Racer({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });
}
