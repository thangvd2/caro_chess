import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/services/history_service.dart';
import 'package:caro_chess/models/history_models.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('HistoryService', () {
    late HistoryService service;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      registerFallbackValue(Uri());
      service = HistoryService(client: mockClient);
    });

    test('getUserMatches returns list on success', () async {
      final jsonResponse = '''
      [
        {
          "id": "m1",
          "player_x_id": "u1",
          "player_o_id": "u2",
          "winner_id": "u1",
          "timestamp": "2024-01-01T12:00:00Z"
        }
      ]
      ''';

      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response(jsonResponse, 200));

      final matches = await service.getUserMatches('u1');
      expect(matches.length, 1);
      expect(matches.first.id, 'm1');
      expect(matches.first.moves, isNull);
    });

    test('getMatch returns full details on success', () async {
      final jsonResponse = '''
      {
        "id": "m1",
        "player_x_id": "u1",
        "player_o_id": "u2",
        "winner_id": "u1",
        "timestamp": "2024-01-01T12:00:00Z",
        "moves": [
            {"x": 1, "y": 1, "player": "X", "order": 0}
        ]
      }
      ''';

      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response(jsonResponse, 200));

      final match = await service.getMatch('m1');
      expect(match, isNotNull);
      expect(match!.id, 'm1');
      expect(match.moves, isNotNull);
      expect(match.moves!.length, 1);
      expect(match.moves!.first.x, 1);
    });
  });
}
