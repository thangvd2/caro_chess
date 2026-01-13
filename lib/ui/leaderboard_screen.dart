import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';
import '../models/user_profile.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _service = LeaderboardService();
  List<UserProfile>? _users;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await _service.getLeaderboard();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _users == null || _users!.isEmpty
             ? const Center(child: Text('No players found.'))
             : ListView.builder(
                 itemCount: _users!.length,
                 itemBuilder: (context, index) {
                   final user = _users![index];
                   return _buildUserTile(user, index);
                 },
               ),
    );
  }

  Widget _buildUserTile(UserProfile user, int index) {
    Color? tileColor;
    if (index == 0) tileColor = const Color(0xFFFFD700).withOpacity(0.2); // Gold
    else if (index == 1) tileColor = const Color(0xFFC0C0C0).withOpacity(0.2); // Silver
    else if (index == 2) tileColor = const Color(0xFFCD7F32).withOpacity(0.2); // Bronze
    
    return Card(
      color: tileColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text('#${index + 1}'),
        ),
        title: Text(user.id, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Wins: ${user.wins} | Losses: ${user.losses}'),
        trailing: Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
           decoration: BoxDecoration(
               color: Colors.blue,
               borderRadius: BorderRadius.circular(12),
           ),
           child: Text(
               'ELO ${user.elo}', 
               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
           ),
        ),
      ),
    );
  }
}
