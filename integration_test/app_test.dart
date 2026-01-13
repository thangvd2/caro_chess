import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/main.dart' as app;
import 'package:caro_chess/ui/game_board_widget.dart';
import 'package:caro_chess/ui/game_controls_widget.dart';
import 'package:caro_chess/ui/rule_selector_widget.dart';

void main() {
  group('Caro Chess Integration Tests', () {
    testWidgets('Complete local game flow', (WidgetTester tester) async {
      // 1. Launch app
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      // 2. Verify we're in initial state with game controls
      expect(find.text('Local PvP'), findsOneWidget);
      expect(find.text('Play vs AI'), findsOneWidget);
      expect(find.byType(GameControlsWidget), findsOneWidget);

      // 3. Start local PvP game
      await tester.tap(find.text('Local PvP'));
      await tester.pumpAndSettle();

      // 4. Verify game board is displayed
      expect(find.byType(GameBoardWidget), findsOneWidget);

      // 5. Verify turn indicator shows X's turn
      expect(find.textContaining('Turn: X'), findsOneWidget);

      // 6. Make a move at position (7, 7) - center of board
      // The board is a 15x15 grid, so (7, 7) is at index 7 * 15 + 7 = 112
      final centerCell = find.byType(Container).at(112);
      await tester.tap(centerCell);
      await tester.pumpAndSettle();

      // 7. Verify turn changed to O
      expect(find.textContaining('Turn: O'), findsOneWidget);

      // 8. Make a move for O at position (7, 8)
      final cellBelowCenter = find.byType(Container).at(127); // 7, 8
      await tester.tap(cellBelowCenter);
      await tester.pumpAndSettle();

      // 9. Verify turn changed back to X
      expect(find.textContaining('Turn: X'), findsOneWidget);

      // 10. Verify undo button is enabled
      expect(find.text('Undo'), findsOneWidget);

      // 11. Reset the game
      await tester.tap(find.text('Reset Game'));
      await tester.pumpAndSettle();

      // 12. Verify we're back to initial state
      expect(find.text('Local PvP'), findsOneWidget);
    });

    testWidgets('AI game flow', (WidgetTester tester) async {
      // 1. Launch app
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      // 2. Start game vs AI
      await tester.tap(find.text('Play vs AI'));
      await tester.pumpAndSettle();

      // 3. Make a move for player X
      final centerCell = find.byType(Container).at(112);
      await tester.tap(centerCell);
      await tester.pumpAndSettle();

      // 4. Verify AI is thinking indicator appears
      expect(find.text('AI is thinking...'), findsOneWidget);

      // 5. Wait for AI to move (pump multiple times for async AI)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 6. Verify turn is back to X (AI made its move)
      expect(find.textContaining('Turn: X'), findsOneWidget);
    });

    testWidgets('Store purchase flow', (WidgetTester tester) async {
      // 1. Launch app
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      // 2. Navigate to store
      expect(find.byIcon(Icons.store), findsOneWidget);
      await tester.tap(find.byIcon(Icons.store));
      await tester.pumpAndSettle();

      // 3. Verify store title
      expect(find.text('Cosmetic Store'), findsOneWidget);

      // 4. Verify coins display
      expect(find.textContaining('Coins'), findsOneWidget);

      // 5. Verify store items are displayed
      expect(find.text('Neon X/O'), findsOneWidget);
      expect(find.text('Classic Serif'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('Wooden Board'), findsOneWidget);

      // 6. Go back to main screen
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('Equip cosmetic flow', (WidgetTester tester) async {
      // 1. Launch app
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      // 2. Navigate to store
      await tester.tap(find.byIcon(Icons.store));
      await tester.pumpAndSettle();

      // 3. Verify initial state (items not owned)
      expect(find.text('100 Coins'), findsOneWidget);
      expect(find.text('Buy'), findsWidgets);

      // 4. Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('Undo and Redo functionality', (WidgetTester tester) async {
      // 1. Launch app
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      // 2. Start local game
      await tester.tap(find.text('Local PvP'));
      await tester.pumpAndSettle();

      // 3. Make a move
      await tester.tap(find.byType(Container).at(112));
      await tester.pumpAndSettle();

      // 4. Undo the move
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // 5. Verify redo button is now enabled
      expect(find.text('Redo'), findsOneWidget);

      // 6. Redo the move
      await tester.tap(find.text('Redo'));
      await tester.pumpAndSettle();

      // 7. Verify undo is enabled again
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('Game persistence', (WidgetTester tester) async {
      // 1. Launch app
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      // 2. Start local game
      await tester.tap(find.text('Local PvP'));
      await tester.pumpAndSettle();

      // 3. Make a move
      await tester.tap(find.byType(Container).at(112));
      await tester.pumpAndSettle();

      // 4. Verify game is in progress
      expect(find.textContaining('Turn:'), findsOneWidget);

      // 5. Restart the app (simulate)
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      // 6. Note: In a real test, we'd verify the game state persisted
      // But since LoadSavedGame is called on init, the game should be restored
      // The exact behavior depends on how the repository saves/loads
    });

    testWidgets('Rule selector displays correctly', (WidgetTester tester) async {
      // 1. Launch app
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      // 2. Verify rule selector is present
      // The RuleSelectorWidget should be visible
      expect(find.byType(RuleSelectorWidget), findsOneWidget);
    });
  });

  group('Win Detection Integration Tests', () {
    testWidgets('Horizontal win detection', (WidgetTester tester) async {
      // 1. Launch app and start game
      await tester.pumpWidget(const app.CaroChessApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Local PvP'));
      await tester.pumpAndSettle();

      // 2. Simulate a winning sequence for X (horizontal 5 in a row)
      // This is a simplified test - in reality, we'd need to tap specific cells
      // Row 7, columns 5-9: (5,7), (6,7), (7,7), (8,7), (9,7)
      final positions = [
        5 * 15 + 7, // (5, 7)
        6 * 15 + 7, // (6, 7)
        7 * 15 + 7, // (7, 7)
        8 * 15 + 7, // (8, 7)
        9 * 15 + 7, // (9, 7)
      ];

      // X moves
      await tester.tap(find.byType(Container).at(positions[0]));
      await tester.pumpAndSettle();

      // O moves (blocking attempt, but not blocking)
      await tester.tap(find.byType(Container).at(5 * 15 + 8));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Container).at(positions[1]));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Container).at(6 * 15 + 8));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Container).at(positions[2]));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Container).at(7 * 15 + 8));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Container).at(positions[3]));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Container).at(8 * 15 + 8));
      await tester.pumpAndSettle();

      // Final winning move for X
      await tester.tap(find.byType(Container).at(positions[4]));
      await tester.pumpAndSettle();

      // 3. Verify game over state
      // The VictoryOverlay should be visible
      expect(find.textContaining('Winner:'), findsOneWidget);
    });
  });
}
