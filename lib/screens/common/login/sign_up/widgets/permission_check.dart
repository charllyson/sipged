import 'package:flutter/material.dart';

class PermissionCheck extends StatelessWidget {
  const PermissionCheck({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final bool enabled;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = enabled ? color : const Color(0xFF98A2B3);

    final bgColor = value
        ? activeColor.withValues(alpha: enabled ? 0.10 : 0.07)
        : const Color(0xFFF9FAFB);

    final borderColor = value
        ? activeColor.withValues(alpha: enabled ? 0.35 : 0.18)
        : const Color(0xFFE5E7EB);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? () => onChanged(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 36,
        padding: const EdgeInsets.only(left: 8, right: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              activeColor: activeColor,
              onChanged: enabled
                  ? (v) {
                if (v == null) return;
                onChanged(v);
              }
                  : null,
            ),
            Icon(
              icon,
              size: 14,
              color: activeColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? const Color(0xFF101828) : Colors.black45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}