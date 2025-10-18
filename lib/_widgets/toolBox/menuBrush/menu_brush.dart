import 'package:flutter/material.dart';
import 'package:siged/_widgets/toolBox/tool_action.dart';
import 'package:siged/_widgets/toolBox/tool_sub_menus.dart';
import 'package:siged/_widgets/toolBox/tool_slot.dart';

/// Argumentos do menu Pincel
class MenuBrush {
  final VoidCallback activateBrushDraw; // ativa o modo desenho livre
  final SideMenuBuilder colorBuilder;
  final SideMenuBuilder widthBuilder;

  MenuBrush({
    required this.activateBrushDraw,
    required this.colorBuilder,
    required this.widthBuilder,
  });
}

ToolSlot buildBrushMenu(MenuBrush a) {
  return ToolSlot(
    id: 'brush',
    icon: Icons.brush_outlined,
    tooltip: 'Pincel',
    primaryActionId: 'brush-draw',          // ação principal por padrão
    flyout: [
      ToolAction(
        id: 'brush-draw',
        icon: Icons.brush_outlined,
        tooltip: 'Desenhar livre',
        onTap: a.activateBrushDraw,         // <- ativa o modo pincel
      ),
      ToolAction(
        id: 'brush-color',
        icon: Icons.color_lens_outlined,
        tooltip: 'Cor',
        sideBuilder: a.colorBuilder,        // submenu lateral
      ),
      ToolAction(
        id: 'brush-width',
        icon: Icons.straighten,
        tooltip: 'Largura',
        sideBuilder: a.widthBuilder,        // submenu lateral
      ),
    ],
  );
}
