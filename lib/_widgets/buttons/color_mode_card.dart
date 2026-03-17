import 'package:flutter/material.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class ColorModeCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const ColorModeCard({super.key,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedFg = selected
        ? (isDark ? const Color(0xFF90C2FF) : Colors.blue)
        : (isDark ? Colors.white : Colors.black87);

    final Color? borderColor = selected
        ? (isDark ? Colors.blueAccent.withValues(alpha: 0.6) : Colors.blue)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 125,
          height: 40,
          child: BasicCard(
            isDark: isDark,
            borderRadius: 8,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderColor: borderColor,
            enableShadow: false,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedFg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}