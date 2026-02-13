// lib/_widgets/schedule/civil/dxf_interactive_view.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sipged/_services/files/dxf/dxf_selection_overlay.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

// enums do seu projeto (mantive o import como estava)
import 'package:sipged/_services/files/dxf/dxf_enums.dart';

// util de fit
import 'package:sipged/_widgets/schedule/civil/schedule_civil_fit_utils.dart';

// DXF controller + overlay (camada modularizada)
import 'package:sipged/_services/files/dxf/dxf_controller.dart';
import 'package:sipged/_services/files/dxf/dxf_hit_tester.dart';
import 'package:sipged/_services/files/dxf/dxf_model.dart';

/// View interativa para DXF baseada no DxfController.
/// - Panning/zoom com InteractiveViewer (opcional)
/// - Tap para seleção (SelectionMode.direct) usando hit-test do controller
/// - Overlay azul da entidade selecionada
class DxfInteractiveView extends StatefulWidget {
  const DxfInteractiveView({
    super.key,
    required this.controller,           // ⬅️ agora recebemos o DxfController
    required this.contentInset,
    required this.selectionMode,        // direct | group (só direct aqui)
    this.panEnabled = true,
    this.onSelect,                      // callback da seleção DXF
  });

  final DxfController controller;
  final EdgeInsets contentInset;
  final SelectionMode selectionMode;
  final bool panEnabled;

  /// Notifica quando uma entidade DXF foi selecionada (ou null para limpar)
  final void Function(DxfPick? pick)? onSelect;

  @override
  State<DxfInteractiveView> createState() => _DxfInteractiveViewState();
}

class _DxfInteractiveViewState extends State<DxfInteractiveView> {
  final TransformationController _tc = TransformationController();

  // Fit inicial controlado por insets/viewport
  bool _didFit = false;

  // Conveniências
  ui.Image? get _img => widget.controller.image;
  Size? get _imgSize => widget.controller.sizePx;
  DxfModel? get _model => widget.controller.model;

  double get _screenScale => _tc.value.storage[0]; // m00 (assumindo escala uniforme)

  @override
  void didUpdateWidget(covariant DxfInteractiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se trocar a imagem ou size, refaz o fit
    if (oldWidget.controller.image != widget.controller.image) {
      _didFit = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitIfNeeded());
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitIfNeeded());
  }

  void _fitIfNeeded() {
    if (!mounted || _didFit || _imgSize == null) return;

    // Tenta obter o tamanho do slot onde essa view está (usamos context.size)
    final size = context.size ?? const Size(1, 1);
    final viewportInner = Size(
      (size.width  - widget.contentInset.horizontal).clamp(0.0, double.infinity),
      (size.height - widget.contentInset.vertical).clamp(0.0, double.infinity),
    );

    // Fit centrado da imagem inteira (px → px)
    _tc.value = ScheduleCivilFitUtils.fitToViewportCentered(
      imageSize: _imgSize!,
      viewportInner: viewportInner,
      extraScale: 1.0,
    );
    _didFit = true;
  }

  void _onTapDown(TapDownDetails d) {
    if (widget.selectionMode != SelectionMode.direct) return;
    if (_imgSize == null || _img == null || _model == null) return;

    // Ponto do tap em coordenadas DO WIDGET (pós-padding)
    final local = d.localPosition;

    // InteractiveViewer usa matrix _tc.value no child;
    // para obter o ponto no espaço da IMAGEM (px), aplicamos a inversa:
    final inv = Matrix4.inverted(_tc.value);
    final p4 = inv.transform3(Vector3(local.dx, local.dy, 0));
    final pImage = Offset(p4.x, p4.y); // px da imagem

    // Faz pick pelo controller: converte imagem→modelo internamente e usa hit-test
    final pick = widget.controller.pickAtImage(
      pImage,
      tolPx: 8.0,
      currentScreenScale: _screenScale,
    );

    // Notifica o host
    widget.onSelect?.call(pick);
    setState(() {}); // para redesenhar overlay
  }

  @override
  Widget build(BuildContext context) {
    // Sem imagem ainda
    if (_img == null || _imgSize == null) {
      return const SizedBox.expand(child: ColoredBox(color: Colors.transparent));
    }

    return Padding(
      padding: widget.contentInset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onPanStart: widget.panEnabled ? (_) {} : null,
        child: InteractiveViewer(
          transformationController: _tc,
          alignment: Alignment.topLeft,
          constrained: false,
          minScale: 0.2,
          maxScale: 20,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          clipBehavior: Clip.none,
          child: SizedBox(
            width: _imgSize!.width,
            height: _imgSize!.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // raster DXF (com alpha)
                RawImage(image: _img),

                // overlay da ENTIDADE selecionada (usa MODELO→IMAGEM do controller)
                DxfSelectionOverlay(
                  model: _model,
                  pick: widget.controller.selectedPick,
                  modelToImage: widget.controller.modelToImage,
                  screenScale: _screenScale, // ⬅️ novo
                ),

                // (Opcional) outras camadas podem ser colocadas acima via Stack no host
              ],
            ),
          ),
        ),
      ),
    );
  }
}
