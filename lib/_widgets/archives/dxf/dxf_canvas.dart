// lib/_widgets/archives/dxf/widgets/dxf_canvas.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/archives/dxf/dxf_controller.dart';
import 'dxf_selection_overlay.dart';

class DxfCanvas extends StatefulWidget {
  const DxfCanvas({
    super.key,
    required this.controller,
    required this.contentInset,
    this.onScreenScaleChanged,
  });

  final DxfController controller;
  final EdgeInsets contentInset;
  final void Function(double scale)? onScreenScaleChanged;

  @override
  State<DxfCanvas> createState() => _DxfCanvasState();
}

class _DxfCanvasState extends State<DxfCanvas> {
  final _tc = TransformationController();

  @override
  void didUpdateWidget(covariant DxfCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.onScreenScaleChanged?.call(_tc.value.storage[0]);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.image == null || c.sizePx == null) return const SizedBox.shrink();

    return InteractiveViewer(
      transformationController: _tc,
      alignment: Alignment.topLeft,
      constrained: false,
      minScale: 0.2,
      maxScale: 20,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      clipBehavior: Clip.none,
      child: SizedBox(
        width: c.sizePx!.width,
        height: c.sizePx!.height,
        child: Stack(
          children: [
            RawImage(image: c.image),
            // Overlay de seleção DXF
            DxfSelectionOverlay(
              model: c.model,
              pick: c.selectedPick,
              modelToImage: c.modelToImage,
            ),
            // Slot para outras camadas (ex.: polígonos por cima) — use Stack pai
          ],
        ),
      ),
    );
  }
}
