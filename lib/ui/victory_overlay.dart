import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../config/app_config.dart';

class VictoryOverlay extends StatefulWidget {
  final bool isVisible;
  const VictoryOverlay({super.key, required this.isVisible});

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: AppConfig.victoryConfettiDuration);
    if (widget.isVisible) _controller.play();
  }

  @override
  void didUpdateWidget(VictoryOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      print("VictoryOverlay: Playing confetti");
      _controller.play();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 20,
          gravity: 0.1,
          minBlastForce: 10,
          maxBlastForce: 30,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ),
    );
  }
}
