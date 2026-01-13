import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_profile.dart';

class LeaderboardService {
  final http.Client _client;

  LeaderboardService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch top users by ELO
  Future<List<UserProfile>> getLeaderboard({int limit = 50}) async {
    final url = Uri.parse('${AppConfig.authUrl}/leaderboard?limit=\$limit');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserProfile.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch specific user profile with stats
  Future<UserProfile?> getUserProfile(String userId) async {
    final url = Uri.parse('${AppConfig.authUrl}/users/$userId');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
