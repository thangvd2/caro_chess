import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/engine/game_engine.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('Cross-Language Engine Validation', () {
    // Load test vectors synchronously
    final file = File('test_vectors/engine_scenarios.json');
    final jsonString = file.readAsStringSync();
    final testVectors = jsonDecode(jsonString) as Map<String, dynamic>;

    for (final scenario in testVectors['scenarios'] as List) {
      test(scenario['name'], () {
        final rule = _parseRule(scenario['rule']);
        final engine = GameEngine(rule: rule);

        // Apply all moves
        for (final move in scenario['moves'] as List) {
          final player = move['player'] == 'X' ? Player.x : Player.o;

          final pos = Position(x: move['x'], y: move['y']);
          final success = engine.placePiece(pos);

          // If move failed, player turn doesn't change
          // If move succeeded, turn alternates
          if (!success && engine.currentPlayer != player) {
            // Move was rejected by the engine (valid)
            continue;
          }
        }

        // Validate final state
        final expected = scenario['expected'];
        final expectedWinner = expected['winner'];
        final expectedGameOver = expected['isGameOver'];

        expect(engine.isGameOver, equals(expectedGameOver),
            reason: 'Game over state mismatch');

        if (expectedWinner == null) {
          expect(engine.winner, isNull, reason: 'Expected no winner');
        } else {
          expect(engine.winner, isNotNull, reason: 'Expected a winner');
          final winnerStr = engine.winner == Player.x ? 'X' : 'O';
          expect(winnerStr, equals(expectedWinner), reason: 'Winner mismatch');
        }

        // Validate winning line if provided - check if all expected positions are in the winning line
        if (expected['winningLine'] != null) {
          expect(engine.winningLine, isNotNull, reason: 'Expected a winning line');
          expect(engine.winningLine!.length, equals(expected['winningLine'].length),
              reason: 'Winning line length mismatch');

          // Create a set of expected positions for comparison
          final expectedPositions = <String>{};
          for (final pos in expected['winningLine'] as List) {
            expectedPositions.add('${pos['x']},${pos['y']}');
          }

          // Check that all winning line positions are in the expected set
          for (final actualPos in engine.winningLine!) {
            final posKey = '${actualPos.x},${actualPos.y}';
            expect(expectedPositions.contains(posKey), isTrue,
                reason: 'Winning line contains unexpected position ($posKey)');
          }
        }
      });
    }
  });
}

GameRule _parseRule(String rule) {
  switch (rule.toLowerCase()) {
    case 'standard':
      return GameRule.standard;
    case 'freestyle':
      return GameRule.freeStyle;
    case 'caro':
      return GameRule.caro;
    default:
      throw ArgumentError('Unknown rule: $rule');
  }
}
