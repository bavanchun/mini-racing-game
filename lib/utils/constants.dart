import 'package:flutter/material.dart';

import '../models/racer.dart';

/// Các giá trị tinh chỉnh game trung tâm và danh sách tay đua cố định.
///
/// Giữ những thứ này ở một nơi làm cho quy tắc cược dễ kiểm chứng và
/// cho phép mọi màn hình chia sẻ cùng một danh sách chính xác.
class GameConfig {
  GameConfig._();

  /// Ví mà người chơi bắt đầu với (và mức sàn chúng ta reset về nếu họ vỡ nợ).
  static const int startingMoney = 100;

  /// Hệ số áp dụng cho cược đặt trên tay đua thắng.
  /// Một cược thắng của `s` trả lại `s * winMultiplier` vào ví.
  static const int winMultiplier = 3;

  /// Ba con ngựa. Ids là 0..2 và được dùng làm key cược/kết quả.
  static const List<Racer> racers = [
    Racer(id: 0, name: 'Thunder', emoji: '🐎', color: Color(0xFFE53935)), // red
    Racer(id: 1, name: 'Blaze', emoji: '🐎', color: Color(0xFF1E88E5)), // blue
    Racer(id: 2, name: 'Shadow', emoji: '🐎', color: Color(0xFF43A047)), // green
  ];
}

/// Tinh chỉnh cho animation đua giả slider (xem màn hình Race).
class RaceConfig {
  RaceConfig._();

  /// Tần suất mỗi tay đua tiến lên. Thấp hơn = mượt mà hơn nhưng bận rộn hơn.
  /// Tick ngắn hơn + bước nhỏ hơn = cuộc đua dài hơn, trôi mượt mà.
  static const Duration tick = Duration(milliseconds: 80);

  /// Phân số tối thiểu / tối đa của đường đua mà tay đua có thể đạt được mỗi tick.
  /// Lựa chọn ngẫu nhiên trong phạm vi này là điều làm cho tốc độ khác nhau.
  /// Trung bình ≈0.012 → ~83 ticks × 80ms ≈ 6.6s cuộc đua.
  static const double minStep = 0.006;
  static const double maxStep = 0.018;

  /// Tạm dừng sau khi người thắng được highlight trước khi điều hướng đến kết quả, để
  /// khoảnh khắc photo-finish được ghi nhận.
  static const Duration photoFinishDelay = Duration(milliseconds: 1100);

  /// Tạm dừng đếm ngược trước khi cuộc đua bắt đầu (trước đây là số magic trong màn hình).
  static const Duration countdown = Duration(milliseconds: 600);
}
