import 'package:flutter/material.dart';

import '../models/racer.dart';

/// Central game-tuning values and the fixed roster of racers.
///
/// Keeping these in one place makes the betting rules easy to verify and
/// lets every screen share the exact same roster.
class GameConfig {
  GameConfig._();

  /// Wallet the player starts with (and the floor we reset to if they go broke).
  static const int startingMoney = 100;

  /// Multiplier applied to the stake placed on the winning racer.
  /// A winning bet of `s` returns `s * winMultiplier` to the wallet.
  static const int winMultiplier = 3;

  /// The three horses. Ids are 0..2 and are used as bet/result keys.
  static const List<Racer> racers = [
    Racer(id: 0, name: 'Thunder', emoji: '🐎', color: Color(0xFFE53935)), // red
    Racer(id: 1, name: 'Blaze', emoji: '🐎', color: Color(0xFF1E88E5)), // blue
    Racer(id: 2, name: 'Shadow', emoji: '🐎', color: Color(0xFF43A047)), // green
  ];
}

/// Tuning for the fake-slider race animation (see Race screen).
class RaceConfig {
  RaceConfig._();

  /// How often each racer advances. Lower = smoother but busier.
  /// Shorter tick + smaller steps = a longer, smoothly gliding race.
  static const Duration tick = Duration(milliseconds: 80);

  /// Minimum / maximum fraction of the track a racer can gain per tick.
  /// The random pick inside this range is what makes speeds differ.
  /// Avg ≈0.012 → ~83 ticks × 80ms ≈ 6.6s race.
  static const double minStep = 0.006;
  static const double maxStep = 0.018;

  /// Pause after a winner is highlighted before navigating to the results, so
  /// the photo-finish moment registers.
  static const Duration photoFinishDelay = Duration(milliseconds: 1100);

  /// Countdown pause before the race begins (was a magic number in the screen).
  static const Duration countdown = Duration(milliseconds: 600);
}
