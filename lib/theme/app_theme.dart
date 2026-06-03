import 'package:flutter/material.dart';

/// Màu sắc chia sẻ và [ThemeData] toàn app cho game đua.
///
/// Bảng màu ấm "ngày đua": cỏ xanh, đường kem, và nhấn vàng.
class AppColors {
  AppColors._();

  static const Color turf = Color(0xFF2E7D32); // grass green
  static const Color turfDark = Color(0xFF1B5E20);
  static const Color rail = Color(0xFFF5EBD6); // cream
  static const Color gold = Color(0xFFFFB300); // money / highlight
  static const Color sky = Color(0xFF0D47A1);
  static const Color trackLane = Color(0xFF8D6E63); // dirt brown
  static const Color win = Color(0xFF2E7D32);
  static const Color lose = Color(0xFFC62828);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.turf,
        primary: AppColors.turf,
        secondary: AppColors.gold,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFEFE7D3),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.turfDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.turf,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.rail,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
