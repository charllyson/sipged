import 'package:flutter/material.dart';

class GroupCounterBadge extends StatelessWidget {
  const GroupCounterBadge({
    super.key,
    required this.checkedCount,
    required this.total,
    required this.isSuper,
  });

  final int checkedCount;
  final int total;
  final bool isSuper;

  @override
  Widget build(BuildContext context) {
    final label = isSuper ? '$total/$total' : '$checkedCount/$total';

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }
}