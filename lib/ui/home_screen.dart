import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/user_profile.dart';
import '../models/game_models.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameRule _selectedRule = GameRule.standard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caro Chess"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
               final state = context.read<GameBloc>().state;
               UserProfile? profile;
               if (state is GameInProgress) { 
                 profile = state.userProfile;
               }
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen(profile: UserProfile(id: "Local Player"))));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Welcome to Caro Chess", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  
                  // Rule Selector
                  const Text("Select Game Rule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<GameRule>(
                    segments: const [
                      ButtonSegment(value: GameRule.standard, label: Text("Standard")),
                      ButtonSegment(value: GameRule.freeStyle, label: Text("Free-style")),
                      ButtonSegment(value: GameRule.caro, label: Text("Caro")),
                    ],
                    selected: {_selectedRule},
                    onSelectionChanged: (Set<GameRule> newSelection) {
                      setState(() {
                        _selectedRule = newSelection.first;
                      });
                    },
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getRuleDescription(_selectedRule),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  
                  const SizedBox(height: 32),
                  _MenuButton(
                    icon: Icons.people,
                    label: "Play Local PvP",
                    onPressed: () {
                       context.read<GameBloc>().add(StartGame(mode: GameMode.localPvP, rule: _selectedRule));
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.computer,
                    label: "Play vs AI",
                    onPressed: () {
                      context.read<GameBloc>().add(StartGame(mode: GameMode.vsAI, rule: _selectedRule));
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.public,
                    label: "Play Online",
                    onPressed: () {
                       // Online matchmaking currently doesn't support rule filtering in the StartGame event blindly?
                       // Actually StartGame logic for online is: send FIND_MATCH.
                       // Server Matchmaker needs to know the rule. 
                       // Currently client sends FIND_MATCH type. 
                       // We might need to update Server to accept parameters. 
                       // For now, let's pass the rule to StartGame, even if backend implementation is pending.
                       // Looking at GameBloc:
                       // if (_mode == GameMode.online) { ... _socketService.send({'type': 'FIND_MATCH'}); }
                       // So rule is ignored for now. That is a separate task.
                       context.read<GameBloc>().add(StartGame(mode: GameMode.online, rule: _selectedRule));
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.add_box,
                    label: "Create Room",
                    onPressed: () {
                       // Similarly, Create Room needs rule.
                       context.read<GameBloc>().add(StartRoomCreation());
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.login, 
                    label: "Join Room",
                    onPressed: () {
                       _showJoinRoomDialog(context);
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                       _MiniButton(icon: Icons.history, label: "History", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                       _MiniButton(icon: Icons.leaderboard, label: "Rankings", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
                       _MiniButton(icon: Icons.store, label: "Shop", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))),
                    ],
                  )
                ],
              ),
            ),
        ),
      ),
    );
  }

  void _showJoinRoomDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Join Room"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Enter Room Code",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                // Use the context from HomeScreen (available as context in State)
                context.read<GameBloc>().add(JoinRoomRequested(code));
                Navigator.pop(ctx);
              }
            }, 
            child: const Text("Join")
          ),
        ],
      )
    );
  }

  String _getRuleDescription(GameRule rule) {
    switch (rule) {
      case GameRule.standard:
        return "Standard Gomoku: First to get exactly 5 in a row wins. Overlines (6+) do not count.";
      case GameRule.freeStyle:
        return "Free-style Gomoku: First to get 5 or more in a row wins. Overlines are allowed.";
      case GameRule.caro:
        return "Vietnamese Caro: First to get 5 in a row wins, UNLESS the line is blocked at both ends by the opponent.";
    }
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MenuButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 20)),
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MiniButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 32),
          onPressed: onPressed,
          style: IconButton.styleFrom(
             backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
             padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
