import 'package:flutter/material.dart';

import 'models/game_state.dart';
import 'screens/home_betting_screen.dart';
import 'services/wallet_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Required before touching SharedPreferences before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final savedMoney = await WalletStorage.loadMoney();
  runApp(MiniRacingGameApp(initialMoney: savedMoney));
}

/// Root of the mini horse-racing betting game.
///
/// A single [GameState] is created here and handed to the Home screen, which
/// passes the same instance down to the Race and Result screens. Holding it at
/// the root keeps the wallet alive across the Home → Race → Result → Home loop.
class MiniRacingGameApp extends StatefulWidget {
  /// Wallet restored from storage (defaults to the starting amount).
  final int initialMoney;

  const MiniRacingGameApp({super.key, required this.initialMoney});

  @override
  State<MiniRacingGameApp> createState() => _MiniRacingGameAppState();
}

class _MiniRacingGameAppState extends State<MiniRacingGameApp> {
  late final GameState _game = GameState(money: widget.initialMoney);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Racing Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeBettingScreen(game: _game),
    );
  }
}
