import 'package:flutter/material.dart';

class ProgressImportDialog extends StatelessWidget {
  final int total;
  final int current;

  const ProgressImportDialog({
    super.key,
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;

    return AlertDialog(
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text(
              'Salvando $current de $total registros...',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
