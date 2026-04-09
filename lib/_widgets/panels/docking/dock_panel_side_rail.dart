import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_config.dart';

class DockPanelSideRail extends StatelessWidget {
  final DockArea side;
  final List<DockPanelData> groups;
  final ValueChanged<String> onGroupTap;

  final bool standalone;

  const DockPanelSideRail({
    super.key,
    required this.side,
    required this.groups,
    required this.onGroupTap,
    this.standalone = false,
  });

  bool get _isLeft => side == DockArea.left;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: _isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          width: DockPanelConfig.sideRailWidth,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: groups.map((group) {
                      final accent =
                          group.accentColor ?? theme.colorScheme.primary;
                      final icon = group.icon ?? Icons.dashboard_outlined;

                      final chipBackground = isDark
                          ? accent.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.92);

                      final chipBorder = accent.withValues(alpha: 0.22);

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: standalone ? 3 : 5,
                          vertical: 4,
                        ),
                        child: Tooltip(
                          message: group.title,
                          child: BasicCard(
                            isDark: isDark,
                            onTap: () => onGroupTap(group.id),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            useGlassEffect: true,
                            blurSigmaX: 8,
                            blurSigmaY: 8,
                            backgroundColor: chipBackground,
                            borderColor: chipBorder,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                accent.withValues(alpha: isDark ? 0.14 : 0.08),
                                accent.withValues(alpha: isDark ? 0.05 : 0.02),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.10 : 0.04,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            borderRadius: 10,
                            child: SizedBox(
                              width: 30,
                              child: Column(
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: accent,
                                  ),
                                  const SizedBox(height: 8),
                                  RotatedBox(
                                    quarterTurns: 3,
                                    child: Text(
                                      group.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}