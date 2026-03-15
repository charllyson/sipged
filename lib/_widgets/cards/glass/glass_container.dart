import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.alignment,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.blurSigmaX = 12,
    this.blurSigmaY = 12,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.gradient,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final AlignmentGeometry? alignment;
  final BorderRadius borderRadius;
  final double blurSigmaX;
  final double blurSigmaY;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBackgroundColor =
        backgroundColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.18));

    final resolvedBorderColor =
        borderColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.55));

    final resolvedShadow =
        boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ];

    final resolvedGradient =
        gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.04),
              ]
                  : [
                Colors.white.withValues(alpha: 0.30),
                Colors.white.withValues(alpha: 0.10),
              ],
            );

    final content = ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigmaX,
          sigmaY: blurSigmaY,
        ),
        child: Container(
          width: width,
          height: height,
          margin: margin,
          padding: padding,
          alignment: alignment,
          decoration: BoxDecoration(
            color: resolvedBackgroundColor,
            borderRadius: borderRadius,
            border: Border.all(color: resolvedBorderColor, width: 1),
            boxShadow: resolvedShadow,
            gradient: resolvedGradient,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}