import 'package:flutter/material.dart';


class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: .06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
        backgroundBlendMode: BlendMode.screen,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}
