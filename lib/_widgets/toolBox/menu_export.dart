import 'package:flutter/material.dart';
import 'package:sipged/_widgets/toolBox/tool_buttons.dart';
import 'package:sipged/_widgets/toolBox/tool_slot.dart';

/// Argumentos do menu Exportar
class MenuExport {
  final Future<void> Function() exportPng;
  final void Function({required bool normalized}) showGeojsonDialog;
  final VoidCallback deactivateBrushDraw;

  MenuExport({
    required this.exportPng,
    required this.showGeojsonDialog,
    required this.deactivateBrushDraw,
  });
}

ToolSlot buildExportMenu(MenuExport a) {
  return ToolSlot(
    id: 'export',
    icon: Icons.ios_share,
    tooltip: 'Exportar',
    primaryActionId: 'export-png',
    flyout: [
      ToolButtons(
        id: 'export-png',
        icon: Icons.image_outlined,
        tooltip: 'Exportar PNG',
        onTap: () {
          a.deactivateBrushDraw();
          a.exportPng();
        },
      ),
      ToolButtons(
        id: 'export-geojson-norm',
        icon: Icons.data_object,
        tooltip: 'Exportar GeoJSON (normalizado)',
        onTap: () {
          a.deactivateBrushDraw();
          a.showGeojsonDialog(normalized: true);
        },
      ),
      ToolButtons(
        id: 'export-geojson-px',
        icon: Icons.data_array,
        tooltip: 'Exportar GeoJSON (px absolutos)',
        onTap: () {
          a.deactivateBrushDraw();
          a.showGeojsonDialog(normalized: false);
        },
      ),
    ],
    onTapMain: () => a.deactivateBrushDraw(),
  );
}
