import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/docking/dock_panel_config.dart';

class DockPanelBody extends StatelessWidget {
  final Widget child;
  final bool isFloating;
  final Color fill;
  final Color borderColor;
  final Color shadowColor;

  const DockPanelBody({super.key,
    required this.child,
    required this.isFloating,
    required this.fill,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFloating) {
      return Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: DockPanelConfig.panelRadius,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: DockPanelConfig.panelRadius,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
