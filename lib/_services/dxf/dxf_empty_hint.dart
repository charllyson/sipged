// Placeholder (ícone clicável)
import 'package:flutter/material.dart';

class DxfPdfEmptyHint extends StatelessWidget {
  const DxfPdfEmptyHint({
    super.key,
    this.onPickFile});
  final Future<void> Function()? onPickFile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          onTap: onPickFile,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.insert_drive_file, size: 72),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Nenhum DXF selecionado', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        const Text(
          'Clique no ícone acima e escolha um arquivo DXF para visualizar e criar seu cronograma.',
          style: TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}
