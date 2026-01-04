import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:siged/_widgets/cards/glass/glass_card.dart';
import 'package:siged/_widgets/overlays/animated_scale_fade.dart';

class OverlayScreen extends StatelessWidget {
  final String? message;
  final String? details;
  final double? progress;
  final IconData? icon;
  final Color barrierColor;
  final bool keepAppBarUndimmed;
  final Duration animationDuration;

  const OverlayScreen({
    super.key,
    required this.message,
    required this.details,
    required this.progress,
    required this.icon,
    required this.barrierColor,
    required this.keepAppBarUndimmed,
    required this.animationDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = keepAppBarUndimmed
        ? (Scaffold.maybeOf(context)?.appBarMaxHeight ?? 0)
        : 0.0;

    // Tons adaptativos (claro/escuro)
    final isDark = theme.brightness == Brightness.dark;
    final glassFill = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final glassBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.10);
    final barrier = barrierColor.withOpacity(0.12); // bem leve
    final cardShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.25 : 0.10),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];

    return Stack(
      children: [
        // Bloqueio de interação (ModalBarrier suave, não dispensável)
        Positioned.fill(
          child: ModalBarrier(
            color: barrier,
            dismissible: false,
          ),
        ),

        // Blur suave de fundo, sem “apertar” a AppBar (opcional)
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: TweenAnimationBuilder<double>(
              duration: animationDuration,
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: 1),
              builder: (context, t, _) {
                // Blur pequeno e progressivo para não “distorcer” a UI
                final sigma = lerpDouble(0, 3.5, t)!; // antes: 6.0
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),

        // AbsorbPointer extra por garantia (além do ModalBarrier)
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: SafeArea(
              // Card central com “glass”
              child: Align(
                alignment: Alignment.center,
                child: AnimatedScaleFade(
                  duration: animationDuration,
                  child: GlassCard(
                    icon: icon ?? Icons.sync,
                    message: message ?? 'Processando...',
                    details: details,
                    progress: progress,
                    glassFill: glassFill,
                    glassBorder: glassBorder,
                    shadows: cardShadow,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
