import 'package:flutter/material.dart';
import 'dart:math';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shouldShake;

  const ShakeWidget({super.key, required this.child, required this.shouldShake});

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShake && !oldWidget.shouldShake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double sineValue = sin(_controller.value * 6 * pi); // 3 cycles
        final double amplitude = 10 * (1 - _controller.value); // Decay
        return Transform.translate(
          offset: Offset(sineValue * amplitude, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
