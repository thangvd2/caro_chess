import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';

class GameRepository {
  static const String _ruleKey = 'game_rule';
  static const String _historyKey = 'game_history';

  Future<void> saveGame(GameRule rule, List<Position> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ruleKey, rule.name);
    
    final historyJson = history.map((p) => {'x': p.x, 'y': p.y}).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }

  Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final ruleName = prefs.getString(_ruleKey);
    final historyString = prefs.getString(_historyKey);

    if (ruleName == null || historyString == null) return null;

    final rule = GameRule.values.firstWhere((e) => e.name == ruleName);
    final List<dynamic> historyJson = jsonDecode(historyString);
    final history = historyJson.map((m) => Position(x: m['x'], y: m['y'])).toList();

    return {
      'rule': rule,
      'history': history,
    };
  }

  Future<void> clearGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ruleKey);
    await prefs.remove(_historyKey);
  }
}
