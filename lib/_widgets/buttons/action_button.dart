
import 'package:flutter/material.dart';
import 'package:siged/_widgets/buttons/button_flutuante_hover.dart';

/// Botão de ação com o mesmo “look & feel” do ScheduleMenuButtons
class ActionButton extends StatelessWidget {
  const ActionButton({super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.borderColor,
    required this.highlightColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color borderColor;
  final Color highlightColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: highlightColor.withOpacity(0.20),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: BotaoFlutuanteHover(
          icon: icon,
          label: label,
          color: background,
          onPressed: onTap,
        ),
      ),
    );
  }
}