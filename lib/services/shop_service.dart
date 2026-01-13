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

  Future<bool> buyItem(String userId, String itemId) async {
    final url = Uri.parse('${AppConfig.authUrl}/shop/buy');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'item_id': itemId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
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
