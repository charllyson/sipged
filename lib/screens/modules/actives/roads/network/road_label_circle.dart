import 'package:flutter/material.dart';

class RoadLabelCircle extends StatelessWidget {
  final String text;
  final double diameter;
  final double fontSize;

  const RoadLabelCircle({
    super.key,
    required this.text,
    required this.diameter,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final borderWidth = (diameter * 0.07).clamp(1.0, 2.0);

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black87,
          width: borderWidth,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1,
          color: Colors.black87,
        ),
      ),
    );
  }
}