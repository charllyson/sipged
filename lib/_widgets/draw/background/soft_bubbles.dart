import 'package:flutter/material.dart';

class SoftBubbles extends StatelessWidget {
  const SoftBubbles({
    super.key,
    this.bubbles = const <SoftBubbleData>[
      SoftBubbleData(
        top: -60,
        left: -40,
        size: 220,
        color: Color(0xFF60A5FA),
        alpha: .18,
      ),
      SoftBubbleData(
        bottom: -50,
        right: -30,
        size: 200,
        color: Color(0xFF34D399),
        alpha: .16,
      ),
      SoftBubbleData(
        top: 220,
        right: -60,
        size: 160,
        color: Color(0xFFFBBF24),
        alpha: .14,
      ),
      SoftBubbleData(
        bottom: 180,
        left: -50,
        size: 140,
        color: Color(0xFFF472B6),
        alpha: .14,
      ),
    ],
  });

  /// Bolhas específicas para o card superior do perfil.
  ///
  /// Aqui elas ficam coladas/recortadas pela borda do card,
  /// porque o widget deve ser usado dentro de um ClipRRect.
  const SoftBubbles.profileHero({super.key})
      : bubbles = const <SoftBubbleData>[
    SoftBubbleData(
      top: -18,
      right: -18,
      size: 150,
      color: Colors.white,
      alpha: .12,
      blurRadius: 0,
      spreadRadius: 0,
    ),
    SoftBubbleData(
      bottom: -62,
      right: 72,
      size: 138,
      color: Colors.white,
      alpha: .08,
      blurRadius: 0,
      spreadRadius: 0,
    ),
    SoftBubbleData(
      top: 44,
      right: 44,
      size: 92,
      color: Colors.white,
      alpha: .055,
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  final List<SoftBubbleData> bubbles;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: bubbles.map((bubble) {
          return Positioned(
            top: bubble.top,
            left: bubble.left,
            right: bubble.right,
            bottom: bubble.bottom,
            child: _SoftBubble(data: bubble),
          );
        }).toList(),
      ),
    );
  }
}

class SoftBubbleData {
  const SoftBubbleData({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    this.alpha = 1,
    this.blurRadius = 60,
    this.spreadRadius = 10,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  final double size;
  final Color color;
  final double alpha;

  final double blurRadius;
  final double spreadRadius;
}

class _SoftBubble extends StatelessWidget {
  const _SoftBubble({
    required this.data,
  });

  final SoftBubbleData data;

  @override
  Widget build(BuildContext context) {
    final color = data.color.withValues(alpha: data.alpha);

    return Container(
      height: data.size,
      width: data.size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: data.blurRadius <= 0
            ? null
            : [
          BoxShadow(
            color: color.withValues(alpha: .5),
            blurRadius: data.blurRadius,
            spreadRadius: data.spreadRadius,
          ),
        ],
      ),
    );
  }
}