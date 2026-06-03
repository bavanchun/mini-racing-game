import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/user.dart';
import 'screens/home_betting_screen.dart';
import 'screens/login_screen.dart';
import 'services/user_storage.dart';
import 'services/wallet_storage.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'utils/route_observer.dart';

Future<void> main() async {
  // Required before touching SharedPreferences before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the system nav bar so the gradient fills the whole screen
  // (removes the black band at the bottom of Home).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final currentUser = await UserStorage.getCurrentUser();
  int initialMoney = GameConfig.startingMoney;
  if (currentUser != null) {
    initialMoney = await WalletStorage.loadMoney(currentUser.username);
  }
  runApp(MiniRacingGameApp(currentUser: currentUser, initialMoney: initialMoney));
}

/// Root của game đua ngựa đặt cược mini.
///
/// Kiểm tra xem người dùng đã đăng nhập chưa. Nếu có, hiển thị màn hình Home
/// với ví của họ. Nếu chưa, hiển thị màn hình đăng nhập.
class MiniRacingGameApp extends StatelessWidget {
  final User? currentUser;
  final int initialMoney;

  const MiniRacingGameApp({
    super.key, 
    required this.currentUser,
    required this.initialMoney,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Racing Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorObservers: [appRouteObserver],
      initialRoute: '/',
      routes: {
        '/': (context) => currentUser != null
            ? HomeBettingScreen(
                initialMoney: initialMoney,
                username: currentUser?.username,
              )
            : const LoginScreen(),
      },
    );
  }
}
