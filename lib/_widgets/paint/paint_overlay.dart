// lib/_widgets/paint/paint_overlay.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'paint_tool_dock.dart';

class PaintOverlay extends StatefulWidget {
  const PaintOverlay({
    super.key,
    required this.mapController,
    this.onExportPng,
    this.onStrokesChanged,
    this.initialBrushColor = Colors.redAccent,
    this.initialBrushWidth = 4.0,
  });

  final MapController mapController;
  final void Function(Uint8List pngBytes)? onExportPng;
  final void Function(List<List<LatLng>> strokes)? onStrokesChanged;
  final Color initialBrushColor;
  final double initialBrushWidth;

  @override
  State<PaintOverlay> createState() => _PaintOverlayState();
}

class Stroke {
  Stroke({required this.points, required this.color, required this.width});
  final List<LatLng> points;
  final Color color;
  final double width;
}

class _PaintOverlayState extends State<PaintOverlay> {
  final ValueNotifier<int> _painterRepaint = ValueNotifier<int>(0);
  final ValueNotifier<int> _drawRepaint = ValueNotifier<int>(0);
  final ValueNotifier<int> _toolUiRepaint = ValueNotifier<int>(0);

  StreamSubscription<MapEvent>? _mapSub;

  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;

  late Color _brushColor;
  late double _brushWidth;

  /// true = desenhar (mapa travado); false = mover/zoomar mapa (liberado)
  bool _drawMode = true;

  int _activePointers = 0;
  bool _passThrough = false;

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  bool get _mapInteractionsEnabled => !_drawMode;

  @override
  void initState() {
    super.initState();
    _brushColor = widget.initialBrushColor;
    _brushWidth = widget.initialBrushWidth;

    _mapSub = widget.mapController.mapEventStream.listen((_) {
      _painterRepaint.value++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _painterRepaint.value++;
    });
  }

  @override
  void dispose() {
    _mapSub?.cancel();
    _painterRepaint.dispose();
    _drawRepaint.dispose();
    _toolUiRepaint.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onStrokesChanged?.call(
      _strokes.map((s) => List<LatLng>.from(s.points)).toList(),
    );
  }

  static bool _sameLatLng(LatLng a, LatLng b) {
    const eps = 1e-10;
    return (a.latitude - b.latitude).abs() < eps &&
        (a.longitude - b.longitude).abs() < eps;
  }

  void _endStroke() => _currentStroke = null;

  Future<void> exportPng() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      widget.onExportPng?.call(byteData.buffer.asUint8List());
    } catch (_) {}
  }

  LatLng? _toLatLng(Offset localPos) {
    try {
      // v8: usa diretamente Offset <-> LatLng
      return widget.mapController.camera.screenOffsetToLatLng(localPos);
    } catch (_) {
      return null;
    }
  }

  void _startStroke(Offset localPos) {
    final latLng = _toLatLng(localPos);
    if (latLng == null) return;
    _currentStroke =
        Stroke(points: [latLng], color: _brushColor, width: _brushWidth);
    setState(() => _strokes.add(_currentStroke!));
    _drawRepaint.value++;
    _notifyChanged();
  }

  void _appendPoint(Offset localPos) {
    final latLng = _toLatLng(localPos);
    if (latLng == null || _currentStroke == null) return;
    final pts = _currentStroke!.points;
    if (pts.isNotEmpty && _sameLatLng(pts.last, latLng)) return;
    setState(() => pts.add(latLng));
    _drawRepaint.value++;
    _notifyChanged();
  }

  void _applyWheelZoom(double dy) {
    final current = widget.mapController.camera;
    final delta = (dy < 0) ? 0.25 : -0.25;
    final nextZoom = (current.zoom + delta).clamp(3.0, 22.0);
    if (nextZoom != current.zoom) {
      widget.mapController.move(current.center, nextZoom.toDouble(), id: 'wheel');
    }
  }

  // === Painéis ===

  Widget _brushPanel(VoidCallback close) {
    final palette = <Color>[
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.amber,
      Colors.green,
      Colors.cyan,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.white,
      Colors.black,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pincel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in palette)
              GestureDetector(
                onTap: () {
                  setState(() => _brushColor = c);
                  _toolUiRepaint.value++;
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.computeLuminance() < 0.5
                          ? Colors.white70
                          : Colors.black26,
                      width: _brushColor == c ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Espessura', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Slider(
          value: _brushWidth.clamp(1, 20),
          min: 1,
          max: 20,
          divisions: 19,
          label: _brushWidth.toStringAsFixed(0),
          onChanged: (v) {
            setState(() => _brushWidth = v);
            _toolUiRepaint.value++;
          },
        ),
      ],
    );
  }

  Widget _actionsRailPanel(VoidCallback close) {
    const btnSize = 40.0;
    Widget icon(IconData data) => Icon(data, size: 20, color: Colors.white);

    Widget button({
      required String tip,
      required IconData iconData,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: tip,
          child: InkResponse(
            onTap: onTap,
            radius: btnSize / 2 + 6,
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Container(
              width: btnSize,
              height: btnSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white30),
              ),
              child: icon(iconData),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          tip: 'Desfazer',
          iconData: Icons.undo,
          onTap: () {
            if (_strokes.isNotEmpty) {
              setState(() => _strokes.removeLast());
              _drawRepaint.value++;
              _notifyChanged();
            }
          },
        ),
        button(
          tip: 'Limpar',
          iconData: Icons.delete_outline,
          onTap: () {
            if (_strokes.isNotEmpty) {
              setState(() => _strokes.clear());
              _drawRepaint.value++;
              _notifyChanged();
            }
          },
        ),
        button(
          tip: 'Exportar PNG',
          iconData: Icons.download,
          onTap: () async => await exportPng(),
        ),
      ],
    );
  }

  Widget _zoomPanel(VoidCallback close) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Zoom', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: 'Mais zoom',
              onPressed: () {
                final cam = widget.mapController.camera;
                widget.mapController.move(
                  cam.center,
                  (cam.zoom + 0.5).toDouble(),
                  id: 'btn+',
                );
              },
              icon: const Icon(Icons.zoom_in),
            ),
            IconButton(
              tooltip: 'Menos zoom',
              onPressed: () {
                final cam = widget.mapController.camera;
                widget.mapController.move(
                  cam.center,
                  (cam.zoom - 0.5).toDouble(),
                  id: 'btn-',
                );
              },
              icon: const Icon(Icons.zoom_out),
            ),
          ],
        ),
      ],
    );
  }

  Widget _lockPanel(VoidCallback close) {
    final bool locked = !_drawMode; // bloqueado => mover/zoomar mapa
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Travar edição', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                locked ? 'Bloqueado' : 'Desbloqueado',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch.adaptive(
              value: locked,
              onChanged: (v) {
                setState(() => _drawMode = !v); // v=true => trava (libera mapa)
                _toolUiRepaint.value++;
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Bloqueando a edição o mapa pode ser arrastado/zoomado livremente',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shouldIgnoreOverlay = _mapInteractionsEnabled || _passThrough;
    final locked = !_drawMode;

    final groups = <ToolGroup>[
      ToolGroup(
        id: 'brush',
        icon: Icons.brush,
        tooltip: 'Pincel (cor/espessura)',
        panelBuilder: _brushPanel,
        preferredPanelWidth: 180,
        useIntrinsicWidth: true,
      ),
      ToolGroup(
        id: 'actions',
        icon: Icons.layers,
        tooltip: 'Ações do desenho',
        panelBuilder: _actionsRailPanel,
        preferredPanelWidth: 56,
        useIntrinsicWidth: false,
        panelPadding: const EdgeInsets.all(6),
      ),
      ToolGroup(
        id: 'zoom',
        icon: Icons.zoom_in_map,
        tooltip: 'Zoom',
        panelBuilder: _zoomPanel,
        preferredPanelWidth: 180,
        useIntrinsicWidth: true,
      ),
      ToolGroup(
        id: 'lock',
        icon: _drawMode ? Icons.lock : Icons.lock_open,
        tooltip: _drawMode ? 'Desbloqueado: desenhar' : 'Bloqueado: mover mapa',
        panelBuilder: _lockPanel,
        preferredPanelWidth: 220,
        useIntrinsicWidth: true,
        // destaque vermelho quando TRAVADO
        iconColor: !locked ? Colors.redAccent : null,
        borderColor: !locked ? Colors.redAccent : null,
        sizeborder: !locked ? 2.5 : 1,
        menuBackground: !locked ? Colors.white70 : null,
      ),
    ];

    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Stack(
        children: [
          // camada de desenho
          Positioned.fill(
            child: GestureDetector(
              onLongPressStart: (_) => setState(() => _passThrough = _mapInteractionsEnabled),
              onLongPressEnd:   (_) => setState(() => _passThrough = false),
              onSecondaryTapDown: (_) => setState(() => _passThrough = _mapInteractionsEnabled),
              onSecondaryTapUp:   (_) => setState(() => _passThrough = false),
              behavior: HitTestBehavior.translucent,
              child: IgnorePointer(
                ignoring: shouldIgnoreOverlay,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    _activePointers++;
                    final primary =
                        e.kind == PointerDeviceKind.touch ||
                            (e.kind == PointerDeviceKind.mouse &&
                                e.buttons == kPrimaryMouseButton);

                    if (_drawMode &&
                        _activePointers == 1 &&
                        !_passThrough &&
                        primary) {
                      _startStroke(e.localPosition);
                    }
                  },
                  onPointerMove: (e) {
                    if (_drawMode && _activePointers == 1 && !_passThrough) {
                      _appendPoint(e.localPosition);
                    }
                  },
                  onPointerUp: (e) {
                    _activePointers = (_activePointers - 1).clamp(0, 10);
                    if (_drawMode && _activePointers == 0) _endStroke();
                  },
                  onPointerCancel: (e) {
                    _activePointers = (_activePointers - 1).clamp(0, 10);
                    if (_drawMode && _activePointers == 0) _endStroke();
                  },
                  onPointerSignal: (signal) {
                    if (_mapInteractionsEnabled && signal is PointerScrollEvent) {
                      _applyWheelZoom(signal.scrollDelta.dy);
                    }
                  },
                  child: CustomPaint(
                    painter: StrokesPainter(
                      strokes: _strokes,
                      camera: widget.mapController.camera,
                      repaint: Listenable.merge([_painterRepaint, _drawRepaint]),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dock
          Positioned(
            top: 12,
            right: 12,
            child: PaintToolDock(
              groups: groups,
              side: DockSide.right,
              panelWidth: 240,
              panelMaxHeight: 420,
              panelRepaint: _toolUiRepaint,
              cascadeGap: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class StrokesPainter extends CustomPainter {
  StrokesPainter({
    required this.strokes,
    required this.camera,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final List<Stroke> strokes;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.length < 2) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width
        ..color = s.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      final path = ui.Path();
      Offset? last;

      for (final latLng in s.points) {
        // v8: converte LatLng -> Offset de tela
        final o = camera.latLngToScreenOffset(latLng);
        if (last == null) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
        last = o;
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokesPainter oldDelegate) => false;
}
