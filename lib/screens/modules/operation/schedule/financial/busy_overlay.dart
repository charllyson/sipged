import 'package:flutter/material.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';

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
        const ModalBarrier(
          dismissible: false,
          color: Colors.black38,
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  spreadRadius: 1,
                  color: Colors.black26,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingTreeDotsGrey(
                  size: 42,
                  centered: false,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}