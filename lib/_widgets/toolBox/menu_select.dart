import 'package:flutter/material.dart';
import 'package:sipged/_services/files/dxf/dxf_enums.dart';
import 'package:sipged/_widgets/toolBox/tool_buttons.dart';
import 'package:sipged/_widgets/toolBox/tool_slot.dart';

class MenuSelect {
  final SelectionMode current;
  final void Function(SelectionMode mode) setMode;
  final VoidCallback deactivateDraw;
  final VoidCallback activateSelectionMode;
  final VoidCallback? activatePanMode; // novo

  MenuSelect({
    required this.current,
    required this.setMode,
    required this.deactivateDraw,
    required this.activateSelectionMode,
    this.activatePanMode,
  });
}

ToolSlot buildSelectMenu(MenuSelect a) {
  return ToolSlot(
    id: 'select',
    icon: Icons.near_me,
    tooltip: 'Selecionar',
    primaryActionId: 'select-direct',
    flyout: [
      ToolButtons(
        id: 'select-pan',
        icon: Icons.back_hand,
        tooltip: 'Mover (pan)',
        onTap: () {
          a.deactivateDraw();
          a.activatePanMode?.call();
          a.setMode(SelectionMode.direct);
          // no host: _pan = true;
        },
      ),
      ToolButtons(
        id: 'select-direct',
        icon: Icons.near_me,
        tooltip: 'Seleção direta',
        onTap: () {
          a.deactivateDraw();
          a.activateSelectionMode();
          a.setMode(SelectionMode.direct);
          // no host: _pan = false;
        },
      ),
      ToolButtons(
        id: 'select-group',
        icon: Icons.select_all,
        tooltip: 'Selecionar em grupo',
        onTap: () {
          a.deactivateDraw();
          a.activateSelectionMode();
          a.setMode(SelectionMode.group);
        },
      ),
    ],
  );
}
