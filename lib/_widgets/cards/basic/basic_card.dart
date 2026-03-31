import 'dart:ui';

import 'package:flutter/material.dart';

class BasicCardItem<T> {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final T value;

  const BasicCardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
  });
}

class BasicCard extends StatelessWidget {
  const BasicCard({
    super.key,
    required this.child,
    required this.isDark,
    this.onTap,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.alignment,
    this.width,
    this.height,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.boxShadow,
    this.enableShadow = true,
    this.animationDuration = const Duration(milliseconds: 160),
    this.clipBehavior = Clip.antiAlias,
    this.useGlassEffect = false,
    this.blurSigmaX = 12,
    this.blurSigmaY = 12,
  });

  final Widget child;
  final bool isDark;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final bool enableShadow;
  final Duration animationDuration;
  final Clip clipBehavior;
  final bool useGlassEffect;
  final double blurSigmaX;
  final double blurSigmaY;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final resolvedBorderColor =
        borderColor ??
            (useGlassEffect
                ? (isDark
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.55))
                : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)));

    final resolvedBackgroundColor =
        backgroundColor ??
            (useGlassEffect
                ? (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.18))
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white));

    final resolvedGradient =
        gradient ??
            (useGlassEffect
                ? LinearGradient(
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
            )
                : null);

    final resolvedShadows =
        boxShadow ??
            (enableShadow
                ? [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: useGlassEffect
                      ? (isDark ? 0.22 : 0.10)
                      : (isDark ? 0.40 : 0.08),
                ),
                blurRadius: useGlassEffect ? 24 : 18,
                offset: const Offset(0, 10),
              ),
            ]
                : const <BoxShadow>[]);

    Widget content = AnimatedContainer(
      duration: animationDuration,
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: resolvedGradient == null ? resolvedBackgroundColor : null,
        gradient: resolvedGradient,
        border: Border.all(
          color: resolvedBorderColor,
          width: useGlassEffect ? 1 : 0.8,
        ),
        boxShadow: resolvedShadows,
      ),
      child: child,
    );

    if (useGlassEffect) {
      content = ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigmaX,
            sigmaY: blurSigmaY,
          ),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}