// Smoke test: the app boots into the betting screen and shows the wallet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_racing_game/main.dart';
import 'package:mini_racing_game/utils/constants.dart';

void main() {
  testWidgets('app launches on the betting screen with the starting wallet',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MiniRacingGameApp());

    // Starting wallet is shown.
    expect(find.textContaining('${GameConfig.startingMoney}'), findsWidgets);

    // All three racers appear on the betting screen.
    for (final racer in GameConfig.racers) {
      expect(find.text(racer.name), findsWidgets);
    }

    // Start button exists but is disabled until a bet is placed.
    expect(find.widgetWithText(ElevatedButton, 'Start Race'), findsOneWidget);
  });
}
