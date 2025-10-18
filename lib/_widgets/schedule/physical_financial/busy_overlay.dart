// lib/screens/_pages/physical_financial/widgets/busy_overlay.dart
import 'package:flutter/material.dart';

class PhysFinBusyOverlay extends StatelessWidget {
  final String textWhenBusy;
  final String textWhenSaving;
  final bool saving;
  const PhysFinBusyOverlay({
    super.key,
    this.textWhenBusy = 'Carregando planejamento...',
    this.textWhenSaving = 'Salvando planejamento...',
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = saving ? textWhenSaving : textWhenBusy;
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black38),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(blurRadius: 10, spreadRadius: 1, color: Colors.black26)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                SizedBox(width: 12),
              ],
            ).copyWith(children: [
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 12),
              Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ],
    );
  }
}

extension _RowCopy on Row {
  Row copyWith({List<Widget>? children}) =>
      Row(mainAxisAlignment: mainAxisAlignment, mainAxisSize: mainAxisSize, crossAxisAlignment: crossAxisAlignment, children: children ?? this.children);
}
