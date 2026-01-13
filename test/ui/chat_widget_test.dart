import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/ui/chat_panel.dart';

void main() {
  testWidgets('ChatPanel can be instantiated', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatPanel(messages: []),
        ),
      ),
    );

    expect(find.byType(ChatPanel), findsOneWidget);
  });
}
