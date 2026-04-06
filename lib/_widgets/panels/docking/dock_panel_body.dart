import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/panels/docking/dock_panel_config.dart';

class DockPanelBody extends StatelessWidget {
  final Widget child;
  final bool isFloating;
  final Color fill;
  final Color borderColor;
  final Color shadowColor;

  const DockPanelBody({
    super.key,
    required this.child,
    required this.isFloating,
    required this.fill,
    required this.borderColor,
    required this.shadowColor,
  });

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: fill,
      borderRadius: DockPanelConfig.panelRadius,
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: isFloating ? 14 : 8,
          offset: Offset(0, isFloating ? 8 : 3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isFloating) {
      return DecoratedBox(
        decoration: _decoration(),
        child: child,
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: DecoratedBox(
          decoration: _decoration(),
          child: child,
        ),
      ),
    );
  }
}