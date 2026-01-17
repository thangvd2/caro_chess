import 'package:flutter/material.dart';

class PlayerTimerWidget extends StatelessWidget {
  final Duration? timeRemaining;
  final bool isActive;
  final String label;
  final Duration? turnTimeRemaining;


  const PlayerTimerWidget({
    Key? key,
    required this.timeRemaining,
    required this.isActive,
    required this.label,
    this.turnTimeRemaining,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (timeRemaining == null) return const SizedBox.shrink();

    final minutes = timeRemaining!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = timeRemaining!.inSeconds.remainder(60).toString().padLeft(2, '0');
    final isLowTime = timeRemaining!.inSeconds < 30;
    
    String timeText = "$minutes:$seconds";
    
    // Add Turn Timer if available and active
    if (isActive && turnTimeRemaining != null) {
        final turnSec = turnTimeRemaining!.inSeconds;
        timeText += " | ${turnSec}s";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? (isLowTime ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2)) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? (isLowTime ? Colors.red : Colors.green) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 16, color: isActive ? (isLowTime ? Colors.red : Colors.green) : Colors.grey),
          const SizedBox(width: 4),
          Text(
            "$label $timeText",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? (isLowTime ? Colors.red : Colors.green) : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

}
