import 'package:flutter/material.dart';
import 'package:siged/_widgets/toolBox/tool_dock.dart';
import 'package:siged/_widgets/toolBox/tool_slot.dart';

ToolSlot MenuZoom(VoidCallback onTap) {
  return ToolSlot(
    id: 'zoom',
    icon: Icons.zoom_in_map,
    tooltip: 'Zoom',
    onTapMain: onTap,
  );
}
