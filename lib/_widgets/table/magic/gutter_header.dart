// crie este widget simples (ex.: subwidgets/gutter_header.dart)
import 'package:flutter/material.dart';

class GutterHeader extends StatelessWidget {
  const GutterHeader({
    super.key,
    required this.width,
    required this.height,
    this.addTopBorder = true,
  });

  final double width;
  final double height;
  final bool addTopBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
          left: BorderSide(color: Colors.grey.shade300, width: 1),
          top: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
    );
  }
}
