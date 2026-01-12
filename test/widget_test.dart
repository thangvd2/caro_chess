import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caro_chess/main.dart';
import 'package:caro_chess/ui/game_board_widget.dart';
import 'package:caro_chess/ui/game_controls_widget.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders GameBoard and Controls', (WidgetTester tester) async {
    await tester.pumpWidget(const CaroChessApp());
    // Give it time for async shared_prefs call and Bloc state change
    await tester.pump(); // Start LoadSavedGame
    await tester.pump(); // Process LoadSavedGame
    await tester.pumpAndSettle();

    expect(find.byType(GameBoardWidget), findsOneWidget);
    expect(find.byType(GameControlsWidget), findsOneWidget);
    expect(find.textContaining('Current Turn: X'), findsOneWidget);
  });
}