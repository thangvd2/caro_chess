import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/ui/game_board_widget.dart';

void main() {
  testWidgets('BoardCell renders without error', (tester) async {
    const cell = Cell(position: Position(x: 0, y: 0), owner: Player.x);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardCell(cell: cell, onTap: () {}),
        ),
      ),
    );

    expect(find.text('X'), findsOneWidget);
  });
}
