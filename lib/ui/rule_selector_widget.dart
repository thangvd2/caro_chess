import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/game_models.dart';

class RuleSelectorWidget extends StatelessWidget {
  const RuleSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Select Game Rule",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RuleButton(
              label: "Standard",
              rule: GameRule.standard,
            ),
            const SizedBox(width: 8),
            _RuleButton(
              label: "Free-style",
              rule: GameRule.freeStyle,
            ),
            const SizedBox(width: 8),
            _RuleButton(
              label: "Caro (Vietnam)",
              rule: GameRule.caro,
            ),
          ],
        ),
      ],
    );
  }
}

class _RuleButton extends StatelessWidget {
  final String label;
  final GameRule rule;

  const _RuleButton({required this.label, required this.rule});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.read<GameBloc>().add(StartGame(rule: rule));
      },
      child: Text(label),
    );
  }
}
