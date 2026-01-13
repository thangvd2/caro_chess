import 'game_models.dart';

class MatchModel {
  final String id;
  final String playerXId;
  final String playerOId;
  final String? winnerId;
  final DateTime timestamp;
  final List<MatchMove>? moves;

  MatchModel({
    required this.id,
    required this.playerXId,
    required this.playerOId,
    this.winnerId,
    required this.timestamp,
    this.moves,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      playerXId: json['player_x_id'],
      playerOId: json['player_o_id'],
      winnerId: json['winner_id'],
      timestamp: DateTime.parse(json['timestamp']),
      moves: json['moves'] != null
          ? (json['moves'] as List).map((m) => MatchMove.fromJson(m)).toList()
          : null,
    );
  }
  
  bool get isDraw => winnerId == null;
}

class MatchMove {
  final int x;
  final int y;
  final Player player;
  final int order;

  MatchMove({
    required this.x,
    required this.y,
    required this.player,
    required this.order,
  });

  factory MatchMove.fromJson(Map<String, dynamic> json) {
    return MatchMove(
      x: json['x'],
      y: json['y'],
      player: json['player'] == 'X' ? Player.x : Player.o,
      order: json['order'],
    );
  }
}
