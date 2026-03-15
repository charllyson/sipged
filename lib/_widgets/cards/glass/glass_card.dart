import 'package:flutter/material.dart';
import 'package:sipged/_widgets/cards/glass/glass_container.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.gradient,
    this.blurSigmaX = 12,
    this.blurSigmaY = 12,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final double blurSigmaX;
  final double blurSigmaY;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      boxShadow: boxShadow,
      gradient: gradient,
      blurSigmaX: blurSigmaX,
      blurSigmaY: blurSigmaY,
      child: child,
    );
  }
}