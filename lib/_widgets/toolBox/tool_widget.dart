import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_services/dxf/dxf_enums.dart';

import 'package:siged/_widgets/toolBox/menuAction/menu_actions.dart';
import 'package:siged/_widgets/toolBox/menuDrawerPolygon/menu_drawer_polygon.dart';
import 'package:siged/_widgets/toolBox/menuBrush/menu_brush.dart';
import 'package:siged/_widgets/toolBox/menuExport/menu_export.dart';
import 'package:siged/_widgets/toolBox/menuSelect/menu_select.dart';
import 'package:siged/_widgets/toolBox/menuText/menuText.dart';
import 'package:siged/_widgets/toolBox/menuText/menu_text_enums.dart';
import 'package:siged/_widgets/toolBox/menuZoom/menu_zoom.dart';
import 'menuLock/menu_lock.dart';

import 'package:siged/_widgets/toolBox/tool_dock.dart';
import 'package:siged/_widgets/toolBox/tool_widget_controller.dart';
import 'package:siged/_widgets/toolBox/tool_slot.dart';

typedef ValueSetterInt = void Function(int delta);

class ToolBoxWidget extends StatefulWidget {
  const ToolBoxWidget({
    super.key,
    this.mapController,
    this.onExportPng,
    this.onStrokesChanged,
    this.onStrokesChangedPx,
    this.snapEnabled = false,
    this.snapRadius = 8,
    this.snapMinGradient = 8,
    this.canFinishPolygon = false,
    this.canUndo = false,
    this.canClear = false,
    this.hasSelection = false,
    this.onActivatePolygonMode,
    this.onActivateSelectionMode,
    this.onActivateTextMode,
    this.onActivatePanMode, // novo
    this.onToggleSnap,
    this.onChangeSnapRadius,
    this.onChangeSnapThreshold,
    this.onFinishPolygon,
    this.onUndo,
    this.onClear,
    this.onRenameSelected,
    this.onDeleteSelected,
    this.onEnterTextPoint,
    this.onEnterTextArea,
    this.onEnterTextPath,
    this.onEnterTextVerticalPoint,
    this.onEnterTextVerticalArea,
    this.onEnterTextVerticalPath,
    this.onEnterTypewriter,
    this.textSizeBuilder,
    this.textColorBuilder,
    this.textFontBuilder,
    this.buildGeoJSON,
    this.copyToClipboard,
    this.initialBrushColor = Colors.redAccent,
    this.initialBrushWidth = 4.0,
    this.leftPadding = 12,
    this.topPadding = 12,
    this.panelMaxHeight = 420,
  });

  final MapController? mapController;
  final void Function(Uint8List pngBytes)? onExportPng;
  final void Function(List<List<LatLng>> strokes)? onStrokesChanged;
  final void Function(List<List<Offset>> strokesPx)? onStrokesChangedPx;

  final bool snapEnabled;
  final int snapRadius;
  final int snapMinGradient;
  final bool canFinishPolygon;
  final bool canUndo;
  final bool canClear;
  final bool hasSelection;

  final VoidCallback? onActivatePolygonMode;
  final VoidCallback? onActivateSelectionMode;
  final void Function(TextTool tool)? onActivateTextMode;
  final VoidCallback? onActivatePanMode; // novo

  final VoidCallback? onToggleSnap;
  final ValueSetterInt? onChangeSnapRadius;
  final ValueSetterInt? onChangeSnapThreshold;
  final Future<void> Function()? onFinishPolygon;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;
  final Future<void> Function()? onRenameSelected;
  final VoidCallback? onDeleteSelected;

  final VoidCallback? onEnterTextPoint;
  final VoidCallback? onEnterTextArea;
  final VoidCallback? onEnterTextPath;
  final VoidCallback? onEnterTextVerticalPoint;
  final VoidCallback? onEnterTextVerticalArea;
  final VoidCallback? onEnterTextVerticalPath;
  final VoidCallback? onEnterTypewriter;

  final Widget Function(VoidCallback close)? textSizeBuilder;
  final Widget Function(VoidCallback close)? textColorBuilder;
  final Widget Function(VoidCallback close)? textFontBuilder;

  final String Function(bool normalized)? buildGeoJSON;
  final Future<void> Function(String text)? copyToClipboard;

  final Color initialBrushColor;
  final double initialBrushWidth;

  final double leftPadding;
  final double topPadding;
  final double panelMaxHeight;

  @override
  State<ToolBoxWidget> createState() => _ToolBoxWidgetState();
}

class Stroke {
  Stroke({required this.color, required this.width, required this.screenSpace});
  final bool screenSpace;
  final List<LatLng> geoPoints = [];
  final List<Offset> screenPoints = [];
  final Color color;
  final double width;
}

class _ToolBoxWidgetState extends State<ToolBoxWidget> {
  final _dockCtl = ToolWidgetController();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  StreamSubscription<MapEvent>? _mapSub;

  final ValueNotifier<int> _painterRepaint = ValueNotifier<int>(0);
  final ValueNotifier<int> _drawRepaint = ValueNotifier<int>(0);
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  late Color _brushColor;
  late double _brushWidth;

  bool _brushDrawMode = false;
  bool _panMode = false; // novo

  SelectionMode _selectionMode = SelectionMode.direct;

  int _activePointers = 0;
  bool _passThrough = false;
  bool _pageScrollLocked = false;

  late int _snapRadiusUi;
  late int _snapMinGradUi;

  bool get _hasMap => widget.mapController != null;
  bool get _mapInteractionsEnabled => _hasMap ? !_brushDrawMode : false;

  MapCamera? get _safeCamera {
    if (!_hasMap) return null;
    try { return widget.mapController!.camera; } catch (_) { return null; }
  }

  @override
  void initState() {
    super.initState();
    _brushColor = widget.initialBrushColor;
    _brushWidth = widget.initialBrushWidth;
    _snapRadiusUi = widget.snapRadius;
    _snapMinGradUi = widget.snapMinGradient;
    if (_hasMap) {
      _mapSub = widget.mapController!.mapEventStream.listen((_) => _painterRepaint.value++);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _painterRepaint.value++);
  }

  @override
  void didUpdateWidget(covariant ToolBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapRadius != _snapRadiusUi) _snapRadiusUi = widget.snapRadius;
    if (widget.snapMinGradient != _snapMinGradUi) _snapMinGradUi = widget.snapMinGradient;
  }

  @override
  void dispose() {
    _mapSub?.cancel();
    _painterRepaint.dispose();
    _drawRepaint.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    if (_hasMap) {
      widget.onStrokesChanged?.call(
        _strokes.where((s) => !s.screenSpace).map((s) => List<LatLng>.from(s.geoPoints)).toList(),
      );
    } else {
      widget.onStrokesChangedPx?.call(
        _strokes.where((s) => s.screenSpace).map((s) => List<Offset>.from(s.screenPoints)).toList(),
      );
    }
  }

  static bool _sameLatLng(LatLng a, LatLng b) {
    const eps = 1e-10;
    return (a.latitude - b.latitude).abs() < eps && (a.longitude - b.longitude).abs() < eps;
  }
  static bool _sameOffset(Offset a, Offset b) {
    const eps = 0.1;
    return (a.dx - b.dx).abs() < eps && (a.dy - b.dy).abs() < eps;
  }

  void _endStroke() => _currentStroke = null;

  Future<void> _exportPng() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      widget.onExportPng?.call(byteData.buffer.asUint8List());
    } catch (_) {}
  }

  LatLng? _toLatLng(Offset localPos) {
    final cam = _safeCamera;
    if (cam == null) return null;
    try { return widget.mapController!.camera.screenOffsetToLatLng(localPos); } catch (_) { return null; }
  }

  void _startStroke(Offset localPos) {
    if (!_brushDrawMode) return;
    final latLng = _toLatLng(localPos);
    if (latLng != null) {
      _currentStroke = Stroke(color: _brushColor, width: _brushWidth, screenSpace: false)
        ..geoPoints.add(latLng);
    } else {
      _currentStroke = Stroke(color: _brushColor, width: _brushWidth, screenSpace: true)
        ..screenPoints.add(localPos);
    }
    setState(() => _strokes.add(_currentStroke!));
    _drawRepaint.value++; _notifyChanged();
  }

  void _appendPoint(Offset localPos) {
    if (!_brushDrawMode || _currentStroke == null) return;
    if (_currentStroke!.screenSpace) {
      final pts = _currentStroke!.screenPoints;
      if (pts.isNotEmpty && _sameOffset(pts.last, localPos)) return;
      setState(() => pts.add(localPos));
      _drawRepaint.value++; _notifyChanged();
      return;
    }
    final latLng = _toLatLng(localPos);
    if (latLng == null) return;
    final pts = _currentStroke!.geoPoints;
    if (pts.isNotEmpty && _sameLatLng(pts.last, latLng)) return;
    setState(() => pts.add(latLng));
    _drawRepaint.value++; _notifyChanged();
  }

  void _undoStroke() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _drawRepaint.value++;
    });
    _notifyChanged();
  }

  void _clearStrokes() {
    setState(() {
      _strokes.clear();
      _drawRepaint.value++;
    });
    _notifyChanged();
  }

  void _applyWheelZoom(double dy) {
    final cam = _safeCamera;
    if (cam == null) return;
    final delta = (dy < 0) ? 0.25 : -0.25;
    final nextZoom = (cam.zoom + delta).clamp(3.0, 22.0);
    if (nextZoom != cam.zoom) widget.mapController!.move(cam.center, nextZoom.toDouble(), id: 'wheel');
  }

  Widget _buildColorMenu(VoidCallback close) {
    final colors = <Color>[
      Colors.redAccent, Colors.orangeAccent, Colors.amber, Colors.green,
      Colors.cyan, Colors.blueAccent, Colors.purpleAccent, Colors.white, Colors.black,
    ];
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          for (final c in colors)
            GestureDetector(
              onTap: () { setState(() => _brushColor = c); close(); },
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: c, shape: BoxShape.circle,
                  border: Border.all(
                    color: c.computeLuminance() < 0.5 ? Colors.white70 : Colors.black26,
                    width: _brushColor == c ? 2.2 : 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWidthMenu(VoidCallback close) {
    const double kMin = 1, kMax = 20; const int kDiv = 19;
    return StatefulBuilder(builder: (context, setLocal) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_brushWidth.clamp(kMin, kMax).toStringAsFixed(0)} px',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180, width: 48,
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: _brushWidth.clamp(kMin, kMax),
                  min: kMin, max: kMax, divisions: kDiv,
                  onChanged: (v) { setState(() => _brushWidth = v); setLocal(() {}); },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 40, height: (_brushWidth).clamp(kMin, kMax),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF6E6E6E)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSnapRadiusMenu(VoidCallback close) {
    const int minR = 1, maxR = 64;
    return StatefulBuilder(builder: (context, setLocal) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_snapRadiusUi px',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180, width: 48,
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: _snapRadiusUi.toDouble().clamp(minR.toDouble(), maxR.toDouble()),
                  min: minR.toDouble(), max: maxR.toDouble(),
                  divisions: maxR - minR,
                  onChanged: (v) {
                    final next = v.round();
                    final delta = next - _snapRadiusUi;
                    _snapRadiusUi = next; setLocal(() {});
                    widget.onChangeSnapRadius?.call(delta);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSnapThresholdMenu(VoidCallback close) {
    const int minT = 1, maxT = 64;
    return StatefulBuilder(builder: (context, setLocal) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_snapMinGradUi',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180, width: 48,
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: _snapMinGradUi.toDouble().clamp(minT.toDouble(), maxT.toDouble()),
                  min: minT.toDouble(), max: maxT.toDouble(),
                  divisions: maxT - minT,
                  onChanged: (v) {
                    final next = v.round();
                    final delta = next - _snapMinGradUi;
                    _snapMinGradUi = next; setLocal(() {});
                    widget.onChangeSnapThreshold?.call(delta);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showExportDialog({required bool normalized}) {
    final builder = widget.buildGeoJSON;
    if (builder == null) return;
    final json = builder(normalized);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('GeoJSON (${normalized ? "normalizado" : "px absolutos"})'),
        content: SingleChildScrollView(child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace'))),
        actions: [
          TextButton(onPressed: () async => await widget.copyToClipboard?.call(json), child: const Text('Copiar')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shouldIgnoreOverlay = !_brushDrawMode || _passThrough || _mapInteractionsEnabled || _panMode;
    final cam = _safeCamera;

    final slots = <ToolSlot>[
      buildSelectMenu(
        MenuSelect(
          current: _selectionMode,
          setMode: (m) => setState(() { _selectionMode = m; _panMode = false; }),
          deactivateDraw: () => setState(() => _brushDrawMode = false),
          activateSelectionMode: () {
            setState(() => _panMode = false);
            widget.onActivateSelectionMode?.call();
          },
          activatePanMode: () {
            setState(() { _brushDrawMode = false; _panMode = true; });
            widget.onActivatePanMode?.call();
          },
        ),
      ),
      buildBrushMenu(
        MenuBrush(
          activateBrushDraw: () => setState(() { _panMode = false; _brushDrawMode = true; }),
          colorBuilder: _buildColorMenu,
          widthBuilder: _buildWidthMenu,
        ),
      ),
      buildTextMenu(
        MenuText(
          deactivateBrushDraw: () => setState(() { _brushDrawMode = false; _panMode = false; }),
          activateTextMode: (tool) { setState(() => _panMode = false); widget.onActivateTextMode?.call(tool); },
        ),
      ),
      buildAreaMenu(
        MenuDrawerPolygon(
          activatePolygonMode: () { setState(() => _panMode = false); widget.onActivatePolygonMode?.call(); },
          snapEnabled: widget.snapEnabled,
          toggleSnap: () => widget.onToggleSnap?.call(),
          snapRadiusBuilder: _buildSnapRadiusMenu,
          snapThresholdBuilder: _buildSnapThresholdMenu,
          finishPolygon: () async => await widget.onFinishPolygon?.call(),
          deactivateBrushDraw: () => setState(() { _brushDrawMode = false; _panMode = false; }),
        ),
      ),
      buildActionsMenu(
        MenuActions(
          undoUnified: () {
            if (widget.onUndo != null) { WidgetsBinding.instance.addPostFrameCallback((_) => widget.onUndo!.call()); }
            if (_strokes.isNotEmpty) _undoStroke();
          },
          clearBrushOnly: _clearStrokes,
          clearAll: () => widget.onClear != null ? widget.onClear!() : _clearStrokes(),
          deactivateBrushDraw: () => setState(() { _brushDrawMode = false; _panMode = false; }),
        ),
      ),
      buildExportMenu(
        MenuExport(
          exportPng: _exportPng,
          showGeojsonDialog: ({required normalized}) => _showExportDialog(normalized: normalized),
          deactivateBrushDraw: () => setState(() { _brushDrawMode = false; _panMode = false; }),
        ),
      ),
      MenuZoom(() => setState(() { _brushDrawMode = false; _panMode = false; })),
      buildLockMenu(
        MenuLock(
          pageScrollLocked: _pageScrollLocked,
          toggleLock: () => setState(() => _pageScrollLocked = !_pageScrollLocked),
          deactivateBrushDraw: () => setState(() { _brushDrawMode = false; _panMode = false; }),
        ),
      ),
    ];

    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Stack(
        children: [
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
                    final isPrimary = e.kind == PointerDeviceKind.touch ||
                        (e.kind == PointerDeviceKind.mouse && e.buttons == kPrimaryMouseButton);
                    if (_activePointers == 1 && !_passThrough && isPrimary) _startStroke(e.localPosition);
                  },
                  onPointerMove: (e) { if (_activePointers == 1 && !_passThrough) _appendPoint(e.localPosition); },
                  onPointerUp: (e) { _activePointers = (_activePointers - 1).clamp(0, 10); if (_activePointers == 0) _endStroke(); },
                  onPointerCancel: (e) { _activePointers = (_activePointers - 1).clamp(0, 10); if (_activePointers == 0) _endStroke(); },
                  onPointerSignal: (signal) {
                    if (signal is PointerScrollEvent) {
                      if (_pageScrollLocked) return;
                      if (_mapInteractionsEnabled) _applyWheelZoom(signal.scrollDelta.dy);
                    }
                  },
                  child: CustomPaint(
                    painter: _StrokesPainter(
                      strokes: _strokes,
                      camera: cam,
                      repaint: Listenable.merge([_painterRepaint, _drawRepaint]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: widget.topPadding,
            left: widget.leftPadding,
            child: ToolDock(
              controller: _dockCtl,
              side: AIDockSide.left,
              slots: slots,
              onBeforeOpenMenu: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter({required this.strokes, required this.camera, Listenable? repaint})
      : super(repaint: repaint);
  final List<Stroke> strokes;
  final MapCamera? camera;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final int n = s.screenSpace ? s.screenPoints.length : s.geoPoints.length;
      if (n < 2) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width
        ..color = s.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      final path = ui.Path();
      Offset? last;
      if (s.screenSpace) {
        for (final o in s.screenPoints) { if (last == null) { path.moveTo(o.dx, o.dy); } else { path.lineTo(o.dx, o.dy); } last = o; }
      } else {
        if (camera == null) continue;
        for (final latLng in s.geoPoints) {
          final o = camera!.latLngToScreenOffset(latLng);
          if (last == null) { path.moveTo(o.dx, o.dy); } else { path.lineTo(o.dx, o.dy); }
          last = o;
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter old) => false;
}
