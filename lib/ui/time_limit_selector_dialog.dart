import 'package:flutter/material.dart';

class TimePreset {
  final String label;
  final Duration totalTime;
  final Duration increment;
  final Duration turnLimit;

  const TimePreset(this.label, this.totalTime, this.increment, {this.turnLimit = const Duration(seconds: 30)});
}

const List<TimePreset> kTimePresets = [
  TimePreset("Bullet 1m", Duration(minutes: 1), Duration.zero),
  TimePreset("Bullet 1m+1s", Duration(minutes: 1), Duration(seconds: 1)),
  TimePreset("Blitz 3m", Duration(minutes: 3), Duration.zero),
  TimePreset("Blitz 3m+2s", Duration(minutes: 3), Duration(seconds: 2)),
  TimePreset("Blitz 5m", Duration(minutes: 5), Duration.zero),
  TimePreset("Blitz 5m+5s", Duration(minutes: 5), Duration(seconds: 5)), // Approximate Default
  TimePreset("Rapid 10m", Duration(minutes: 10), Duration.zero),
  TimePreset("Rapid 10m+15s", Duration(minutes: 10), Duration(seconds: 15)),
  TimePreset("Classical 30m", Duration(minutes: 30), Duration.zero),
];

class TimeLimitSelectorDialog extends StatefulWidget {
  const TimeLimitSelectorDialog({super.key});

  @override
  State<TimeLimitSelectorDialog> createState() => _TimeLimitSelectorDialogState();
}

class _TimeLimitSelectorDialogState extends State<TimeLimitSelectorDialog> {
  TimePreset _selectedPreset = kTimePresets[5]; // Default 5m+5s

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Time Control"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...kTimePresets.map((preset) => RadioListTile<TimePreset>(
              title: Text(preset.label),
              subtitle: Text("${preset.increment.inSeconds}s increment"),
              value: preset,
              groupValue: _selectedPreset,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPreset = val);
              },
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedPreset),
          child: const Text("Create"),
        ),
      ],
    );
  }
}
