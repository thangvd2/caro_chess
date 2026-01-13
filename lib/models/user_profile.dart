import 'package:equatable/equatable.dart';

enum PlayerTier { bronze, silver, gold, platinum }

class UserProfile extends Equatable {
  final String id;
  final int elo;
  final int wins;
  final int losses;
  final int draws;

  final int gamesPlayed;
  final int coins;

  const UserProfile({
    required this.id,
    this.elo = 1200,
    this.gamesPlayed = 0,
    this.coins = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      elo: json['elo'] ?? 1200,
      gamesPlayed: json['games_played'] ?? 0,
      coins: json['coins'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
    );
  }

  PlayerTier get tier {
    if (elo < 1200) return PlayerTier.bronze;
    if (elo < 1500) return PlayerTier.silver;
    if (elo < 1800) return PlayerTier.gold;
    return PlayerTier.platinum;
  }

  double get winRate {
    final total = wins + losses + draws;
    if (total == 0) return 0.0;
    return wins / total;
  }

  @override
  List<Object?> get props => [id, elo, wins, losses, draws];
}
