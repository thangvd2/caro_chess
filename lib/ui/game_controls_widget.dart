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
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => context.read<GameBloc>().add(StartGame(
                          mode: GameMode.vsAI,
                          difficulty: _selectedDifficulty,
                        )),
                    child: const Text('Play vs AI'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ElevatedButton(
                    onPressed: () => context.read<GameBloc>().add(const StartGame(mode: GameMode.online)),
                    child: const Text('Quick Match'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.read<GameBloc>().add(StartRoomCreation()),
                    child: const Text('Create Room'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showJoinRoomDialog(context),
                    child: const Text('Join Room'),
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

        if (state is GameWaitingInRoom) {
          return Column(
            children: [
              const Text("Waiting for opponent...", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              SelectableText(
                "ROOM CODE: ${state.code}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<GameBloc>().add(ResetGame()),
                child: const Text('Cancel'),
              ),
            ],
          );
        }



        String statusText = "";
        VoidCallback? onReset;
        VoidCallback? onUndo;
        VoidCallback? onRedo;

        if (state is GameInProgress) {
          if (state.isSpectating) {
            statusText = "Spectating (X vs O)";
            onReset = () => context.read<GameBloc>().add(ResetGame()); // Leave Room
            // Undo/Redo unavailable for spectator
          } else {
              statusText = "Turn: ${state.currentPlayer == Player.x ? 'X' : 'O'}";
              if (state.mode == GameMode.vsAI) statusText += " (vs AI)";
              if (state.mode == GameMode.online) {
                statusText += state.myPlayer == state.currentPlayer ? " (Your turn)" : " (Opponent turn)";
              }
              
              onReset = () => context.read<GameBloc>().add(ResetGame());
              if (state.canUndo) onUndo = () => context.read<GameBloc>().add(UndoMove());
              if (state.canRedo) onRedo = () => context.read<GameBloc>().add(RedoMove());
          }
        } else if (state is GameOver) {
          statusText = state.winner != null ? "Winner: ${state.winner == Player.x ? 'X' : 'O'}" : "Draw!";
          
          if (state.mode == GameMode.online && state.myPlayer != null && state.winner != null) {
            if (state.winner == state.myPlayer) {
              statusText = "You Win!";
              if (state.winReason == "opponent_left") {
                statusText += " (Opponent Left)";
              }
            } else {
              statusText = "You Lose!";
            }
          }
          
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
            if ((state is GameInProgress && state.mode != GameMode.online) || 
                (state is GameOver && state.mode != GameMode.online)) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: onReset, 
                    child: const Text('Exit', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (state is GameInProgress) {
                        context.read<GameBloc>().add(StartGame(
                          mode: state.mode,
                          rule: state.rule,
                          difficulty: state.difficulty,
                        ));
                      } else if (state is GameOver) {
                        context.read<GameBloc>().add(StartGame(
                          mode: state.mode,
                          rule: state.rule,
                          difficulty: state.difficulty,
                        ));
                      }
                    },
                    child: const Text('New Game'),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton(onPressed: onReset, child: const Text(
                'Leave Room' // Online
              )),
            ],
          ],
        );
      },
    );
  }

  void _showJoinRoomDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Join Private Room"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter 4-character code"),
            autofocus: true,
            maxLength: 4,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final code = controller.text.toUpperCase();
                if (code.length == 4) {
                  context.read<GameBloc>().add(JoinRoomRequested(code));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Join"),
            ),
          ],
        );
      },
    );
  }
}
