import 'package:flutter/material.dart';

class ScheduleDialogButton extends StatelessWidget {
  final String text;
  final String value;
  final IconData icon;
  final Color iconColor;

  const ScheduleDialogButton({
    super.key,
    required this.text,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Força o ícone a manter a cor indicada
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(color: iconColor),
      ),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context, value),
        icon: Icon(icon, color: iconColor),
        label: Text(text),
      ),
    );
  }
}