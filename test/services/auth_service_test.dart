import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caro_chess/services/auth_service.dart';
import 'package:caro_chess/config/app_config.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('AuthService', () {
    late AuthService service;
    late MockHttpClient mockClient;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockClient = MockHttpClient();
      registerFallbackValue(Uri());
      service = AuthService(client: mockClient);
    });

    test('login returns token on success', () async {
      when(() => mockClient.post(
            any(), 
            body: any(named: 'body'), 
            headers: any(named: 'headers')
          ))
          .thenAnswer((_) async => http.Response('{"token": "abc", "id": "u1"}', 200));

      final token = await service.login('user1');
      expect(token, 'abc');
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AuthService.keyAuthToken), 'abc');
    });

    test('signup returns token on success', () async {
      when(() => mockClient.post(
            any(), 
            body: any(named: 'body'), 
            headers: any(named: 'headers')
          ))
          .thenAnswer((_) async => http.Response('{"token": "xyz", "id": "u2"}', 200));

      final token = await service.signup('user2');
      expect(token, 'xyz');
    });
    
    test('returns null on failure', () async {
      when(() => mockClient.post(any(), body: any(named: 'body'), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Error', 400));
          
      final token = await service.login('user1');
      expect(token, isNull);
    });
  });
}
