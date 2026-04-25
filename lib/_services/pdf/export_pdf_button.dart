import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';

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
        final bytes = await widget.onBuildPdfBytes();
        await Printing.sharePdf(bytes: bytes, filename: widget.fileName);
      } else if (info.canPrint) {
        await Printing.layoutPdf(
          onLayout: (format) async => await widget.onBuildPdfBytes(),
          name: widget.fileName,
        );
      } else {
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
            ? const LoadingTreeDotsGrey(
          size: 20,
          strokeWidth: 2,
          centered: false,
        )
            : Icon(icon),
      ),
    );
  }
}