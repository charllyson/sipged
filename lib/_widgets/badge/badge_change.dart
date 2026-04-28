import 'package:flutter/material.dart';

class BadgeChange extends StatelessWidget {
  const BadgeChange({super.key,
    required this.count,
    required this.color,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 17,
        minHeight: 17,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}