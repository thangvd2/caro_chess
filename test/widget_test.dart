import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/main.dart';
import 'package:caro_chess/ui/game_board_widget.dart';
import 'package:caro_chess/ui/game_controls_widget.dart';

void main() {
  testWidgets('App renders GameBoard and Controls', (WidgetTester tester) async {
    await tester.pumpWidget(const CaroChessApp());
    await tester.pumpAndSettle();

    expect(find.byType(GameBoardWidget), findsOneWidget);
    expect(find.byType(GameControlsWidget), findsOneWidget);
    expect(find.text('Current Turn: X'), findsOneWidget);
  });
}
