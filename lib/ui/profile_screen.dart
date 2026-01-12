import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const ProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Player Profile")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              profile.id,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _TierBadge(tier: profile.tier),
            const Divider(height: 40),
            _StatRow(label: "ELO", value: profile.elo.toString()),
            _StatRow(label: "Wins", value: profile.wins.toString()),
            _StatRow(label: "Losses", value: profile.losses.toString()),
            _StatRow(label: "Win Rate", value: "${(profile.winRate * 100).toStringAsFixed(1)}%"),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final PlayerTier tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (tier) {
      case PlayerTier.bronze: color = Colors.brown; break;
      case PlayerTier.silver: color = Colors.grey; break;
      case PlayerTier.gold: color = Colors.amber; break;
      case PlayerTier.platinum: color = Colors.blueGrey; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tier.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
