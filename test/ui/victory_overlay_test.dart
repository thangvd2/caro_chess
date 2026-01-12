import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:confetti/confetti.dart';
import 'package:caro_chess/ui/victory_overlay.dart';

void main() {
  testWidgets('VictoryOverlay renders ConfettiWidget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VictoryOverlay(isVisible: true),
        ),
      ),
    );

    expect(find.byType(ConfettiWidget), findsOneWidget);
  });
}
