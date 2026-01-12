import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/models/user_profile.dart';

void main() {
  group('UserProfile and Tier Logic', () {
    test('returns correct tier based on ELO', () {
      expect(UserProfile(id: '1', elo: 800).tier, equals(PlayerTier.bronze));
      expect(UserProfile(id: '1', elo: 1200).tier, equals(PlayerTier.silver));
      expect(UserProfile(id: '1', elo: 1500).tier, equals(PlayerTier.gold));
      expect(UserProfile(id: '1', elo: 2000).tier, equals(PlayerTier.platinum));
    });

    test('calculates win rate correctly', () {
      final user = UserProfile(id: '1', elo: 1200, wins: 10, losses: 10);
      expect(user.winRate, equals(0.5));
    });
  });
}
