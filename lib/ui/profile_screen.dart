import 'package:flutter/material.dart';
import '../models/user_profile.dart';

import '../services/leaderboard_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const ProfileScreen({super.key, required this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;
  final LeaderboardService _service = LeaderboardService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    // Only fetch if ID is not generic "Local Player" or "Guest" (unless Guest is real on server)
    if (_profile.id == "Local Player") return;
    
    setState(() => _isLoading = true);
    final freshProfile = await _service.getUserProfile(_profile.id);
    if (freshProfile != null && mounted) {
      setState(() {
        _profile = freshProfile;
        _isLoading = false;
      });
    } else {
        if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Player Profile"),
          actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshProfile),
          ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              _profile.id,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _TierBadge(tier: _profile.tier),
            const Divider(height: 40),
            _StatRow(label: "ELO", value: _profile.elo.toString()),
            _StatRow(label: "Games Played", value: _profile.gamesPlayed.toString()),
            _StatRow(label: "Wins", value: _profile.wins.toString()),
            _StatRow(label: "Losses", value: _profile.losses.toString()),
            _StatRow(label: "Draws", value: _profile.draws.toString()),
            _StatRow(label: "Win Rate", value: "${(_profile.winRate * 100).toStringAsFixed(1)}%"),
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
