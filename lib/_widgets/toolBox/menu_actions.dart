import 'package:flutter/material.dart';
import 'package:sipged/_widgets/toolBox/tool_buttons.dart';
import 'package:sipged/_widgets/toolBox/tool_slot.dart';

/// Argumentos do menu Ações (desfazer/limpar)
class MenuActions {
  final VoidCallback undoUnified;     // desfaz polígono (host) e, se preciso, brush (fallback)
  final VoidCallback clearBrushOnly;  // limpa só os strokes do pincel
  final VoidCallback clearAll;        // limpa tudo (polígonos + brush)
  final VoidCallback deactivateBrushDraw;

  MenuActions({
    required this.undoUnified,
    required this.clearBrushOnly,
    required this.clearAll,
    required this.deactivateBrushDraw,
  });
}

ToolSlot buildActionsMenu(MenuActions a) {
  return ToolSlot(
    id: 'actions',
    icon: Icons.build,
    tooltip: 'Ações',
    primaryActionId: 'undo',
    flyout: [
      ToolButtons(
        id: 'undo',
        icon: Icons.undo,
        tooltip: 'Desfazer',
        onTap: () {
          a.deactivateBrushDraw();
          a.undoUnified();
        },
      ),
      ToolButtons(
        id: 'clear-draw',
        icon: Icons.auto_fix_normal,
        tooltip: 'Limpar desenho',
        onTap: () {
          a.deactivateBrushDraw();
          a.clearBrushOnly();
        },
      ),
      ToolButtons(
        id: 'clear',
        icon: Icons.clear_all,
        tooltip: 'Limpar',
        onTap: () {
          a.deactivateBrushDraw();
          a.clearAll();
        },
      ),
    ],
    onTapMain: () => a.deactivateBrushDraw(),
  );
}
