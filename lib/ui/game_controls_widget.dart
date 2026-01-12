import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/game_models.dart';

class GameControlsWidget extends StatelessWidget {
  const GameControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        String statusText = "Welcome to Caro Chess";
        VoidCallback? onReset;

        if (state is GameInitial) {
           return ElevatedButton(
             onPressed: () => context.read<GameBloc>().add(const StartGame()),
             child: const Text('Start Game'),
           );
        }

        if (state is GameInProgress) {
          statusText = "Current Turn: ${state.currentPlayer == Player.x ? 'X' : 'O'}";
          onReset = () => context.read<GameBloc>().add(ResetGame());
        } else if (state is GameOver) {
          if (state.winner != null) {
            statusText = "Winner: ${state.winner == Player.x ? 'X' : 'O'}";
          } else {
            statusText = "Draw!"; 
          }
          onReset = () => context.read<GameBloc>().add(ResetGame());
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                statusText,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            if (onReset != null)
              ElevatedButton(
                onPressed: onReset,
                child: const Text('Reset Game'),
              ),
          ],
        );
      },
    );
  }
}
