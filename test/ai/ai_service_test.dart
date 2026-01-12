import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/ai/ai_service.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('AIService', () {
    late AIService service;

    setUp(() {
      service = AIService();
    });

    test('returns a valid move asynchronously', () async {
      final board = GameBoard(rows: 15, columns: 15);
      board.cells[7][7] = const Cell(position: Position(x: 7, y: 7), owner: Player.x);
      
      final move = await service.getBestMove(board, Player.o, difficulty: AIDifficulty.medium);
      
      expect(move, isNotNull);
      expect(move.x, inInclusiveRange(0, 14));
      expect(move.y, inInclusiveRange(0, 14));
    });
  });
}
