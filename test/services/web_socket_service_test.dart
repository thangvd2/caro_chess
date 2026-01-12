import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/services/web_socket_service.dart';

void main() {
  group('WebSocketService', () {
    test('can be instantiated', () {
      final service = WebSocketService();
      expect(service, isNotNull);
    });
  });
}
