import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/game_models.dart';

class RuleGuidelinesWidget extends StatelessWidget {
  const RuleGuidelinesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        GameRule currentRule = GameRule.standard;
        if (state is GameInProgress) currentRule = state.rule;
        if (state is GameOver) currentRule = state.rule;

        String description = "";
        switch (currentRule) {
          case GameRule.standard:
            description = "Standard Gomoku: First to get exactly 5 in a row wins. Overlines (6+) do not count.";
            break;
          case GameRule.freeStyle:
            description = "Free-style Gomoku: First to get 5 or more in a row wins. Overlines are allowed.";
            break;
          case GameRule.caro:
            description = "Vietnamese Caro: First to get 5 in a row wins, UNLESS the line is blocked at both ends by the opponent.";
            break;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Rule Details:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description),
            ],
          ),
        );
      },
    );
  }
}
