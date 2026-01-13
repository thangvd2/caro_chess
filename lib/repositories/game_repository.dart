import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';
import '../models/cosmetics.dart';
import '../ai/ai_service.dart';

class GameRepository {
  static const String _ruleKey = 'game_rule';
  static const String _modeKey = 'game_mode';
  static const String _difficultyKey = 'game_difficulty';
  static const String _historyKey = 'game_history';
  static const String _inventoryKey = 'game_inventory';

  Future<void> saveGame(GameRule rule, List<Position> history, {GameMode mode = GameMode.localPvP, AIDifficulty difficulty = AIDifficulty.medium}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ruleKey, rule.name);
    await prefs.setString(_modeKey, mode.name);
    await prefs.setString(_difficultyKey, difficulty.name);
    
    final historyJson = history.map((p) => {'x': p.x, 'y': p.y}).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }

  Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final ruleName = prefs.getString(_ruleKey);
    final modeName = prefs.getString(_modeKey);
    final diffName = prefs.getString(_difficultyKey);
    final historyString = prefs.getString(_historyKey);

    if (ruleName == null || historyString == null) return null;

    final rule = GameRule.values.firstWhere((e) => e.name == ruleName);
    final mode = modeName != null ? GameMode.values.firstWhere((e) => e.name == modeName) : GameMode.localPvP;
    final diff = diffName != null ? AIDifficulty.values.firstWhere((e) => e.name == diffName) : AIDifficulty.medium;
    
    final List<dynamic> historyJson = jsonDecode(historyString);
    final history = historyJson.map((m) => Position(x: m['x'], y: m['y'])).toList();

    return {
      'rule': rule,
      'mode': mode,
      'difficulty': diff,
      'history': history,
    };
  }

  Future<void> clearGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ruleKey);
    await prefs.remove(_modeKey);
    await prefs.remove(_difficultyKey);
    await prefs.remove(_historyKey);
  }

  Future<void> saveInventory(Inventory inventory) async {
    final prefs = await SharedPreferences.getInstance();
    final json = {
      'coins': inventory.coins,
      'ownedItemIds': inventory.ownedItemIds,
      'equippedPieceSkinId': inventory.equippedPieceSkinId,
      'equippedBoardSkinId': inventory.equippedBoardSkinId,
    };
    await prefs.setString(_inventoryKey, jsonEncode(json));
  }

  Future<Inventory> loadInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_inventoryKey);
    if (jsonString == null) return const Inventory();
    
    final json = jsonDecode(jsonString);
    return Inventory(
      coins: json['coins'],
      ownedItemIds: List<String>.from(json['ownedItemIds']),
      equippedPieceSkinId: json['equippedPieceSkinId'],
      equippedBoardSkinId: json['equippedBoardSkinId'],
    );
  }
}
