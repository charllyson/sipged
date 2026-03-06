import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/print/label_preview_painter.dart';
import 'package:sipged/_widgets/print/label_bitmap.dart';

class PreviewPanel extends StatefulWidget {
  const PreviewPanel({
    super.key,
    required this.larguraMm,
    required this.alturaMm,
    required this.gapMm,
    required this.text,
    required this.qrData,
    required this.cfg,
    this.selectedSection = PreviewSection.none,
    this.onSectionTap,
  });

  final double larguraMm;
  final double alturaMm;
  final double gapMm;

  final String text;
  final String qrData;
  final LabelLayoutConfig cfg;

  final PreviewSection selectedSection;
  final void Function(PreviewSection section)? onSectionTap;

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  LabelPreviewLayout? _lastLayout;
  final GlobalKey _paintKey = GlobalKey();

  ui.Image? _centerLogoMonoRot;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  @override
  void didUpdateWidget(covariant PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cfg.qrCenterAssetPath != widget.cfg.qrCenterAssetPath ||
        oldWidget.cfg.qrCenterMonoThreshold != widget.cfg.qrCenterMonoThreshold ||
        oldWidget.cfg.enableQrCenterImage != widget.cfg.enableQrCenterImage) {
      _loadLogo();
    }
  }

  Future<void> _loadLogo() async {
    final img = await getQrCenterLogoMonoRot(widget.cfg);
    if (!mounted) return;
    setState(() => _centerLogoMonoRot = img);
  }

  @override
  Widget build(BuildContext context) {
    final bg = Colors.black.withValues(alpha: 0.20);
    final stroke = Colors.white.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stroke),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preview', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final paintW = c.maxHeight;
                final paintH = c.maxWidth;

                return Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final layout = _lastLayout;
                      if (layout == null) return;

                      final ctx = _paintKey.currentContext;
                      if (ctx == null) return;

                      final box = ctx.findRenderObject() as RenderBox;
                      final local = box.globalToLocal(d.globalPosition);

                      final section = layout.sectionAt(local);
                      widget.onSectionTap?.call(section);
                    },
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: CustomPaint(
                        key: _paintKey,
                        size: Size(paintW, paintH),
                        painter: LabelPreviewPainter(
                          larguraMm: widget.larguraMm,
                          alturaMm: widget.alturaMm,
                          gapMm: widget.gapMm,
                          text: widget.text,
                          qrData: widget.qrData,
                          cfg: widget.cfg,
                          theme: Theme.of(context),
                          selectedSection: widget.selectedSection,
                          onLayout: (layout) => _lastLayout = layout,
                          centerLogoMonoRot: _centerLogoMonoRot,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _legendDot(color: Colors.white, label: 'Etiqueta'),
              _legendDot(color: Colors.white.withValues(alpha: 0.25), label: 'GAP'),
              _legendDot(color: Colors.lightBlueAccent.withValues(alpha: 0.8), label: 'Área QR'),
              _legendDot(color: Colors.orangeAccent.withValues(alpha: 0.9), label: 'Área Texto'),
              _legendDot(color: Colors.white.withValues(alpha: 0.45), label: 'Padding'),
              _legendDot(color: Colors.amberAccent.withValues(alpha: 0.85), label: 'Seleção'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }
}