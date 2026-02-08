import 'package:flutter/material.dart';

class SoftBubbles extends StatelessWidget {
  const SoftBubbles({super.key});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
              top: -60,
              left: -40,
              child: _bubble(const Color(0xFF60A5FA).withOpacity(.18), 220)),
          Positioned(
              bottom: -50,
              right: -30,
              child: _bubble(const Color(0xFF34D399).withOpacity(.16), 200)),
          Positioned(
              top: 220,
              right: -60,
              child: _bubble(const Color(0xFFFBBF24).withOpacity(.14), 160)),
          Positioned(
              bottom: 180,
              left: -50,
              child: _bubble(const Color(0xFFF472B6).withOpacity(.14), 140)),
        ],
      ),
    );
  }

  Widget _bubble(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(.5), blurRadius: 60, spreadRadius: 10)
        ],
      ),
    );
  }
}
