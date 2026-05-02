import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

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

  void _notifyError(String message) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Erro ao exportar',
        subtitle: message,
        status: NotificationStatus.error,
        leadingLabel: 'PDF',
      ),
    );
  }

  Future<void> _export() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final info = await Printing.info();

      if (info.canShare) {
        final bytes = await widget.onBuildPdfBytes();

        await Printing.sharePdf(
          bytes: bytes,
          filename: widget.fileName,
        );

        return;
      }

      await Printing.layoutPdf(
        onLayout: (_) async => widget.onBuildPdfBytes(),
        name: widget.fileName,
      );
    } catch (e) {
      _notifyError('Falha ao exportar PDF: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
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
            ? const LoadingTreeDots(
          size: 20,
          strokeWidth: 2,
          centered: false,
        )
            : Icon(icon),
      ),
    );
  }
}