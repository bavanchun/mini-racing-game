import 'package:flutter/material.dart';

/// A single competitor in the race (one of the three horses).
///
/// Immutable description of *who* races. The live race position is tracked
/// separately in the Race screen so the same roster can be reused every round.
class Racer {
  /// Stable id (0, 1, 2) used as the key for bets and results.
  final int id;

  /// Display name shown on the betting and result screens.
  final String name;

  /// Emoji glyph used to draw the horse on its track (Material Icons has no
  /// horse, so a glyph gives us a real, crisp horse on every platform).
  final String emoji;

  /// Accent colour for this racer's track and bet row.
  final Color color;

  const Racer({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });
}
