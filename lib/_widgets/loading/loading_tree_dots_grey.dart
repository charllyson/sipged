import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoadingTreeDotsGrey extends StatelessWidget {
  final double? size;
  final double strokeWidth;
  final Color? color;
  final bool centered;

  const LoadingTreeDotsGrey({
    super.key,
    this.size,
    this.strokeWidth = 4,
    this.color,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final double resolvedSize = size ?? 100;

    Widget indicator = SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: const RiveAnimation.asset(
        'assets/rive/tree-dots-grey-loading.riv',
        fit: BoxFit.contain,
      ),
    );

    if (centered) {
      return Center(child: indicator);
    }

    return indicator;
  }
}