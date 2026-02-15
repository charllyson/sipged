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
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black87, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            spreadRadius: 0.5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.visible,
        softWrap: false,
      ),
    );
  }
}
