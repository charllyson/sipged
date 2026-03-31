import 'package:flutter/material.dart';

class AnimatedScaleFade extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedScaleFade({super.key,
    required this.child,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.96, end: 1),
      builder: (context, scale, _) {
        return AnimatedOpacity(
          duration: duration,
          curve: Curves.easeOut,
          opacity: 1,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}
