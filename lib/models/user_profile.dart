import 'package:equatable/equatable.dart';

enum PlayerTier { bronze, silver, gold, platinum }

class UserProfile extends Equatable {
  final String id;
  final int elo;
  final int wins;
  final int losses;
  final int draws;

  const UserProfile({
    required this.id,
    this.elo = 1200,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

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
