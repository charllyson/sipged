import 'package:flutter/material.dart';

class UserExpandIconBadge extends StatelessWidget {
  const UserExpandIconBadge({
    super.key,
    required this.readable,
    required this.total,
    this.color = const Color(0xFF2563EB),
    this.backgroundColor = const Color(0xFFEFF6FF),
    this.borderColor = const Color(0xFFBFDBFE),
  });

  final int readable;
  final int total;

  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            '$readable/$total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more_rounded,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }
}