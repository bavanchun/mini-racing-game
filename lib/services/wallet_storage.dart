import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Lưu trữ ví của người chơi qua các lần khởi chạy ứng dụng (tính năng bonus).
///
/// Tất cả các phương thức đều fail soft: nếu storage không khả dụng thì game vẫn hoạt động,
/// chỉ là không nhớ số tiền giữa các phiên làm việc.
/// Ví được lưu theo username để hỗ trợ nhiều người dùng.
class WalletStorage {
  WalletStorage._();

  static const String _moneyPrefix = 'wallet_money_';

  /// Tải ví đã lưu cho người dùng cụ thể, nếu không có thì dùng số tiền khởi đầu.
  static Future<int> loadMoney(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_moneyPrefix$username';
      return prefs.getInt(key) ?? GameConfig.startingMoney;
    } catch (_) {
      return GameConfig.startingMoney;
    }
  }

  /// Lưu ví hiện tại cho người dùng cụ thể. Các lỗi được cố ý bỏ qua.
  static Future<void> saveMoney(String username, int money) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_moneyPrefix$username';
      await prefs.setInt(key, money);
    } catch (_) {
      // ignore: persistence là tính năng best-effort bonus, không bao giờ chặn gameplay.
    }
  }
}
