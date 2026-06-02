import 'package:flutter/material.dart';

import '../models/racer.dart';
import '../theme/app_theme.dart';

/// A single row in the betting UI representing one [racer].
///
/// Displays the horse emoji, the racer's name in its own accent colour, the
/// current [stake], and +/- buttons to increment or decrement the stake.
///
/// The parent is responsible for clamping: [onDecrement] / [onIncrement]
/// callbacks are fired and the parent decides whether the change is valid
/// before calling `setState`. This keeps all validation logic in one place
/// (the screen) rather than duplicating it across rows.
class BetRow extends StatelessWidget {
  final Racer racer;

  /// Current stake amount placed on this racer (already read from GameState).
  final int stake;

  /// Amount by which each button press changes the stake.
  final int step;

  /// Called when the user taps "-". The parent clamps to >= 0.
  final VoidCallback onDecrement;

  /// Called when the user taps "+". The parent prevents over-betting.
  final VoidCallback onIncrement;

  const BetRow({
    super.key,
    required this.racer,
    required this.stake,
    required this.step,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Horse emoji — large enough to be visually prominent.
            Text(
              racer.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),

            // Racer name, coloured with the racer's accent colour.
            Expanded(
              child: Text(
                racer.name,
                style: textTheme.titleMedium?.copyWith(
                  color: racer.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Decrement button — greyed out when stake is already zero.
            _StepButton(
              icon: Icons.remove,
              onTap: stake > 0 ? onDecrement : null,
              color: AppColors.lose,
            ),

            // Current stake display in a fixed-width container so the layout
            // stays stable as numbers grow (e.g., 0 → 100).
            SizedBox(
              width: 52,
              child: Text(
                '\$$stake',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: stake > 0 ? AppColors.gold : Colors.grey,
                ),
              ),
            ),

            // Increment button.
            _StepButton(
              icon: Icons.add,
              onTap: onIncrement,
              color: AppColors.win,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular icon button used for the +/- controls.
///
/// Receives a nullable [onTap] so it can be disabled (greyed) when the action
/// is not allowed (e.g., decrement when stake is already zero).
class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled ? color.withAlpha(30) : Colors.grey.withAlpha(20),
          border: Border.all(
            color: isEnabled ? color : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? color : Colors.grey,
        ),
      ),
    );
  }
}
