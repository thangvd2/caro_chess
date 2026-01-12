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
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(GameBoardWidget), findsOneWidget);
    expect(find.byType(GameControlsWidget), findsOneWidget);
    expect(find.textContaining('Turn: X'), findsOneWidget);
  });
}
