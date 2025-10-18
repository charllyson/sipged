// lib/_widgets/toolBox/menuText/menu_text.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/toolBox/menuText/menu_text_enums.dart';
import 'package:siged/_widgets/toolBox/tool_action.dart';
import 'package:siged/_widgets/toolBox/tool_slot.dart';

class MenuText {
  final void Function(TextTool tool) activateTextMode; // avisa o host
  final VoidCallback deactivateBrushDraw;              // garante que o brush pare

  MenuText({
    required this.activateTextMode,
    required this.deactivateBrushDraw,
  });
}

ToolSlot buildTextMenu(MenuText a) {
  return ToolSlot(
    id: 'text',
    icon: Icons.title,
    tooltip: 'Texto',
    primaryActionId: 'text-point',          // <- padrão: Texto (ponto)
    flyout: [
      ToolAction(
        id: 'text-point',
        icon: Icons.title,
        tooltip: 'Ferramenta Texto (ponto)',
        onTap: () { a.deactivateBrushDraw(); a.activateTextMode(TextTool.point); },
      ),
      ToolAction(
        id: 'text-area',
        icon: Icons.crop_square,
        tooltip: 'Ferramenta Texto de área',
        onTap: () { a.deactivateBrushDraw(); a.activateTextMode(TextTool.area); },
      ),
      ToolAction(
        id: 'text-vertical',
        icon: Icons.text_rotate_vertical,
        tooltip: 'Ferramenta Texto vertical',
        onTap: () { a.deactivateBrushDraw(); a.activateTextMode(TextTool.verticalPoint); },
      ),
      ToolAction(
        id: 'text-area-vertical',
        icon: Icons.view_sidebar,
        tooltip: 'Ferramenta Texto de área vertical',
        onTap: () { a.deactivateBrushDraw(); a.activateTextMode(TextTool.verticalArea); },
      ),
      ToolAction(
        id: 'text-mono',
        icon: Icons.keyboard_alt_outlined,
        tooltip: 'Ferramenta Datilografia',
        onTap: () { a.deactivateBrushDraw(); a.activateTextMode(TextTool.monospace); },
      ),
    ],
  );
}

