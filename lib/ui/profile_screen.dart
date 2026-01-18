import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';

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
              IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<GameBloc>().add(LogoutRequested());
                    // Pop to root (AppContent) which will show LoginScreen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
              ),
          ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildAvatar(context),
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

  Widget _buildAvatar(BuildContext context) {
      final inventory = context.select((GameBloc bloc) => bloc.state.inventory);
      final frameId = inventory?.equippedAvatarFrameId;
      
      Widget avatar = const CircleAvatar(
          radius: 50,
          child: Icon(Icons.person, size: 50),
      );

      BoxDecoration? decoration;

      switch (frameId) {
        case 'gold_avatar':
          decoration = const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Colors.amber, Colors.yellowAccent, Colors.amber]),
            boxShadow: [BoxShadow(color: Colors.amber, blurRadius: 10, spreadRadius: 2)],
          );
          break;
        case 'avatar_diamond':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.white, Colors.blueAccent]),
            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 12, spreadRadius: 3)],
            border: Border.all(color: Colors.white, width: 2),
          );
          break;
        case 'avatar_rainbow':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple]),
            boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
          );
          break;
        case 'avatar_fire':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Colors.red.shade900, Colors.orange, Colors.yellow]),
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.8), blurRadius: 15, spreadRadius: 1)],
          );
          break;
        case 'avatar_ice':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Colors.white, Colors.cyan, Colors.blue]),
            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
          );
          break;
        case 'avatar_nature':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Colors.green.shade900, Colors.lightGreenAccent]),
            border: Border.all(color: Colors.brown, width: 3),
          );
          break;
        case 'avatar_tech':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: Colors.cyanAccent, width: 2),
            boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)],
          );
          break;
        case 'avatar_royal':
          decoration = const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Colors.deepPurple, Colors.purpleAccent, Colors.amber]),
            boxShadow: [BoxShadow(color: Colors.purple, blurRadius: 12, spreadRadius: 2)],
          );
          break;
        case 'avatar_mystic':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Colors.indigo, Colors.pink]),
            boxShadow: [BoxShadow(color: Colors.indigoAccent.withOpacity(0.5), blurRadius: 10)],
          );
          break;
        case 'avatar_cyber':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade900,
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 10)],
          );
          break;
        case 'avatar_pixel':
          decoration = BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 4), // Bold black outline
          );
          break;
      }

      if (decoration != null) {
          return Container(
              padding: const EdgeInsets.all(4),
              decoration: decoration,
              child: avatar,
          );
      }
      return avatar;
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
