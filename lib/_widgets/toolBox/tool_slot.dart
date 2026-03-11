import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/toolBox/tool_buttons.dart';

class ToolSlot {
  final String id;
  final IconData icon;
  final String tooltip;
  final List<ToolButtons> flyout;
  final String? primaryActionId;      // <- qual ação é a principal
  final VoidCallback? onTapMain;      // fallback opcional

  ToolSlot({
    required this.id,
    required this.icon,
    required this.tooltip,
    this.flyout = const [],
    this.primaryActionId,
    this.onTapMain,
  });
}

