import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_services/files/dxf/dxf_selection_overlay.dart';
import 'package:siged/_widgets/input/in_line_text_box.dart';

// Base/UI
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/schedule/modal/type.dart';
import 'package:siged/_widgets/toolBox/tool_widget_controller.dart';

// Modal unificado + tipos
import 'package:siged/screens/modules/operation/schedule/physical/road/schedule_modal_square.dart';

// Civil (render e UI)
import 'package:siged/_services/files/dxf/dxf_empty_hint.dart';
import 'package:siged/_widgets/schedule/civil/schedule_civil_board.dart';
import 'package:siged/_widgets/schedule/civil/schedule_civil_fit_utils.dart';
import 'package:siged/_services/files/dxf/dxf_enums.dart';
import 'package:siged/_widgets/toolBox/menuDrawerPolygon/menu_drawer_polygon_painter.dart';
import 'package:siged/_widgets/toolBox/menuDrawerPolygon/snap_utils.dart';
import 'package:siged/_widgets/toolBox/menuText/menu_text_enums.dart';

// Domínio
import 'package:siged/_widgets/schedule/linear/schedule_status.dart';
import 'package:siged/_widgets/images/carousel/carousel_metadata.dart' as pm;

// BLoC/Auth
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siged/_blocs/modules/operation/operation/civil/civil_schedule_bloc.dart';
import 'package:siged/_blocs/modules/operation/operation/civil/civil_schedule_event.dart';
import 'package:siged/_blocs/modules/operation/operation/civil/civil_schedule_state.dart';

// Storage
import 'package:firebase_storage/firebase_storage.dart';

// DXF modular
import 'package:siged/_services/files/dxf/dxf_controller.dart';
import 'package:siged/_services/files/dxf/dxf_to_geo.dart';

// ✅ notificações ricas
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ScheduleCivilWidget extends StatefulWidget {
  const ScheduleCivilWidget({
    super.key,
    required this.title,
    required this.controller,
    this.initialPdfBytes,          // mantém o nome por compatibilidade, agora é DXF
    this.pageNumber = 1,           // ignorado (só DXF)
    this.allowPickNewPdf = true,   // controla o botão “Trocar DXF”
    this.onPolylinesReady
  });

  final String title;
  final Uint8List? initialPdfBytes; // <- use como DXF
  final int pageNumber;             // <- ignorado
  final bool allowPickNewPdf;
  final ScheduleCivilController controller;
  final void Function(List<List<LatLng>> polylines)? onPolylinesReady;

  @override
  State<ScheduleCivilWidget> createState() => _ScheduleCivilWidgetState();
}

class _ScheduleCivilWidgetState extends State<ScheduleCivilWidget> {
  // Transform/viewport (aplicado sobre a imagem DXF)
  final TransformationController _tc = TransformationController();
  final GlobalKey _viewerKey = GlobalKey();

  // DXF controller (novo)
  final DxfController _dxf = DxfController();

  // Fonte (apenas DXF)
  Uint8List? _docBytes;

  // Estados
  bool _loading = false;
  Object? _error;

  bool _blocking = false;
  String _blockingMsg = 'Carregando…';
  void _setBlocking(bool on, {String? msg}) {
    if (!mounted) return;
    setState(() {
      _blocking = on;
      if (msg != null) _blockingMsg = msg;
    });
  }

  // Hover / “seleção de linha” (feedback por pixel)
  Offset? _hoverSnap;
  Offset? _selectedEdge;

  // Texto inline
  int? _editingTextIndex;
  Offset? _editingAnchor;
  final _textEditCtrl = TextEditingController();
  final _textEditFocus = FocusNode();

  // FIT
  bool _didFitViewport = false;
  EdgeInsets _lastInset = EdgeInsets.zero;
  Size _lastViewport = Size.zero;

  final double _dxfHairlinePx = 0.9;

  // Props locais por polígono
  final Map<int, Map<String, dynamic>> _polyProps = {};
  Map<String, dynamic> _propsForIndex(int idx) => _polyProps[idx] ??= {};

  // CIVIL BACKEND
  final Map<int, String> _polygonIdByIndex = {};
  int _lastFeatureCount = 0;
  bool _savingNewFeature = false;
  bool _hydrating = false;
  String? _lastAssetUrl;

  // AUTH
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ====== STATUS/Cores ======
  ScheduleStatus _statusFromKey(String? s) {
    final t = (s ?? '').toLowerCase();
    if (t.contains('conclu')) return ScheduleStatus.concluido;
    if (t.contains('andament') || t.contains('progress')) return ScheduleStatus.emAndamento;
    return ScheduleStatus.aIniciar;
  }

  ScheduleStatus _statusFromProgress(double? p) {
    if (p == null) return ScheduleStatus.aIniciar;
    if (p >= 100) return ScheduleStatus.concluido;
    if (p <= 0) return ScheduleStatus.aIniciar;
    return ScheduleStatus.emAndamento;
  }

  Color _statusBaseColor(ScheduleStatus st) {
    switch (st) {
      case ScheduleStatus.concluido:   return const Color(0xFF34A853);
      case ScheduleStatus.emAndamento: return const Color(0xFFF39C12);
      case ScheduleStatus.aIniciar:    return const Color(0xFF9CA3AF);
    }
  }

  Color _polyColorForIndex(int i, {double s = 0.85, double v = 0.95}) {
    final props = _propsForIndex(i);
    final prog = (props['progress'] is num) ? (props['progress'] as num).toDouble() : null;
    final status = (props['status'] != null)
        ? _statusFromKey(props['status'] as String?)
        : _statusFromProgress(prog);

    final base = _statusBaseColor(status);
    final double alpha = switch (status) {
      ScheduleStatus.concluido => 0.32,
      ScheduleStatus.emAndamento => 0.32,
      ScheduleStatus.aIniciar => 0.22,
    };
    return base.withOpacity(alpha);
  }

  Color _randomStrokeColor(int index, {double s = 0.85, double v = 0.95}) {
    final hue = (index * 137.508) % 360.0;
    return HSVColor.fromAHSV(1.0, hue, s, v).toColor();
  }

  // ====== Helpers ======
  Future<String> _askAreaName({String initial = 'Área'}) async {
    final txt = TextEditingController(text: initial);
    final r = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nome da área', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: txt,
                  labelText: 'Digite um nome',
                  onSubmitted: (_) => Navigator.of(ctx).pop(txt.text.trim()),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(''), child: const Text('Cancelar')),
                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(txt.text.trim()), child: const Text('Salvar')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return (r ?? '').trim();
  }

  // injeta polígono via controller
  Future<void> _addFeatureFromPoints({required String name, required List<Offset> points}) async {
    final c = widget.controller;
    final prevMode = c.mode;
    c.activateDraw();
    c.current..clear()..addAll(points);
    await c.finishPolygon(onAskName: (_) async => name);
    c.activateSelect();
    c.current.clear();
    c.selectedIndex = null;
    if (prevMode != ToolMode.draw) c.mode = prevMode;
  }

  // ========== Hydrate ==========
  Future<void> _hydrateFromBackend(CivilScheduleState st) async {
    _hydrating = true;

    // 1) baixar DXF do backend (apenas dxf_url)
    final rawUrl = (st.assets['dxf_url'])?.toString() ?? '';
    if (rawUrl.isNotEmpty && rawUrl != _lastAssetUrl) {
      await _syncAssetFromBackend(rawUrl);
    }

    // 2) desenhar polígonos do backend
    widget.controller.clearAll();
    _polygonIdByIndex.clear();
    _polyProps.clear();

    for (int i = 0; i < st.polygons.length; i++) {
      final d = st.polygons[i];
      final id = d['id'] as String;
      final name = (d['name'] ?? 'POLÍGONO ${i + 1}').toString();

      final pts = (d['points'] as List? ?? const [])
          .map((p) {
        final m = Map<String, dynamic>.from(p as Map);
        return Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble());
      })
          .toList();

      await _addFeatureFromPoints(name: name, points: pts);

      final props = _propsForIndex(i);
      props['status']     = d['status'];
      props['comment']    = d['comentario'];
      props['takenAtMs']  = (d['takenAtMs'] is num) ? (d['takenAtMs'] as num).toInt() : null;
      props['photoUrls']  = (d['fotos'] is List) ? List<String>.from(d['fotos']) : const <String>[];
      props['photoMetas'] = (d['fotos_meta'] is List)
          ? List<Map<String, dynamic>>.from(
        (d['fotos_meta'] as List).whereType<Object>().map(
              (e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        ),
      )
          : const <Map<String, dynamic>>[];
      props['progress'] = switch ((d['status'] ?? '').toString()) {
        'concluido' => 100,
        'em_andamento' => 50,
        _ => 0,
      };

      _polygonIdByIndex[i] = id;
    }

    widget.controller.activateSelect();
    widget.controller.current.clear();
    widget.controller.selectedIndex = null;

    _lastFeatureCount = widget.controller.features.length;
    _hydrating = false;
  }

  // ========== Storage sync (DXF only) ==========
  Future<void> _syncAssetFromBackend(String rawUrl) async {
    try {
      _setBlocking(true, msg: 'Baixando DXF…');
      final ref = FirebaseStorage.instance.refFromURL(rawUrl);
      final data = await ref.getData(50 * 1024 * 1024);
      if (!mounted || data == null) return;

      setState(() {
        _docBytes = data;

        // limpa estados de interação
        _hoverSnap = null;
        _didFitViewport = false;
        _selectedEdge = null;
        _lastAssetUrl = rawUrl;
      });

      await _renderDxf();
    } catch (e) {
    } finally {
      _setBlocking(false);
    }
  }

  @override
  void initState() {
    super.initState();
    _docBytes = widget.initialPdfBytes; // trata como DXF inicial
    _lastFeatureCount = widget.controller.features.length;
    widget.controller.addListener(_onControllerChanged);
    if (_docBytes != null) _renderDxf();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _tc.dispose();
    _textEditCtrl.dispose();
    _textEditFocus.dispose();
    _dxf.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final n = widget.controller.features.length;
    if (!_hydrating && n > _lastFeatureCount) {
      final newIndex = n - 1;
      _persistFeatureIfNeeded(newIndex);
    }
    _lastFeatureCount = n;
    setState(() {});
  }

  Future<void> _persistFeatureIfNeeded(int index) async {
    if (_savingNewFeature) return;
    final civil = context.read<CivilScheduleBloc?>();
    final cid = civil?.state.contractId;
    if (civil == null || cid == null) return;
    if (_polygonIdByIndex.containsKey(index)) return;

    _savingNewFeature = true;
    try {
      _polygonIdByIndex[index] = '__pending__';

      final f = widget.controller.features[index];
      final points = f.points.map((p) => {'x': p.dx.toDouble(), 'y': p.dy.toDouble()}).toList();

      final newId = await civil.repo.upsertPolygon(
        contractId: cid,
        page: civil.state.currentPage,
        name: f.name,
        status: 'a_iniciar',
        points: points,
        currentUserId: _uid,
      );

      _polygonIdByIndex[index] = newId;
      civil.add(const CivilRefreshRequested());

      if (mounted) {
        NotificationCenter.instance.show(
          AppNotification(
            title: const Text('Polígono salvo.'),
            type: AppNotificationType.success,
            leadingLabel: const Text('Civil'),
          ),
        );
      }
    } catch (e) {
      _polygonIdByIndex.remove(index);
      if (mounted) {
        NotificationCenter.instance.show(
          AppNotification(
            title: Text('Falha ao salvar polígono: $e'),
            type: AppNotificationType.error,
            leadingLabel: const Text('Civil'),
          ),
        );
      }
    } finally {
      _savingNewFeature = false;
    }
  }

  // ========== Render DXF via controller ==========
  Future<void> _renderDxf() async {
    if (_docBytes == null) return;
    widget.controller.setPagePixelSize = null;

    setState(() {
      _loading = true;
      _error = null;
      _didFitViewport = false;

      _hoverSnap = null;
      _editingTextIndex = null;
      _editingAnchor = null;
      _selectedEdge = null;
    });

    try {
      _setBlocking(true, msg: 'Renderizando DXF…');
      await _dxf.loadBytes(_docBytes!, hairlinePx: _dxfHairlinePx);
      if (_dxf.model != null && widget.onPolylinesReady != null) {
        final projector = autoDetectProjector(_dxf.model!); // ou UtmProjector(zone: 24/25, southHemisphere: true)
        final lines = DxfToGeo.toPolylines(model: _dxf.model!, projector: projector);
        widget.onPolylinesReady!(lines);
      }

      setState(() {
        _loading = false;
      });
      widget.controller.setPagePixelSize = _dxf.sizePx;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _dxf.sizePx == null) return;
        if (_lastViewport != Size.zero) _applyFitToContent();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } finally {
      _setBlocking(false);
    }
  }

  // ========== Fit ==========
  Rect _autoContentBounds({int step = 1, int white = 235}) {
    if (_dxf.rgba == null || _dxf.w <= 0 || _dxf.h <= 0) {
      final s = _dxf.sizePx ?? const Size(1,1);
      return Rect.fromLTWH(0, 0, s.width, s.height);
    }
    int minX = _dxf.w, minY = _dxf.h, maxX = -1, maxY = -1;

    int idx(int x, int y) => (y * _dxf.w + x) * 4;
    bool nonWhiteAt(int x, int y) {
      final i = idx(x, y);
      final r = _dxf.rgba![i], g = _dxf.rgba![i + 1], b = _dxf.rgba![i + 2];
      return r < white || g < white || b < white;
    }

    for (int y = 0; y < _dxf.h; y += step) {
      for (int x = 0; x < _dxf.w; x += step) {
        if (nonWhiteAt(x, y)) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < 0) {
      final s = _dxf.sizePx ?? const Size(1,1);
      return Rect.fromLTWH(0, 0, s.width, s.height);
    }

    const pad = 6.0;
    return Rect.fromLTRB(
      (minX - pad).clamp(0, _dxf.w).toDouble(),
      (minY - pad).clamp(0, _dxf.h).toDouble(),
      (maxX + pad).clamp(0, _dxf.w).toDouble(),
      (maxY + pad).clamp(0, _dxf.h).toDouble(),
    );
  }

  void _applyFitToContent() {
    if (!mounted || _dxf.sizePx == null || _lastViewport == Size.zero) return;

    final inner = Size(
      (_lastViewport.width - _lastInset.horizontal).clamp(0.0, double.infinity),
      (_lastViewport.height - _lastInset.vertical).clamp(0.0, double.infinity),
    );

    if (_dxf.rgba != null) {
      final roi = _autoContentBounds();
      _tc.value = ScheduleCivilFitUtils.fitRectToViewport(
        rect: roi,
        viewportInner: inner,
        extraScale: 1.10,
      );
    } else {
      _tc.value = ScheduleCivilFitUtils.fitToViewportCentered(
        imageSize: _dxf.sizePx!,
        viewportInner: inner,
        extraScale: 1.60,
      );
    }
    _didFitViewport = true;
  }

  // ========== Conversões ==========
  Offset _toImageSpace(Offset globalPosition) {
    final ctx = _viewerKey.currentContext;
    if (ctx == null) return Offset.zero;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final localInViewer = box.globalToLocal(globalPosition);
    return _tc.toScene(localInViewer); // ponto em px da IMAGEM
  }

  // ===== Texto =====



  // ========== Interação ==========
  Future<void> _onTapDown(TapDownDetails d) async {
    if (_dxf.sizePx == null) return;

    // Converte screen → image space
    var pImage = _toImageSpace(d.globalPosition);

    // Snap por pixel (na imagem raster)
    if (widget.controller.snapEnabled) {
      pImage = SnapUtils.snapToEdge(
        p: pImage, rgba: _dxf.rgba, w: _dxf.w, h: _dxf.h,
        snapRadius: widget.controller.snapRadius,
        minGradient: widget.controller.snapMinGradient,
      );
    }

    final ctrl = widget.controller;

    // Texto → editor inline
    if (ctrl.mode == ToolMode.text) {
      _startInlineTextEditor(pImage);
      return;
    }

    // Delega pro controller (select/draw de polígonos) — OBS: ele também trabalha em "image space"
    ctrl.handleTap(
      pagePoint: pImage,
      onAskName: (s) => _askAreaName(initial: s),
    );

    // Evita modal durante desenho
    final bool isDrawingNow = ctrl.mode == ToolMode.draw && ctrl.current.isNotEmpty;

    // Hit-test de ENTIDADES DXF (quando nada de polígono foi selecionado)
    if (!isDrawingNow &&
        ctrl.mode == ToolMode.select &&
        ctrl.selectedIndex == null) {
      setState(() {}); // redesenha overlay
    }

    // Fallback antigo: marcador na borda do DXF por snap de pixel
    if (ctrl.mode == ToolMode.select && ctrl.selectedIndex == null && !isDrawingNow && _dxf.rgba != null) {
      final q = SnapUtils.snapToEdge(
        p: pImage, rgba: _dxf.rgba, w: _dxf.w, h: _dxf.h,
        snapRadius: ctrl.snapRadius, minGradient: ctrl.snapMinGradient,
      );
      if ((q - pImage).distance <= ctrl.snapRadius.toDouble()) {
        setState(() => _selectedEdge = q);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && _selectedEdge == q) setState(() => _selectedEdge = null);
        });
      }
    }

    // Se polígono selecionado, abre o modal
    final int? selected = ctrl.selectedIndex;
    if (selected != null && selected >= 0 && !isDrawingNow && ctrl.mode != ToolMode.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openScheduleModalForPolygonUnified(selected);
      });
    }
  }

  void _onHover(PointerHoverEvent e) {
    if (widget.controller.mode != ToolMode.draw ||
        !widget.controller.snapEnabled ||
        _dxf.sizePx == null) return;

    var p = _toImageSpace(e.position);
    if (p.dx < 0 || p.dy < 0 || p.dx > _dxf.sizePx!.width || p.dy > _dxf.sizePx!.height) {
      if (_hoverSnap != null) setState(() => _hoverSnap = null);
      return;
    }
    p = SnapUtils.snapToEdge(
      p: p, rgba: _dxf.rgba, w: _dxf.w, h: _dxf.h,
      snapRadius: widget.controller.snapRadius,
      minGradient: widget.controller.snapMinGradient,
    );
    setState(() => _hoverSnap = p);
  }

  void _onExit(PointerExitEvent e) {
    if (_hoverSnap != null) setState(() => _hoverSnap = null);
  }

  // ========== Upload DXF ==========
  Future<void> _pickAndReplace() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['dxf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final name = result.files.single.name;
    final bytes = result.files.single.bytes!;

    _setBlocking(true, msg: 'Carregando DXF…');

    setState(() {
      _docBytes = bytes;
      _hoverSnap = null;
      _didFitViewport = false;
      _selectedEdge = null;
    });

    widget.controller.clearAll();
    widget.controller.setPagePixelSize = null;
    await _renderDxf(); // render local imediato

    // sobe no Storage e salva meta dos assets
    final civil = context.read<CivilScheduleBloc?>();
    if (civil != null && civil.state.contractId != null && _docBytes != null) {
      civil.add(CivilAssetUploadRequested(
        filename: name,
        bytes: _docBytes!,
        currentUserId: _uid,
      ));
    }

    _setBlocking(false);
  }

  // Insets / Viewport
  void _onInsetsReady(EdgeInsets inset, Size viewport) {
    _lastInset = inset;
    _lastViewport = viewport;
    if (_dxf.sizePx == null) return;
    if (!_didFitViewport) _applyFitToContent();
  }


  Widget _buildInteractiveViewer() {
    final ctrl = widget.controller;
    if (_dxf.image == null || _dxf.sizePx == null) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      opaque: true,
      cursor: ctrl.mode == ToolMode.draw
          ? SystemMouseCursors.precise
          : (ctrl.mode == ToolMode.text ? SystemMouseCursors.text : SystemMouseCursors.grab),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: InteractiveViewer(
          key: _viewerKey,
          transformationController: _tc,
          alignment: Alignment.topLeft,
          constrained: false,
          minScale: 0.2,
          maxScale: 20,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          clipBehavior: Clip.none,
          child: SizedBox(
            width: _dxf.sizePx!.width,
            height: _dxf.sizePx!.height,
            child: Stack(
              children: [
                // DXF raster (com alpha)
                RawImage(image: _dxf.image),

                // 🔵 Overlay da ENTIDADE DXF selecionada
                DxfSelectionOverlay(
                  model: _dxf.model,
                  pick: _dxf.selectedPick,
                  modelToImage: _dxf.modelToImage,
                ),

                // polígonos
                CustomPaint(
                  size: _dxf.sizePx!,
                  painter: MenuDrawerPolygonPainter(
                    features: ctrl.features,
                    current: ctrl.current,
                    colorForIndex: _randomStrokeColor,
                    fillColorForIndex: _polyColorForIndex,
                    percentForIndex: (i) {
                      final p = _propsForIndex(i)['progress'];
                      if (p is num) return p.toDouble();
                      final st = _statusFromKey(_propsForIndex(i)['status'] as String?);
                      return st == ScheduleStatus.concluido ? 100.0
                          : (st == ScheduleStatus.aIniciar ? 0.0 : 50.0);
                    },
                    hasPhotosForIndex: (i) {
                      final urls = (_propsForIndex(i)['photoUrls'] as List?)?.cast<String>() ?? const [];
                      return urls.isNotEmpty;
                    },
                    hasCommentForIndex: (i) {
                      final c = _propsForIndex(i)['comment'] as String?;
                      return (c?.trim().isNotEmpty ?? false);
                    },
                    hoverSnap: _hoverSnap,
                    selectedIndex: ctrl.selectedIndex,
                  ),
                ),

                // marcador da linha dxf “selecionada” (fallback por pixel)
                if (_selectedEdge != null)
                  Positioned(
                    left: _selectedEdge!.dx - 6,
                    top:  _selectedEdge!.dy - 6,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(color: const Color(0xFF8CC8FF), width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                        ),
                      ),
                    ),
                  ),

                // editor inline
                if (_editingAnchor != null)
                  Positioned(
                    left: _editingAnchor!.dx,
                    top: _editingAnchor!.dy,
                    child: InlineTextBox(
                      controller: _textEditCtrl,
                      focusNode: _textEditFocus,
                      style: ctrl.defaultTextStyle,
                      onSubmit: _commitInlineText,
                      onCancel: _cancelInlineText,
                    ),
                  ),

                // textos renderizados
                ...List.generate(ctrl.texts.length, (i) {
                  final it = ctrl.texts[i];
                  final style = ctrl.defaultTextStyle.copyWith(
                    color: it.color,
                    fontSize: it.fontSize,
                    fontWeight: it.weight,
                    shadows: (i == ctrl.selectedText)
                        ? const [Shadow(color: Colors.black54, blurRadius: 6)]
                        : null,
                  );

                  final child = SizedBox(
                    width: it.areaSize?.width,
                    child: Text(
                      it.text,
                      softWrap: it.areaSize != null,
                      maxLines: it.areaSize != null ? 999 : null,
                      style: style,
                    ),
                  );

                  return Positioned(
                    left: it.position.dx,
                    top: it.position.dy,
                    child: IgnorePointer(
                      ignoring: true,
                      child: it.areaSize != null
                          ? ConstrainedBox(
                        constraints: BoxConstraints.tightFor(
                          width: it.areaSize!.width,
                          height: it.areaSize!.height,
                        ),
                        child: child,
                      )
                          : child,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenBlocker() {
    if (!(_blocking || _loading || _dxf.isLoading)) return const SizedBox.shrink();
    return Stack(
      children: [
        const Positioned.fill(child: ModalBarrier(dismissible: false, color: Color(0x80000000))),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6E6E6E)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6)),
                  const SizedBox(width: 12),
                  Text(_blockingMsg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===== Texto inline =====
  void _startInlineTextEditor(Offset scenePos, {int? editIndex}) {
    final ctrl = widget.controller;
    setState(() {
      _editingTextIndex = editIndex;
      _editingAnchor = scenePos;
      _textEditCtrl.text = (editIndex != null) ? ctrl.texts[editIndex].text : '';
      ctrl.selectedText = editIndex;
      ctrl.mode = ToolMode.text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textEditFocus.requestFocus();
    });
  }

  void _commitInlineText() {
    final txt = _textEditCtrl.text.trim();
    final ctrl = widget.controller;

    if (txt.isEmpty) {
      _cancelInlineText();
      return;
    }

    setState(() {
      if (_editingTextIndex == null) {
        ctrl.texts.add(TextItem(
          text: txt,
          position: _editingAnchor!,
          color: ctrl.defaultTextStyle.color ?? Colors.white,
          fontSize: ctrl.defaultTextStyle.fontSize ?? 16,
          weight: ctrl.defaultTextStyle.fontWeight ?? FontWeight.w600,
          areaSize: (ctrl.textTool == TextTool.area || ctrl.textTool == TextTool.verticalArea)
              ? Size(ctrl.textDefaultWidth, ctrl.textDefaultHeight)
              : null,
          vertical: (ctrl.textTool == TextTool.verticalPoint || ctrl.textTool == TextTool.verticalArea),
        ));
        ctrl.selectedText = ctrl.texts.length - 1;
      } else {
        final i = _editingTextIndex!;
        final old = ctrl.texts[i];
        ctrl.texts[i] = TextItem(
          text: txt,
          position: old.position,
          areaSize: old.areaSize,
          vertical: old.vertical,
          monospace: old.monospace,
          fontSize: old.fontSize,
          weight: old.weight,
          color: old.color,
        );
        ctrl.selectedText = i;
      }
      _editingTextIndex = null;
      _editingAnchor = null;
    });

    _textEditCtrl.clear();
  }

  void _cancelInlineText() {
    setState(() {
      _editingTextIndex = null;
      _editingAnchor = null;
    });
    _textEditCtrl.clear();
  }

  // ===== Modal unificado =====
  Future<void> _openScheduleModalForPolygonUnified(int polyIndex) async {
    final ctrl = widget.controller;

    final currentName = ctrl.features[polyIndex].name;
    final props = _propsForIndex(polyIndex);

    final String? statusKey = props['status'] as String?;
    final String? comment = props['comment'] as String?;
    final int? takenAtMs = props['takenAtMs'] as int?;
    final DateTime? takenAt = takenAtMs != null ? DateTime.fromMillisecondsSinceEpoch(takenAtMs) : null;

    final List<String> existingUrls = (props['photoUrls'] as List?)?.cast<String>() ?? const [];

    final double? initialProgress =
    (props['progress'] is num) ? (props['progress'] as num).toDouble().clamp(0, 100) : null;

    final List metas = (props['photoMetas'] as List?) ?? const [];
    final Map<String, pm.CarouselMetadata> existingMetaByUrl = {
      for (final m in metas)
        if ((m is Map) && (m['url']?.toString().isNotEmpty ?? false))
          m['url'] as String: pm.CarouselMetadata(
            name: m['name']?.toString(),
            takenAt: (m['takenAtMs'] is num)
                ? DateTime.fromMillisecondsSinceEpoch((m['takenAtMs'] as num).toInt())
                : null,
            lat: (m['lat'] as num?)?.toDouble(),
            lng: (m['lng'] as num?)?.toDouble(),
            make: m['make']?.toString(),
            model: m['model']?.toString(),
            orientation: (m['orientation'] is num)
                ? (m['orientation'] as num).toInt()
                : int.tryParse(m['orientation']?.toString() ?? ''),
            url: m['url']?.toString(),
          ),
    };

    final initialStatus = (initialProgress != null)
        ? _statusFromProgress(initialProgress)
        : _statusFromKey(statusKey);

    final polygonId = _polygonIdByIndex[polyIndex];

    if (polygonId == null) {
      final civil = context.read<CivilScheduleBloc>();
      final f = widget.controller.features[polyIndex];
      final points = f.points.map((p) => {'x': p.dx, 'y': p.dy}).toList();
      await civil.repo.upsertPolygon(
        contractId: civil.state.contractId!,
        page: civil.state.currentPage,
        name: f.name,
        status: 'a_iniciar',
        points: points
            .map((m) => {'x': (m['x'] as num).toDouble(), 'y': (m['y'] as num).toDouble()})
            .toList(),
        currentUserId: _uid,
      );
      civil.add(const CivilRefreshRequested());
      return;
    }

    final civilBloc = context.read<CivilScheduleBloc>();
   /* final ScheduleRoadBloc adapter = ScheduleBlocAdapterForCivil(
      civilBloc: civilBloc,
      polygonId: polygonId,
      currentUserId: _uid,
    );*/

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: MultiBlocProvider(
                providers: [
                  //BlocProvider<ScheduleRoadBloc>.value(value: adapter),
                  BlocProvider<CivilScheduleBloc>.value(value: civilBloc),
                ],
                child: ScheduleModalSquare(
                  currentUserId: _uid,
                  tipoLabel: widget.title.isNotEmpty ? widget.title : 'CIVIL',
                  type: ScheduleType.civil,
                  targets: [
                    ScheduleApplyTarget(
                      estaca: polyIndex,
                      faixaIndex: 0,
                      existingUrls: existingUrls,
                      existingMetaByUrl: existingMetaByUrl,
                    ),
                  ],
                  initialName: currentName,
                  initialStatus: initialStatus,
                  initialTakenAt: takenAt,
                  initialComment: comment,
                  initialProgress: initialProgress,
                  onDelete: () {
                    civilBloc.add(CivilPolygonDeleteRequested(polygonId));
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                    civilBloc.add(const CivilRefreshRequested());

                    NotificationCenter.instance.show(
                      AppNotification(
                        title: const Text('Área apagada.'),
                        type: AppNotificationType.warning,
                        leadingLabel: const Text('Civil'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    //await adapter.close();

    if (mounted) setState(() {});
  }

  // ========= Build =========
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CivilScheduleBloc, CivilScheduleState>(
      listenWhen: (prev, curr) =>
      prev.contractId  != curr.contractId  ||
          prev.currentPage != curr.currentPage ||
          prev.assets      != curr.assets      ||
          prev.polygons    != curr.polygons    ||
          prev.error       != curr.error,
      listener: (ctx, st) async {
        await _hydrateFromBackend(st);
        if ((st.error ?? '').isNotEmpty && mounted) {
          NotificationCenter.instance.show(
            AppNotification(
              title: Text('Erro: ${st.error}'),
              type: AppNotificationType.error,
              leadingLabel: const Text('Civil'),
            ),
          );
        }
      },
      builder: (ctx, st) {
        // erro de render
        if (_error != null || _dxf.error != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Erro: ${_error ?? _dxf.error}'),
              ),
            ),
          );
        }

        // ainda sem DXF
        if (_docBytes == null || _dxf.image == null || _dxf.sizePx == null) {
          return Scaffold(
            body: Stack(
              children: [
                const BackgroundClean(),
                ScheduleCivilBoard(
                  showBoard: true,
                  contentPadding: 24,
                  onInsetsReady: (inset, viewport) {},
                  childBuilder: (context, inset, viewport) =>
                      DxfPdfEmptyHint(onPickFile: widget.allowPickNewPdf ? _pickAndReplace : null),
                ),
                _buildScreenBlocker(),
              ],
            ),
            floatingActionButton: widget.allowPickNewPdf
                ? FloatingActionButton.extended(
              onPressed: _pickAndReplace,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Trocar DXF'),
            )
                : null,
          );
        }

        // normal
        return Scaffold(
          body: Stack(
            children: [
              const BackgroundClean(),
              ScheduleCivilBoard(
                showBoard: true,
                contentPadding: 0,
                onInsetsReady: _onInsetsReady,
                childBuilder: (context, inset, viewport) => _buildInteractiveViewer(),
              ),
              _buildScreenBlocker(),
            ],
          ),
          floatingActionButton: widget.allowPickNewPdf
              ? FloatingActionButton.extended(
            onPressed: _pickAndReplace,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Trocar DXF'),
          )
              : null,
        );
      },
    );
  }
}
