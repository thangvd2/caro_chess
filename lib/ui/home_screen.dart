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
import 'glass_dialog.dart';

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
               // Use profile from state, or fallback to Local Player only if truly null
               final profile = state.userProfile ?? const UserProfile(id: "Local Player");
               
               Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(profile: profile)));
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
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => GlassDialog(
        title: "Join Room",
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Enter Room Code",
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(ctx), 
             child: const Text("Cancel", style: TextStyle(color: Colors.white70))
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
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
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return GlassDialog(
            title: mode == GameMode.vsAI ? "Game Setup" : "Select Rules",
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Game Rule", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                SegmentedButton<GameRule>(
                  style: ButtonStyle(
                     backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.selected)) return Colors.deepPurpleAccent;
                        return Colors.white10;
                     }),
                     foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  segments: const [
                    ButtonSegment(value: GameRule.standard, label: Text("Strict")),
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
                const SizedBox(height: 12),
                Text(
                  _getRuleDescription(tempRule),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (mode == GameMode.vsAI) ...[
                  const SizedBox(height: 24),
                  const Text("AI Difficulty", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  SegmentedButton<AIDifficulty>(
                    style: ButtonStyle(
                       backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) return Colors.deepPurpleAccent;
                          return Colors.white10;
                       }),
                       foregroundColor: MaterialStateProperty.all(Colors.white),
                    ),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
              ElevatedButton(
                onPressed: () {
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
      GameRule tempRule = _selectedRule;
      Duration tempTime = const Duration(minutes: 5);
      Duration tempIncrement = const Duration(seconds: 5);

      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (ctx) => StatefulBuilder(
           builder: (context, setState) {
             return GlassDialog(
                title: "Create Room",
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Game Rule
                    const Text("Select Game Rule", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    SegmentedButton<GameRule>(
                      style: ButtonStyle(
                         backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.selected)) return Colors.deepPurpleAccent;
                            return Colors.white10;
                         }),
                         foregroundColor: MaterialStateProperty.all(Colors.white),
                      ),
                      segments: const [
                        ButtonSegment(value: GameRule.standard, label: Text("Strict")),
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
                    const SizedBox(height: 4),
                     Text(
                      _getRuleDescription(tempRule),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Total Time
                    const Text("Total Time", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<Duration>(
                        style: ButtonStyle(
                           backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.selected)) return Colors.deepPurpleAccent;
                              return Colors.white10;
                           }),
                           foregroundColor: MaterialStateProperty.all(Colors.white),
                        ),
                        segments: const [
                          ButtonSegment(value: Duration(minutes: 1), label: Text("1m")),
                          ButtonSegment(value: Duration(minutes: 5), label: Text("5m")),
                          ButtonSegment(value: Duration(minutes: 10), label: Text("10m")),
                          ButtonSegment(value: Duration(minutes: 30), label: Text("30m")),
                        ],
                        selected: {tempTime},
                        onSelectionChanged: (Set<Duration> newSelection) {
                          setState(() => tempTime = newSelection.first);
                        },
                        showSelectedIcon: false,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Increment
                    const Text("Increment", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    SegmentedButton<Duration>(
                      style: ButtonStyle(
                         backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.selected)) return Colors.deepPurpleAccent;
                            return Colors.white10;
                         }),
                         foregroundColor: MaterialStateProperty.all(Colors.white),
                      ),
                      segments: const [
                        ButtonSegment(value: Duration.zero, label: Text("+0s")),
                        ButtonSegment(value: Duration(seconds: 5), label: Text("+5s")),
                        ButtonSegment(value: Duration(seconds: 10), label: Text("+10s")),
                      ],
                      selected: {tempIncrement},
                      onSelectionChanged: (Set<Duration> newSelection) {
                        setState(() => tempIncrement = newSelection.first);
                      },
                      showSelectedIcon: false,
                    ),

                  ],
                ),
                actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
                   ElevatedButton(
                      onPressed: () {
                         this.setState(() {
                           _selectedRule = tempRule;
                         });
                         Navigator.pop(ctx);
                         context.read<GameBloc>().add(StartRoomCreation(
                            rule: tempRule,
                            totalTime: tempTime,
                            increment: tempIncrement,
                            turnLimit: const Duration(minutes: 2), // Default safety cap
                         ));
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
        return "Strict (Exact 5): You must get exactly 5 in a row. 6 or more (Overline) does NOT count.";
      case GameRule.freeStyle:
        return "Free Style (5+): Get 5 or more in a row to win. Overlines are allowed.";
      case GameRule.caro:
        return "Caro (Blocked Ends): 5 in a row wins, UNLESS blocked at both ends by the opponent.";
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
