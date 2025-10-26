// lib/_widgets/export/export_pdf_button.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class ExportPdfButton extends StatefulWidget {
  const ExportPdfButton({
    super.key,
    required this.onBuildPdfBytes,
    this.fileName = 'relatorio.pdf',
    this.icon,
    this.tooltip = 'Exportar PDF',
  });

  final Future<Uint8List> Function() onBuildPdfBytes;
  final String fileName;
  final IconData? icon;
  final String tooltip;

  @override
  State<ExportPdfButton> createState() => _ExportPdfButtonState();
}

class _ExportPdfButtonState extends State<ExportPdfButton> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final info = await Printing.info();

      if (info.canShare) {
        // iOS/Android/Desktop -> compartilha/salva
        final bytes = await widget.onBuildPdfBytes();
        await Printing.sharePdf(bytes: bytes, filename: widget.fileName);
      } else if (info.canPrint) {
        // Web (e alguns desktops) -> abre diálogo de impressão/salvar como PDF
        await Printing.layoutPdf(
          onLayout: (format) async => await widget.onBuildPdfBytes(),
          name: widget.fileName,
        );
      } else {
        // Fallback simples: tenta abrir o preview
        await Printing.layoutPdf(
          onLayout: (format) async => await widget.onBuildPdfBytes(),
          name: widget.fileName,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon ?? Icons.picture_as_pdf_outlined;

    return Tooltip(
      message: widget.tooltip,
      child: IconButton(
        onPressed: _busy ? null : _export,
        icon: _busy
            ? const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Icon(icon),
      ),
    );
  }
}
