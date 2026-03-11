import 'package:flutter/material.dart';
import 'package:sipged/_widgets/toolBox/tool_buttons.dart';
import 'package:sipged/_widgets/toolBox/tool_sub_menus.dart';
import 'package:sipged/_widgets/toolBox/tool_slot.dart';

/// Argumentos do menu Definir Área (polígono + snap)
class MenuDrawerPolygon {
  final VoidCallback activatePolygonMode;
  final bool snapEnabled;
  final VoidCallback toggleSnap;
  final SideMenuBuilder snapRadiusBuilder;
  final SideMenuBuilder snapThresholdBuilder;
  final Future<void> Function() finishPolygon;
  final VoidCallback deactivateBrushDraw;

  MenuDrawerPolygon({
    required this.activatePolygonMode,
    required this.snapEnabled,
    required this.toggleSnap,
    required this.snapRadiusBuilder,
    required this.snapThresholdBuilder,
    required this.finishPolygon,
    required this.deactivateBrushDraw,
  });
}

ToolSlot buildAreaMenu(MenuDrawerPolygon a) {
  return ToolSlot(
    id: 'definir-area',
    icon: Icons.draw,
    tooltip: 'Definir Área',
    primaryActionId: 'area-draw',
    flyout: [
      ToolButtons(
        id: 'area-draw',
        icon: Icons.gesture,
        tooltip: 'Desenhar área',
        onTap: () {
          a.deactivateBrushDraw();
          a.activatePolygonMode();
        },
      ),
      ToolButtons(
        id: 'snap-toggle',
        icon: a.snapEnabled ? Icons.push_pin : Icons.push_pin_outlined,
        tooltip: a.snapEnabled ? 'Desligar snap' : 'Ligar snap',
        onTap: () {
          a.deactivateBrushDraw();
          a.toggleSnap();
        },
      ),
      ToolButtons(
        id: 'snap-radius',
        icon: Icons.blur_circular,
        tooltip: 'Raio do snap',
        sideBuilder: a.snapRadiusBuilder,
        sideOpenToLeft: false,
        sideMaxHeight: 260,
      ),
      ToolButtons(
        id: 'snap-threshold',
        icon: Icons.waves,
        tooltip: 'Limiar do snap',
        sideBuilder: a.snapThresholdBuilder,
        sideOpenToLeft: false,
        sideMaxHeight: 260,
      ),
      ToolButtons(
        id: 'finish-poly',
        icon: Icons.done_all,
        tooltip: 'Fechar polígono',
        onTap: () async {                  // 👈 async
          a.deactivateBrushDraw();
          await a.finishPolygon();         // 👈 aguarda
        },
      ),
    ],
    onTapMain: () {
      a.deactivateBrushDraw();
    },
  );
}
