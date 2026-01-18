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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive 
            ? (isLowTime ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2)) 
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? (isLowTime ? Colors.redAccent : Colors.greenAccent) : Colors.white10,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 20, color: isActive ? (isLowTime ? Colors.redAccent : Colors.greenAccent) : Colors.white38),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? (isLowTime ? Colors.redAccent : Colors.greenAccent) : Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? (isLowTime ? Colors.redAccent : Colors.greenAccent) : Colors.white,
                    fontSize: 14,
                    fontFamily: "Monospace", 
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

}
