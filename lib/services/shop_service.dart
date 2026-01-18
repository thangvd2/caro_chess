import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/shop_models.dart';

class ShopService {
  final http.Client _client;

  ShopService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ShopItem>> getShopItems() async {
    final url = Uri.parse('${AppConfig.authUrl}/shop');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ShopItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int?> buyItem(String userId, String itemId) async {
    final url = Uri.parse('${AppConfig.authUrl}/shop/buy');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'item_id': itemId}),
      );
      if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
              return data['new_balance'] as int?; 
          }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> getUserCoins(String userId) async {
      // For now, we reuse GetUser from leaderboard or history handler? 
      // Server doesn't have dedicated GetUserCoins, but GetUser returns the profile with Coins.
      // We can use the existing /users/{id} endpoint if it exposes coins.
      // Checking backend main.go... yes, "/users/" handled by leaderboardHandler.GetUser
      // checking repository.go User struct... yes, Coins int `json:"coins"`.
      
      final url = Uri.parse('${AppConfig.authUrl}/users/$userId');
      try {
          final response = await _client.get(url);
          if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              return data['coins'] as int? ?? 0;
          }
          return 0;
      } catch (e) {
          return 0;
      }
  }
  
  Future<List<String>> getInventory(String userId) async {
    final url = Uri.parse('${AppConfig.authUrl}/inventory?user_id=$userId');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
         return List<String>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
