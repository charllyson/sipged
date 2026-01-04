import 'package:flutter/material.dart';

class BasicCard extends StatelessWidget {
  final Widget child;

  /// Tema atual (dark / light)
  final bool isDark;

  /// Raio do borderRadius (default 18)
  final double borderRadius;

  /// Padding interno
  final EdgeInsets padding;

  /// Largura opcional (se null, usa largura natural)
  final double? width;
  final double? height;

  /// Gradiente de fundo (se não for null, ignora [backgroundColor])
  final Gradient? gradient;

  /// Cor da borda (se null, usa padrão suave)
  final Color? borderColor;

  /// Ativa/desativa sombra
  final bool enableShadow;


  /// Duração da animação (para transições de cor/tamanho suaves)
  final Duration animationDuration;

  const BasicCard({
    super.key,
    required this.child,
    required this.isDark,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.all(12),
    this.width,
    this.height,
    this.gradient,
    this.borderColor = Colors.black12,
    this.enableShadow = true,
    this.animationDuration = const Duration(milliseconds: 160),
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBorder = borderColor ??
        (isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.05));

    final List<BoxShadow> shadows = enableShadow
        ? [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ]
        : const [];

    return AnimatedContainer(
      duration: animationDuration,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white,
        border: Border.all(color: effectiveBorder, width: 0.8),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
