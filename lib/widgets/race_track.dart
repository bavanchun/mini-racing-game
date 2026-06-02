import 'package:flutter/material.dart';

import '../models/racer.dart';
import '../theme/app_theme.dart';

/// Renders a single racer's lane: a dirt track with a finish-line marker on
/// the right and an emoji horse that glides left → right as [progress] rises
/// from 0.0 (start) to 1.0 (finish line).
///
/// Movement uses [AnimatedPositioned] inside a [Stack] — there is intentionally
/// no Slider widget here; the "fake slider" pattern is a lab requirement.
///
/// [progress] must be in [0.0, 1.0]. The parent drives updates via setState.
class RaceTrack extends StatelessWidget {
  final Racer racer;

  /// Current position: 0.0 = start gate, 1.0 = finish line.
  final double progress;

  /// Whether this racer won (triggers a visual highlight).
  final bool isWinner;

  /// Tick duration — AnimatedPositioned uses this so the horse glides
  /// smoothly between timer ticks rather than jumping.
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
          // Racer label row above the track
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
          // The actual lane with moving horse
          LayoutBuilder(
            builder: (context, constraints) {
              final laneWidth = constraints.maxWidth;
              // Usable travel distance: from left padding to the finish line
              // left edge. Reserve _sidePadding on the left and _finishWidth on
              // the right so progress=1.0 lands the horse directly on the flag.
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
                    // Dirt texture: subtle horizontal stripes
                    Positioned.fill(
                      child: CustomPaint(painter: _DirtStripePainter()),
                    ),

                    // Finish-line checkered column on the far right
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: _finishWidth,
                      child: CustomPaint(painter: _CheckeredPainter()),
                    ),

                    // Flag icon on top of finish line
                    Positioned(
                      right: 4,
                      top: 4,
                      child: const Text('🏁', style: TextStyle(fontSize: 16)),
                    ),

                    // Progress fill (colored band behind horse to show distance)
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

                    // The horse emoji — this IS the "fake slider thumb"
                    AnimatedPositioned(
                      duration: animationDuration,
                      curve: Curves.linear,
                      left: horseLeft,
                      top: (_laneHeight - _horseSize) / 2,
                      width: _horseSize,
                      height: _horseSize,
                      // Semantic label lets screen readers identify which racer
                      // this glyph represents as it moves across the track.
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

/// Paints subtle horizontal stripes to give the dirt track a textured feel.
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

/// Paints the classic black-and-white checkered finish column.
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
