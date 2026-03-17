import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';
import 'package:sipged/_widgets/buttons/color_mode_card.dart';

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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ColorModeCard(
          label: 'Padrão',
          selected: selectedMode == ActiveRoadColorMode.defaultColor,
          isDark: isDark,
          onTap: () => onChanged(ActiveRoadColorMode.defaultColor),
        ),
        ColorModeCard(
          label: 'VSA',
          selected: selectedMode == ActiveRoadColorMode.vsa,
          isDark: isDark,
          onTap: () => onChanged(ActiveRoadColorMode.vsa),
        ),
        ColorModeCard(
          label: 'Pavimento',
          selected: selectedMode == ActiveRoadColorMode.surface,
          isDark: isDark,
          onTap: () => onChanged(ActiveRoadColorMode.surface),
        ),
        ColorModeCard(
          label: 'Gerência Regional',
          selected: selectedMode == ActiveRoadColorMode.region,
          isDark: isDark,
          onTap: () => onChanged(ActiveRoadColorMode.region),
        ),
      ],
    );
  }
}