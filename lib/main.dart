import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/game_bloc.dart';
import 'ui/game_board_widget.dart';
import 'ui/game_controls_widget.dart';
import 'ui/rule_selector_widget.dart';
import 'ui/rule_guidelines_widget.dart';
import 'ui/profile_screen.dart';
import 'ui/victory_overlay.dart';
import 'ui/shake_widget.dart';
import 'models/user_profile.dart';
import 'models/cosmetics.dart';

import 'ui/store_screen.dart';

void main() {
  runApp(const CaroChessApp());
}

class CaroChessApp extends StatelessWidget {
  const CaroChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caro Chess',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => GameBloc()..add(LoadSavedGame()),
        child: const GamePage(),
      ),
    );
  }
}

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caro Chess'),
        actions: [
          Builder(builder: (context) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.store),
                  onPressed: () {
                    final state = context.read<GameBloc>().state;
                    Inventory inventory = const Inventory();
                    if (state is GameInProgress) {
                      inventory = state.inventory;
                    } else if (state is GameOver) {
                      inventory = state.inventory;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreScreen(inventory: inventory),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    final state = context.read<GameBloc>().state;
                    UserProfile? profile;
                    if (state is GameInProgress) {
                      profile = state.userProfile;
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          profile: profile ?? const UserProfile(id: "Local Player"),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RuleSelectorWidget(),
                  const RuleGuidelinesWidget(),
                  const SizedBox(height: 10),
                  const GameControlsWidget(),
                  const SizedBox(height: 20),
                  BlocBuilder<GameBloc, GameState>(
                    builder: (context, state) {
                      return ShakeWidget(
                        shouldShake: state is GameOver && state.winner != null,
                        child: const GameBoardWidget(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              return VictoryOverlay(isVisible: state is GameOver && state.winner != null);
            },
          ),
        ],
      ),
    );
  }
}
