import 'package:flutter/widgets.dart';

/// App-wide route observer so a screen can refresh when a route pushed on top
/// of it pops back. Home subscribes and rebuilds in `didPopNext()` — this is
/// what reliably redraws the wallet and any "Play Again" repeated bets when the
/// Result screen pops back, since Home's `await Navigator.push` completes early
/// (when Race is *replaced* by Result, before the repeat runs).
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();
