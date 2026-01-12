import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/game_models.dart';
import '../ai/ai_service.dart';

class GameControlsWidget extends StatefulWidget {
  const GameControlsWidget({super.key});

  @override
  State<GameControlsWidget> createState() => _GameControlsWidgetState();
}

class _GameControlsWidgetState extends State<GameControlsWidget> {
  AIDifficulty _selectedDifficulty = AIDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is GameInitial) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("AI Difficulty: "),
                  DropdownButton<AIDifficulty>(
                    value: _selectedDifficulty,
                    items: AIDifficulty.values.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDifficulty = val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.read<GameBloc>().add(const StartGame(mode: GameMode.localPvP)),
                    child: const Text('Local PvP'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => context.read<GameBloc>().add(StartGame(
                          mode: GameMode.vsAI,
                          difficulty: _selectedDifficulty,
                        )),
                    child: const Text('Play vs AI'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => context.read<GameBloc>().add(const StartGame(mode: GameMode.online)),
                    child: const Text('Play Online'),
                  ),
                ],
              ),
            ],
          );
        }

        if (state is GameFindingMatch) {
          return const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text("Finding match..."),
            ],
          );
        }

        if (state is GameAIThinking) {
          return const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text("AI is thinking..."),
            ],
          );
        }

        String statusText = "";
        VoidCallback? onReset;
        VoidCallback? onUndo;
        VoidCallback? onRedo;

        if (state is GameInProgress) {
          statusText = "Turn: ${state.currentPlayer == Player.x ? 'X' : 'O'}";
          if (state.mode == GameMode.vsAI) statusText += " (vs AI)";
          if (state.mode == GameMode.online) {
            statusText += state.myPlayer == state.currentPlayer ? " (Your turn)" : " (Opponent turn)";
          }
          
          onReset = () => context.read<GameBloc>().add(ResetGame());
          if (state.canUndo) onUndo = () => context.read<GameBloc>().add(UndoMove());
          if (state.canRedo) onRedo = () => context.read<GameBloc>().add(RedoMove());
        } else if (state is GameOver) {
          statusText = state.winner != null ? "Winner: ${state.winner == Player.x ? 'X' : 'O'}" : "Draw!";
          onReset = () => context.read<GameBloc>().add(ResetGame());
        }

        return Column(
          children: [
            Text(statusText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: onUndo, child: const Text('Undo')),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: onRedo, child: const Text('Redo')),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onReset, child: const Text('Reset Game')),
          ],
        );
      },
    );
  }
}