import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';

  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Login with an existing User ID
  Future<String?> login(String userId) async {
    final url = Uri.parse('${AppConfig.authUrl}/login');
    try {
      final response = await _client.post(
        url,
        body: jsonEncode({'id': userId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        await _saveToken(token);
        await _saveUserId(userId);
        return token;
      } else {
        // Handle error (e.g., user not found)
        return null;
      }
    } catch (e) {
      // Network error
      return null;
    }
  }

  /// Signup a new User ID (or register implicit guest)
  Future<String?> signup(String userId) async {
    final url = Uri.parse('${AppConfig.authUrl}/signup');
    try {
      final response = await _client.post(
        url,
        body: jsonEncode({'id': userId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        await _saveToken(token);
        await _saveUserId(userId);
        return token;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAuthToken, token);
  }
  
  Future<void> _saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUserId, id);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAuthToken);
  }
  
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyAuthToken);
  }
}
