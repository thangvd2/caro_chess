import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/history_models.dart';

class HistoryService {
  final http.Client _client;

  HistoryService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch recently played matches for a user
  Future<List<MatchModel>> getUserMatches(String userId, {int limit = 20}) async {
    final url = Uri.parse('${AppConfig.authUrl}/users/$userId/matches?limit=$limit');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MatchModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Handle error or return empty list
      return [];
    }
  }

  /// Fetch full details for a specific match
  Future<MatchModel?> getMatch(String matchId) async {
    final url = Uri.parse('${AppConfig.authUrl}/matches/$matchId');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        return MatchModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
