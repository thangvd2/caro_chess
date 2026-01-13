import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../services/auth_service.dart';
import '../models/history_models.dart';
import 'replay_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final AuthService _authService = AuthService();
  
  List<MatchModel>? _matches;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _userId = await _authService.getUserId();
    if (_userId != null) {
      final matches = await _historyService.getUserMatches(_userId!);
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_userId == null) {
      return const Center(child: Text('Not authenticated. Play a game online to login.'));
    }

    if (_matches == null || _matches!.isEmpty) {
      return const Center(child: Text('No matches found.'));
    }

    return ListView.builder(
      itemCount: _matches!.length,
      itemBuilder: (context, index) {
        final match = _matches![index];
        return _buildMatchTile(match);
      },
    );
  }

  Widget _buildMatchTile(MatchModel match) {
    // Determine result
    String result = "Draw";
    Color color = Colors.grey;
    
    if (match.winnerId != null) {
      if (match.winnerId == _userId) {
        result = "Victory";
        color = Colors.green;
      } else {
        result = "Defeat";
        color = Colors.red;
      }
    }
    
    // Determine Opponent (Assuming playerX/O)
    String opponent = match.playerXId == _userId ? match.playerOId : match.playerXId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.history, color: color),
        title: Text('$result vs $opponent'),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(match.timestamp.toLocal())),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReplayScreen(matchId: match.id, initialData: match),
            ),
          );
        },
      ),
    );
  }
}
