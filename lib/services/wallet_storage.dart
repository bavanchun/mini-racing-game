import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Persists the player's wallet across app launches (bonus feature).
///
/// All methods fail soft: if storage is unavailable the game still works,
/// it just won't remember money between sessions.
class WalletStorage {
  WalletStorage._();

  static const String _moneyKey = 'wallet_money';

  /// Load the saved wallet, falling back to the starting amount.
  static Future<int> loadMoney() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_moneyKey) ?? GameConfig.startingMoney;
    } catch (_) {
      return GameConfig.startingMoney;
    }
  }

  /// Save the current wallet. Errors are swallowed on purpose.
  static Future<void> saveMoney(int money) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_moneyKey, money);
    } catch (_) {
      // ignore: persistence is a best-effort bonus, never block gameplay.
    }
  }
}
