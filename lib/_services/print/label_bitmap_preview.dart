/*
// lib/_widgets/bluetooth/label_bitmap_preview.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:siged/_services/print/label_bitmap.dart';

class LabelBitmapPreview extends StatefulWidget {
  const LabelBitmapPreview({
    super.key,
    required this.larguraMm,
    required this.alturaMm,
    required this.texto,
    required this.qrData,
    this.dpi = 203,
    this.cfg = const LabelLayoutConfig(),
  });

  final double larguraMm;
  final double alturaMm;
  final String texto;
  final String qrData;
  final int dpi;
  final LabelLayoutConfig cfg;

  @override
  State<LabelBitmapPreview> createState() => _LabelBitmapPreviewState();
}

class _LabelBitmapPreviewState extends State<LabelBitmapPreview> {
  Uint8List? _png;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final png = await renderLabelPng(
      larguraMm: widget.larguraMm,
      alturaMm: widget.alturaMm,
      texto: widget.texto,
      qrData: widget.qrData,
      dpi: widget.dpi,
      cfg: widget.cfg,
    );
    if (!mounted) return;
    setState(() => _png = png);
  }

  @override
  Widget build(BuildContext context) {
    final png = _png;
    if (png == null) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pré-visualização (PNG gerado no canvas):'),
        const SizedBox(height: 8),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: Image.memory(
            png,
            gaplessPlayback: true,
            filterQuality: FilterQuality.none, // mantém o “pixel perfeito”
          ),
        ),
      ],
    );
  }
}
*/
