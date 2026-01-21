// lib/screens/modules/operation/operation/civil/schedule_civil_panel.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/toolBox/tool_widget_controller.dart';

// schedule_civil_panel.dart (exemplo)
class ScheduleCivilPanel extends StatelessWidget {
  const ScheduleCivilPanel({
    super.key,
    required this.title,
    required this.contractId,
    required this.controller,
  });

  final String title;
  final String contractId;
  final ScheduleCivilController controller;

  @override
  Widget build(BuildContext context) {
    return Material( // mantém elevação/tema do painel
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔁 use um header local, não a UpBar global
          _PanelHeader(
            title: title,
            onClose: Navigator.of(context).maybePop,
          ),
          const Divider(height: 1),
          // ... resto do painel
        ],
      ),
    );
  }
}

// Header local minimalista
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.onClose});
  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          IconButton(
            tooltip: 'Fechar painel',
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
