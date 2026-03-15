import 'package:flutter/material.dart';

class BasicCard extends StatelessWidget {
  const BasicCard({
    super.key,
    required this.child,
    required this.isDark,
    this.onTap,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.all(12),
    this.width,
    this.height,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.enableShadow = true,
    this.animationDuration = const Duration(milliseconds: 160),
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;

  /// Tema atual (dark / light)
  final bool isDark;

  /// Callback de clique
  final VoidCallback? onTap;

  /// Raio do borderRadius
  final double borderRadius;

  /// Padding interno
  final EdgeInsets padding;

  /// Dimensões opcionais
  final double? width;
  final double? height;

  /// Cor de fundo simples
  final Color? backgroundColor;

  /// Gradiente de fundo (se informado, tem prioridade sobre [backgroundColor])
  final Gradient? gradient;

  /// Cor da borda
  final Color? borderColor;

  /// Ativa/desativa sombra
  final bool enableShadow;

  /// Duração da animação
  final Duration animationDuration;

  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder =
        borderColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05));

    final effectiveBackground =
        backgroundColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final shadows = enableShadow
        ? [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ]
        : const <BoxShadow>[];

    final radius = BorderRadius.circular(borderRadius);

    final content = AnimatedContainer(
      duration: animationDuration,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: gradient == null ? effectiveBackground : null,
        gradient: gradient,
        border: Border.all(color: effectiveBorder, width: 0.8),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: radius,
          clipBehavior: clipBehavior,
          child: content,
        ),
      ),
    );
  }
}