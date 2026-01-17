import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/user_profile.dart';
import '../models/game_models.dart';
import 'history_screen.dart';
import '../config/app_config.dart';
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
  AIDifficulty _selectedDifficulty = AIDifficulty.medium;

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
                  const SizedBox(height: 32),
                  _MenuButton(
                    icon: Icons.people,
                    label: "Play Local PvP",
                    onPressed: () {
                       _showGameSetupDialog(context, GameMode.localPvP);
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.computer,
                    label: "Play vs AI",
                    onPressed: () {
                      _showGameSetupDialog(context, GameMode.vsAI);
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.public,
                    label: "Play Online",
                    onPressed: () {
                       _showGameSetupDialog(context, GameMode.online);
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.add_box,
                    label: "Create Room",
                    onPressed: () {
                       _showRoomCreationDialog(context);
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

  void _showGameSetupDialog(BuildContext context, GameMode mode) {
    GameRule tempRule = _selectedRule;
    AIDifficulty tempDifficulty = _selectedDifficulty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(mode == GameMode.vsAI ? "Game Setup" : "Select Rules"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Game Rule", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<GameRule>(
                  segments: const [
                    ButtonSegment(value: GameRule.standard, label: Text("Standard")),
                    ButtonSegment(value: GameRule.freeStyle, label: Text("Free")),
                    ButtonSegment(value: GameRule.caro, label: Text("Caro")),
                  ],
                  selected: {tempRule},
                  onSelectionChanged: (Set<GameRule> newSelection) {
                    setState(() {
                      tempRule = newSelection.first;
                    });
                  },
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 8),
                Text(
                  _getRuleDescription(tempRule),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (mode == GameMode.vsAI) ...[
                  const SizedBox(height: 24),
                  const Text("AI Difficulty", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<AIDifficulty>(
                    segments: const [
                      ButtonSegment(value: AIDifficulty.easy, label: Text("Easy")),
                      ButtonSegment(value: AIDifficulty.medium, label: Text("Med")),
                      ButtonSegment(value: AIDifficulty.hard, label: Text("Hard")),
                    ],
                    selected: {tempDifficulty},
                    onSelectionChanged: (Set<AIDifficulty> newSelection) {
                      setState(() {
                        tempDifficulty = newSelection.first;
                      });
                    },
                    showSelectedIcon: false,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  // Update main state to remember choice
                  this.setState(() {
                    _selectedRule = tempRule;
                    if (mode == GameMode.vsAI) {
                      _selectedDifficulty = tempDifficulty;
                    }
                  });
                  Navigator.pop(ctx);
                  context.read<GameBloc>().add(StartGame(mode: mode, rule: tempRule, difficulty: tempDifficulty));
                },
                child: const Text("Start Game"),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showRoomCreationDialog(BuildContext context) {
      // Room creation implies Online Rule selection + Timer (StartRoomCreation event)
      // We will assume default timer for now or add timer selection?
      // StartRoomCreation supports time.
      // Let's add Rule Selector here too.
      GameRule tempRule = _selectedRule;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
           builder: (context, setState) {
             return AlertDialog(
                title: const Text("Create Room"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Select Game Rule", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<GameRule>(
                      segments: const [
                        ButtonSegment(value: GameRule.standard, label: Text("Standard")),
                        ButtonSegment(value: GameRule.freeStyle, label: Text("Free")),
                        ButtonSegment(value: GameRule.caro, label: Text("Caro")),
                      ],
                      selected: {tempRule},
                      onSelectionChanged: (Set<GameRule> newSelection) {
                        setState(() {
                          tempRule = newSelection.first;
                        });
                      },
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: 8),
                     Text(
                      _getRuleDescription(tempRule),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                   ElevatedButton(
                      onPressed: () {
                         this.setState(() {
                           _selectedRule = tempRule;
                         });
                         Navigator.pop(ctx);
                         // Note: StartRoomCreation needs to be updated to accept Rule!
                         // For now, I'm passing it, but I need to update GameBloc next.
                         // Using default timers for now.
                         context.read<GameBloc>().add(StartRoomCreation(rule: tempRule));
                      }, 
                      child: const Text("Create")
                   ),
                ],
             );
           }
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
