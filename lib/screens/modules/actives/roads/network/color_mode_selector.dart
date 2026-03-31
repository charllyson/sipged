import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class ColorModeSelectorCards extends StatelessWidget {
  final ActiveRoadColorMode selectedMode;
  final ValueChanged<ActiveRoadColorMode> onChanged;

  const ColorModeSelectorCards({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildModeCard({
      required String label,
      required ActiveRoadColorMode mode,
    }) {
      final selected = selectedMode == mode;

      final Color selectedFg = selected
          ? (isDark ? const Color(0xFF90C2FF) : Colors.blue)
          : (isDark ? Colors.white : Colors.black87);

      final Color? borderColor = selected
          ? (isDark ? Colors.blueAccent.withValues(alpha: 0.6) : Colors.blue)
          : null;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          width: 125,
          height: 40,
          child: BasicCard(
            isDark: isDark,
            onTap: () => onChanged(mode),
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
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildModeCard(
          label: 'Padrão',
          mode: ActiveRoadColorMode.defaultColor,
        ),
        buildModeCard(
          label: 'VSA',
          mode: ActiveRoadColorMode.vsa,
        ),
        buildModeCard(
          label: 'Pavimento',
          mode: ActiveRoadColorMode.surface,
        ),
        buildModeCard(
          label: 'Gerência Regional',
          mode: ActiveRoadColorMode.region,
        ),
      ],
    );
  }
}