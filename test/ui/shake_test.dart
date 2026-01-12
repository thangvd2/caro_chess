import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/ui/shake_widget.dart';

void main() {
  testWidgets('ShakeWidget renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShakeWidget(
          shouldShake: false,
          child: Text('Hello'),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
  });
}
