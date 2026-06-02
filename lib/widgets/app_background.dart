import 'package:flutter/material.dart';

/// A soft "race day" vertical gradient (sky → turf → cream) used behind every
/// screen for a consistent, polished backdrop.
///
/// Wrap a screen's body with this and keep the [Scaffold.backgroundColor]
/// transparent so the gradient shows through.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7EC8E3), // sky
            Color(0xFFBFE3A0), // light turf
            Color(0xFFEFE7D3), // cream
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Convenience: a [Scaffold] backed by [AppBackground] with a transparent
/// surface so the gradient is visible. Keeps screen code tidy.
class GradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const GradientScaffold({super.key, this.appBar, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: AppBackground(child: body),
    );
  }
}
