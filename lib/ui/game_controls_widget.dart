import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/game_models.dart';
import '../ai/ai_service.dart';
import 'player_timer_widget.dart';
import 'time_limit_selector_dialog.dart';



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
                    child: const Text('Quick Match (5m+5s)'),

                  ),
                  ElevatedButton(
                    onPressed: () async {
                       final preset = await showDialog<TimePreset>(
                          context: context,
                          builder: (_) => const TimeLimitSelectorDialog(),
                       );
                       if (preset != null && context.mounted) {
                          context.read<GameBloc>().add(StartRoomCreation(
                              totalTime: preset.totalTime,
                              increment: preset.increment,
                              turnLimit: preset.turnLimit
                          ));
                       }
                    },
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
          return Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                state.isCreatingRoom ? "Creating room..." : "Finding match...",
                style: const TextStyle(fontSize: 18)
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<GameBloc>().add(ResetGame()),
                child: const Text('Cancel'),
              ),
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
            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            if (state is GameInProgress && state.mode == GameMode.online) ...[
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                      Expanded(
                        child: PlayerTimerWidget(
                            label: "Player X",
                            timeRemaining: state.timeRemainingX,
                            isActive: state.currentPlayer == Player.x,
                            turnTimeRemaining: state.currentPlayer == Player.x ? state.currentTurnTimeRemaining : null,
                        ),
                      ),
                      const SizedBox(width: 8), // Replaced spaceEvenly spacing logic with explicit spacing
                      Expanded(
                        child: PlayerTimerWidget(
                            label: "Player O",
                            timeRemaining: state.timeRemainingO,
                            isActive: state.currentPlayer == Player.o,
                            turnTimeRemaining: state.currentPlayer == Player.o ? state.currentTurnTimeRemaining : null,
                        ),
                      ),
                   ],
                ),
                const SizedBox(height: 20),
            ],
            
            // Game Actions (Undo/Redo)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onUndo != null)
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
                     child: ElevatedButton.icon(
                        icon: const Icon(Icons.undo, size: 20),
                        label: const Text('Undo'),
                        onPressed: onUndo,
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white10,
                           foregroundColor: Colors.white70,
                           elevation: 0,
                        ),
                     ),
                   ),
                if (onRedo != null)
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
                     child: ElevatedButton.icon(
                        icon: const Icon(Icons.redo, size: 20),
                        label: const Text('Redo'),
                        onPressed: onRedo,
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white10,
                           foregroundColor: Colors.white70,
                           elevation: 0,
                        ),
                     ),
                   ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Match Actions (Exit / New Game / Leave)
            if ((state is GameInProgress && state.mode != GameMode.online) || 
                (state is GameOver && state.mode != GameMode.online)) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.redAccent.withOpacity(0.8),
                       foregroundColor: Colors.white,
                    ),
                    onPressed: onReset, 
                    icon: const Icon(Icons.exit_to_app, size: 20),
                    label: const Text('Exit'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
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
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.deepPurpleAccent,
                       foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('New Game'),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: onReset, 
                style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.redAccent.withOpacity(0.8),
                   foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close, size: 20),
                label: const Text('Leave Room'),
              ),
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
