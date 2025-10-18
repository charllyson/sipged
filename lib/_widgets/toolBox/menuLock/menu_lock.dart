import 'package:flutter/material.dart';
import 'package:siged/_widgets/toolBox/tool_slot.dart';

class MenuLock {
  final bool pageScrollLocked;
  final VoidCallback toggleLock;
  final VoidCallback deactivateBrushDraw;

  MenuLock({
    required this.pageScrollLocked,
    required this.toggleLock,
    required this.deactivateBrushDraw,
  });
}

ToolSlot buildLockMenu(MenuLock a) {
  return ToolSlot(
    id: 'lock',
    primaryActionId: 'lock-toggle',
    icon: a.pageScrollLocked ? Icons.lock : Icons.lock_open,
    tooltip: a.pageScrollLocked
        ? 'Bloqueado: sem zoom/rolagem da página'
        : 'Desbloqueado: zoom/rolagem da página',
    onTapMain: () {
      a.deactivateBrushDraw();
      a.toggleLock();
    },
  );
}
