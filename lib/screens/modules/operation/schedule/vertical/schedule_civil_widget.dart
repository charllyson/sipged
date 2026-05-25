// lib/screens/modules/operation/schedule/vertical/schedule_civil_widget.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_bloc.dart';
import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_event.dart';
import 'package:sipged/_blocs/modules/operation/schedule/vertical/civil_schedule_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_services/files/dxf/dxf_controller.dart';
import 'package:sipged/_services/files/dxf/dxf_empty_hint.dart';
import 'package:sipged/_services/files/dxf/dxf_enums.dart';
import 'package:sipged/_services/files/dxf/dxf_selection_overlay.dart';
import 'package:sipged/_services/files/dxf/dxf_to_geo.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/text_field_in_line.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_status.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_widget.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_type.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/polygon_painter.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/schedule_civil_board.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/schedule_civil_controller.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/schedule_civil_fit_utils.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/snap_utils.dart';
import 'package:sipged/screens/modules/operation/schedule/vertical/text_item.dart';

class ScheduleCivilWidget extends StatefulWidget {
  const ScheduleCivilWidget({
    super.key,
    required this.title,
    required this.controller,
    this.initialPdfBytes,
    this.pageNumber = 1,
    this.allowPickNewPdf = true,
    this.onPolylinesReady,
  });

  final String title;
  final Uint8List? initialPdfBytes;
  final int pageNumber;
  final bool allowPickNewPdf;
  final ScheduleCivilController controller;
  final void Function(List<List<LatLng>> polylines)? onPolylinesReady;

  @override
  State<ScheduleCivilWidget> createState() => _ScheduleCivilWidgetState();
}

class _ScheduleCivilWidgetState extends State<ScheduleCivilWidget> {
  final TransformationController _tc = TransformationController();
  final GlobalKey _viewerKey = GlobalKey();

  final DxfController _dxf = DxfController();

  Uint8List? _docBytes;

  bool _loading = false;
  Object? _error;

  bool _blocking = false;
  String _blockingMsg = 'Carregando…';

  Offset? _hoverSnap;
  Offset? _selectedEdge;

  int? _editingTextIndex;
  Offset? _editingAnchor;

  final TextEditingController _textEditCtrl = TextEditingController();
  final FocusNode _textEditFocus = FocusNode();

  bool _didFitViewport = false;
  EdgeInsets _lastInset = EdgeInsets.zero;
  Size _lastViewport = Size.zero;

  final double _dxfHairlinePx = 0.9;

  final Map<int, Map<String, dynamic>> _polyProps = <int, Map<String, dynamic>>{};
  final Map<int, String> _polygonIdByIndex = <int, String>{};

  int _lastFeatureCount = 0;
  bool _savingNewFeature = false;
  bool _hydrating = false;
  String? _lastAssetUrl;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _notify({
    required String title,
    String? subtitle,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Civil',
        type: type,
        duration: duration,
      ),
    );
  }

  void _setBlocking(bool on, {String? msg}) {
    if (!mounted) return;

    setState(() {
      _blocking = on;

      if (msg != null) {
        _blockingMsg = msg;
      }
    });
  }

  Map<String, dynamic> _propsForIndex(int index) {
    return _polyProps[index] ??= <String, dynamic>{};
  }

  ScheduleStatus _statusFromKey(String? value) {
    final text = (value ?? '').toLowerCase().trim();

    if (text.contains('conclu')) {
      return ScheduleStatus.concluido;
    }

    if (text.contains('andament') || text.contains('progress')) {
      return ScheduleStatus.emAndamento;
    }

    return ScheduleStatus.aIniciar;
  }

  ScheduleStatus _statusFromProgress(double? progress) {
    if (progress == null) {
      return ScheduleStatus.aIniciar;
    }

    if (progress >= 100) {
      return ScheduleStatus.concluido;
    }

    if (progress <= 0) {
      return ScheduleStatus.aIniciar;
    }

    return ScheduleStatus.emAndamento;
  }

  Color _statusBaseColor(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.concluido:
        return const Color(0xFF34A853);

      case ScheduleStatus.emAndamento:
        return const Color(0xFFF39C12);

      case ScheduleStatus.aIniciar:
        return const Color(0xFF9CA3AF);
    }
  }

  Color _polyColorForIndex(
      int index, {
        double s = 0.85,
        double v = 0.95,
      }) {
    final props = _propsForIndex(index);

    final progress = props['progress'] is num
        ? (props['progress'] as num).toDouble()
        : null;

    final status = props['status'] != null
        ? _statusFromKey(props['status'] as String?)
        : _statusFromProgress(progress);

    final base = _statusBaseColor(status);

    final double alpha = switch (status) {
      ScheduleStatus.concluido => 0.32,
      ScheduleStatus.emAndamento => 0.32,
      ScheduleStatus.aIniciar => 0.22,
    };

    return base.withValues(alpha: alpha);
  }

  Color _randomStrokeColor(
      int index, {
        double s = 0.85,
        double v = 0.95,
      }) {
    final hue = (index * 137.508) % 360.0;

    return HSVColor.fromAHSV(1.0, hue, s, v).toColor();
  }

  Future<String> _askAreaName({String initial = 'Área'}) async {
    final controller = TextEditingController(text: initial);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Nome da área',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: controller,
                    labelText: 'Digite um nome',
                    onSubmitted: (_) {
                      Navigator.of(ctx).pop(controller.text.trim());
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop('');
                        },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(controller.text.trim());
                        },
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return (result ?? '').trim();
  }

  Future<void> _addFeatureFromPoints({
    required String name,
    required List<Offset> points,
  }) async {
    final controller = widget.controller;
    final previousMode = controller.mode;

    controller.activateDraw();

    controller.current
      ..clear()
      ..addAll(points);

    await controller.finishPolygon(
      onAskName: (_) async => name,
    );

    controller.activateSelect();
    controller.current.clear();
    controller.selectedIndex = null;

    if (previousMode != ToolMode.draw) {
      controller.mode = previousMode;
    }
  }

  Future<void> _hydrateFromBackend(CivilScheduleState state) async {
    _hydrating = true;

    try {
      final rawUrl = state.assets['dxf_url']?.toString() ?? '';

      if (rawUrl.isNotEmpty && rawUrl != _lastAssetUrl) {
        await _syncAssetFromBackend(rawUrl);
      }

      widget.controller.clearAll();
      _polygonIdByIndex.clear();
      _polyProps.clear();

      for (int i = 0; i < state.polygons.length; i++) {
        final data = state.polygons[i];

        final id = data['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final name = (data['name'] ?? 'POLÍGONO ${i + 1}').toString();

        final points = (data['points'] as List? ?? const <dynamic>[])
            .whereType<Object>()
            .map((item) {
          if (item is! Map) return null;

          final map = Map<String, dynamic>.from(item);

          final x = map['x'];
          final y = map['y'];

          if (x is! num || y is! num) {
            return null;
          }

          return Offset(x.toDouble(), y.toDouble());
        })
            .whereType<Offset>()
            .toList(growable: false);

        if (points.length < 3) continue;

        await _addFeatureFromPoints(
          name: name,
          points: points,
        );

        final props = _propsForIndex(i);

        props['status'] = data['status'];
        props['comment'] = data['comentario'];

        props['takenAtMs'] = data['takenAtMs'] is num
            ? (data['takenAtMs'] as num).toInt()
            : null;

        props['photoUrls'] = data['fotos'] is List
            ? List<String>.from(data['fotos'] as List)
            : const <String>[];

        props['photoMetas'] = data['fotos_meta'] is List
            ? (data['fotos_meta'] as List)
            .whereType<Object>()
            .map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }

          return <String, dynamic>{};
        })
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
            : const <Map<String, dynamic>>[];

        props['progress'] = switch ((data['status'] ?? '').toString()) {
          'concluido' => 100.0,
          'em_andamento' => 50.0,
          _ => 0.0,
        };

        _polygonIdByIndex[i] = id;
      }

      widget.controller.activateSelect();
      widget.controller.current.clear();
      widget.controller.selectedIndex = null;

      _lastFeatureCount = widget.controller.features.length;
    } finally {
      _hydrating = false;
    }
  }

  Future<void> _syncAssetFromBackend(String rawUrl) async {
    try {
      _setBlocking(true, msg: 'Baixando DXF…');

      final ref = FirebaseStorage.instance.refFromURL(rawUrl);
      final data = await ref.getData(50 * 1024 * 1024);

      if (!mounted || data == null) return;

      setState(() {
        _docBytes = data;
        _hoverSnap = null;
        _didFitViewport = false;
        _selectedEdge = null;
        _lastAssetUrl = rawUrl;
      });

      await _renderDxf();
    } finally {
      _setBlocking(false);
    }
  }

  @override
  void initState() {
    super.initState();

    _docBytes = widget.initialPdfBytes;
    _lastFeatureCount = widget.controller.features.length;

    widget.controller.addListener(_onControllerChanged);

    if (_docBytes != null) {
      _renderDxf();
    }
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

    final count = widget.controller.features.length;

    if (!_hydrating && count > _lastFeatureCount) {
      final newIndex = count - 1;
      _persistFeatureIfNeeded(newIndex);
    }

    _lastFeatureCount = count;

    setState(() {});
  }

  Future<void> _persistFeatureIfNeeded(int index) async {
    if (_savingNewFeature) return;

    final civilBloc = context.read<CivilScheduleBloc>();
    final contractId = civilBloc.state.contractId;

    if (contractId == null || contractId.trim().isEmpty) return;
    if (_polygonIdByIndex.containsKey(index)) return;
    if (index < 0 || index >= widget.controller.features.length) return;

    _savingNewFeature = true;

    try {
      _polygonIdByIndex[index] = '__pending__';

      final feature = widget.controller.features[index];

      final points = feature.points
          .map(
            (point) => <String, double>{
          'x': point.dx.toDouble(),
          'y': point.dy.toDouble(),
        },
      )
          .toList(growable: false);

      final newId = await civilBloc.repo.upsertPolygon(
        contractId: contractId,
        page: civilBloc.state.currentPage,
        name: feature.name,
        status: 'a_iniciar',
        points: points,
        currentUserId: _uid,
      );

      _polygonIdByIndex[index] = newId;

      civilBloc.add(const CivilRefreshRequested());

      _notify(
        title: 'Polígono salvo.',
        type: NotificationStatus.success,
      );
    } catch (error) {
      _polygonIdByIndex.remove(index);

      _notify(
        title: 'Falha ao salvar polígono',
        subtitle: '$error',
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      _savingNewFeature = false;
    }
  }

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

      await _dxf.loadBytes(
        _docBytes!,
        hairlinePx: _dxfHairlinePx,
      );

      if (_dxf.model != null && widget.onPolylinesReady != null) {
        final projector = autoDetectProjector(_dxf.model!);

        final lines = DxfToGeo.toPolylines(
          model: _dxf.model!,
          projector: projector,
        );

        widget.onPolylinesReady!(lines);
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      widget.controller.setPagePixelSize = _dxf.sizePx;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _dxf.sizePx == null) return;

        if (_lastViewport != Size.zero) {
          _applyFitToContent();
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
        _loading = false;
      });
    } finally {
      _setBlocking(false);
    }
  }

  Rect _autoContentBounds({
    int step = 1,
    int white = 235,
  }) {
    if (_dxf.rgba == null || _dxf.w <= 0 || _dxf.h <= 0) {
      final size = _dxf.sizePx ?? const Size(1, 1);
      return Rect.fromLTWH(0, 0, size.width, size.height);
    }

    int minX = _dxf.w;
    int minY = _dxf.h;
    int maxX = -1;
    int maxY = -1;

    int idx(int x, int y) {
      return (y * _dxf.w + x) * 4;
    }

    bool nonWhiteAt(int x, int y) {
      final i = idx(x, y);

      final r = _dxf.rgba![i];
      final g = _dxf.rgba![i + 1];
      final b = _dxf.rgba![i + 2];

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
      final size = _dxf.sizePx ?? const Size(1, 1);
      return Rect.fromLTWH(0, 0, size.width, size.height);
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
    if (!mounted || _dxf.sizePx == null || _lastViewport == Size.zero) {
      return;
    }

    final inner = Size(
      (_lastViewport.width - _lastInset.horizontal).clamp(
        0.0,
        double.infinity,
      ),
      (_lastViewport.height - _lastInset.vertical).clamp(
        0.0,
        double.infinity,
      ),
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

  Offset _toImageSpace(Offset globalPosition) {
    final ctx = _viewerKey.currentContext;

    if (ctx == null) return Offset.zero;

    final box = ctx.findRenderObject() as RenderBox?;

    if (box == null) return Offset.zero;

    final localInViewer = box.globalToLocal(globalPosition);

    return _tc.toScene(localInViewer);
  }

  Future<void> _onTapDown(TapDownDetails details) async {
    if (_dxf.sizePx == null) return;

    var imagePoint = _toImageSpace(details.globalPosition);

    if (widget.controller.snapEnabled) {
      imagePoint = SnapUtils.snapToEdge(
        p: imagePoint,
        rgba: _dxf.rgba,
        w: _dxf.w,
        h: _dxf.h,
        snapRadius: widget.controller.snapRadius,
        minGradient: widget.controller.snapMinGradient,
      );
    }

    final controller = widget.controller;

    if (controller.mode == ToolMode.text) {
      _startInlineTextEditor(imagePoint);
      return;
    }

    controller.handleTap(
      pagePoint: imagePoint,
      onAskName: (name) => _askAreaName(initial: name),
    );

    final isDrawingNow =
        controller.mode == ToolMode.draw && controller.current.isNotEmpty;

    if (!isDrawingNow &&
        controller.mode == ToolMode.select &&
        controller.selectedIndex == null) {
      setState(() {});
    }

    if (controller.mode == ToolMode.select &&
        controller.selectedIndex == null &&
        !isDrawingNow &&
        _dxf.rgba != null) {
      final snapPoint = SnapUtils.snapToEdge(
        p: imagePoint,
        rgba: _dxf.rgba,
        w: _dxf.w,
        h: _dxf.h,
        snapRadius: controller.snapRadius,
        minGradient: controller.snapMinGradient,
      );

      if ((snapPoint - imagePoint).distance <=
          controller.snapRadius.toDouble()) {
        setState(() {
          _selectedEdge = snapPoint;
        });

        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && _selectedEdge == snapPoint) {
            setState(() {
              _selectedEdge = null;
            });
          }
        });
      }
    }

    final selected = controller.selectedIndex;

    if (selected != null &&
        selected >= 0 &&
        !isDrawingNow &&
        controller.mode != ToolMode.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openScheduleModalForPolygonUnified(selected);
        }
      });
    }
  }

  void _onHover(PointerHoverEvent event) {
    if (widget.controller.mode != ToolMode.draw ||
        !widget.controller.snapEnabled ||
        _dxf.sizePx == null) {
      return;
    }

    var point = _toImageSpace(event.position);

    if (point.dx < 0 ||
        point.dy < 0 ||
        point.dx > _dxf.sizePx!.width ||
        point.dy > _dxf.sizePx!.height) {
      if (_hoverSnap != null) {
        setState(() {
          _hoverSnap = null;
        });
      }

      return;
    }

    point = SnapUtils.snapToEdge(
      p: point,
      rgba: _dxf.rgba,
      w: _dxf.w,
      h: _dxf.h,
      snapRadius: widget.controller.snapRadius,
      minGradient: widget.controller.snapMinGradient,
    );

    setState(() {
      _hoverSnap = point;
    });
  }

  void _onExit(PointerExitEvent event) {
    if (_hoverSnap != null) {
      setState(() {
        _hoverSnap = null;
      });
    }
  }

  Future<void> _pickAndReplace() async {
    final civilBloc = context.read<CivilScheduleBloc>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['dxf'],
      withData: true,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.single.bytes == null) {
      return;
    }

    final file = result.files.single;
    final name = file.name;
    final bytes = file.bytes!;

    _setBlocking(true, msg: 'Carregando DXF…');

    try {
      setState(() {
        _docBytes = bytes;
        _hoverSnap = null;
        _didFitViewport = false;
        _selectedEdge = null;
      });

      widget.controller.clearAll();
      widget.controller.setPagePixelSize = null;

      await _renderDxf();

      final contractId = civilBloc.state.contractId;

      if (contractId != null && contractId.trim().isNotEmpty && _docBytes != null) {
        civilBloc.add(
          CivilAssetUploadRequested(
            filename: name,
            bytes: _docBytes!,
            currentUserId: _uid,
          ),
        );
      }
    } finally {
      _setBlocking(false);
    }
  }

  void _onInsetsReady(EdgeInsets inset, Size viewport) {
    _lastInset = inset;
    _lastViewport = viewport;

    if (_dxf.sizePx == null) return;

    if (!_didFitViewport) {
      _applyFitToContent();
    }
  }

  Widget _buildInteractiveViewer() {
    final controller = widget.controller;

    if (_dxf.image == null || _dxf.sizePx == null) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      opaque: true,
      cursor: controller.mode == ToolMode.draw
          ? SystemMouseCursors.precise
          : controller.mode == ToolMode.text
          ? SystemMouseCursors.text
          : SystemMouseCursors.grab,
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
              children: <Widget>[
                RawImage(image: _dxf.image),
                DxfSelectionOverlay(
                  model: _dxf.model,
                  pick: _dxf.selectedPick,
                  modelToImage: _dxf.modelToImage,
                ),
                CustomPaint(
                  size: _dxf.sizePx!,
                  painter: PolygonPainter(
                    features: controller.features,
                    current: controller.current,
                    colorForIndex: _randomStrokeColor,
                    fillColorForIndex: _polyColorForIndex,
                    percentForIndex: (index) {
                      final progress = _propsForIndex(index)['progress'];

                      if (progress is num) {
                        return progress.toDouble();
                      }

                      final status = _statusFromKey(
                        _propsForIndex(index)['status'] as String?,
                      );

                      return status == ScheduleStatus.concluido
                          ? 100.0
                          : status == ScheduleStatus.aIniciar
                          ? 0.0
                          : 50.0;
                    },
                    hasPhotosForIndex: (index) {
                      final urls =
                          (_propsForIndex(index)['photoUrls'] as List?)
                              ?.cast<String>() ??
                              const <String>[];

                      return urls.isNotEmpty;
                    },
                    hasCommentForIndex: (index) {
                      final comment =
                      _propsForIndex(index)['comment'] as String?;

                      return comment?.trim().isNotEmpty ?? false;
                    },
                    hoverSnap: _hoverSnap,
                    selectedIndex: controller.selectedIndex,
                  ),
                ),
                if (_selectedEdge != null)
                  Positioned(
                    left: _selectedEdge!.dx - 6,
                    top: _selectedEdge!.dy - 6,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(
                            color: const Color(0xFF8CC8FF),
                            width: 2,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_editingAnchor != null)
                  Positioned(
                    left: _editingAnchor!.dx,
                    top: _editingAnchor!.dy,
                    child: TextFieldInline(
                      controller: _textEditCtrl,
                      focusNode: _textEditFocus,
                      style: controller.defaultTextStyle,
                      onSubmit: _commitInlineText,
                      onCancel: _cancelInlineText,
                    ),
                  ),
                ...List.generate(controller.texts.length, (index) {
                  final item = controller.texts[index];

                  final style = controller.defaultTextStyle.copyWith(
                    color: item.color,
                    fontSize: item.fontSize,
                    fontWeight: item.weight,
                    shadows: index == controller.selectedText
                        ? const <Shadow>[
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                      ),
                    ]
                        : null,
                  );

                  final child = SizedBox(
                    width: item.areaSize?.width,
                    child: Text(
                      item.text,
                      softWrap: item.areaSize != null,
                      maxLines: item.areaSize != null ? 999 : null,
                      style: style,
                    ),
                  );

                  return Positioned(
                    left: item.position.dx,
                    top: item.position.dy,
                    child: IgnorePointer(
                      ignoring: true,
                      child: item.areaSize != null
                          ? ConstrainedBox(
                        constraints: BoxConstraints.tightFor(
                          width: item.areaSize!.width,
                          height: item.areaSize!.height,
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
    if (!(_blocking || _loading || _dxf.isLoading)) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: Color(0x80000000),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6E6E6E),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const LoadingTreeDots(
                    size: 22,
                    strokeWidth: 2.6,
                    color: Colors.white,
                    centered: false,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _blockingMsg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startInlineTextEditor(
      Offset scenePos, {
        int? editIndex,
      }) {
    final controller = widget.controller;

    setState(() {
      _editingTextIndex = editIndex;
      _editingAnchor = scenePos;

      _textEditCtrl.text =
      editIndex != null ? controller.texts[editIndex].text : '';

      controller.selectedText = editIndex;
      controller.mode = ToolMode.text;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _textEditFocus.requestFocus();
      }
    });
  }

  void _commitInlineText() {
    final text = _textEditCtrl.text.trim();
    final controller = widget.controller;

    if (text.isEmpty) {
      _cancelInlineText();
      return;
    }

    setState(() {
      if (_editingTextIndex == null) {
        controller.texts.add(
          TextItem(
            text: text,
            position: _editingAnchor!,
            color: controller.defaultTextStyle.color ?? Colors.white,
            fontSize: controller.defaultTextStyle.fontSize ?? 16,
            weight: controller.defaultTextStyle.fontWeight ?? FontWeight.w600,
            areaSize: controller.textTool == TextTool.area ||
                controller.textTool == TextTool.verticalArea
                ? Size(
              controller.textDefaultWidth,
              controller.textDefaultHeight,
            )
                : null,
            vertical: controller.textTool == TextTool.verticalPoint ||
                controller.textTool == TextTool.verticalArea,
          ),
        );

        controller.selectedText = controller.texts.length - 1;
      } else {
        final index = _editingTextIndex!;
        final old = controller.texts[index];

        controller.texts[index] = TextItem(
          text: text,
          position: old.position,
          areaSize: old.areaSize,
          vertical: old.vertical,
          monospace: old.monospace,
          fontSize: old.fontSize,
          weight: old.weight,
          color: old.color,
        );

        controller.selectedText = index;
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

  Future<void> _openScheduleModalForPolygonUnified(int polyIndex) async {
    if (polyIndex < 0 || polyIndex >= widget.controller.features.length) {
      return;
    }

    final controller = widget.controller;
    final civilBloc = context.read<CivilScheduleBloc>();
    final navigator = Navigator.of(context);

    final contractId = civilBloc.state.contractId;

    if (contractId == null || contractId.trim().isEmpty) {
      _notify(
        title: 'Contrato inválido',
        subtitle: 'Não foi possível identificar o contrato do cronograma civil.',
        type: NotificationStatus.error,
      );
      return;
    }

    final currentName = controller.features[polyIndex].name;
    final props = _propsForIndex(polyIndex);

    final statusKey = props['status'] as String?;
    final comment = props['comment'] as String?;

    final takenAtMs = props['takenAtMs'] is num
        ? (props['takenAtMs'] as num).toInt()
        : null;

    final takenAt = takenAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(takenAtMs)
        : null;

    final existingUrls =
        (props['photoUrls'] as List?)?.cast<String>() ?? const <String>[];

    final initialProgress = props['progress'] is num
        ? (props['progress'] as num).toDouble().clamp(0.0, 100.0)
        : null;

    final metas = (props['photoMetas'] as List?) ?? const <dynamic>[];

    final existingMetaByUrl = <String, Map<String, dynamic>>{
      for (final item in metas)
        if (item is Map &&
            (item['url']?.toString().trim().isNotEmpty ?? false))
          item['url'].toString(): Map<String, dynamic>.from(item),
    };

    final initialStatus = initialProgress != null
        ? _statusFromProgress(initialProgress)
        : _statusFromKey(statusKey);

    var polygonId = _polygonIdByIndex[polyIndex];

    if (polygonId == '__pending__') {
      _notify(
        title: 'Aguarde',
        subtitle: 'Este polígono ainda está sendo salvo.',
        type: NotificationStatus.warning,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (polygonId == null || polygonId.trim().isEmpty) {
      final feature = widget.controller.features[polyIndex];

      final points = feature.points
          .map(
            (point) => <String, double>{
          'x': point.dx.toDouble(),
          'y': point.dy.toDouble(),
        },
      )
          .toList(growable: false);

      polygonId = await civilBloc.repo.upsertPolygon(
        contractId: contractId,
        page: civilBloc.state.currentPage,
        name: feature.name,
        status: 'a_iniciar',
        points: points,
        currentUserId: _uid,
      );

      _polygonIdByIndex[polyIndex] = polygonId;

      civilBloc.add(const CivilRefreshRequested());
    }

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
                providers: <BlocProvider>[
                  BlocProvider<CivilScheduleBloc>.value(
                    value: civilBloc,
                  ),
                ],
                child: ScheduleModalWidget(
                  currentUserId: _uid,
                  tipoLabel: widget.title.trim().isNotEmpty
                      ? widget.title.trim()
                      : 'CIVIL',
                  type: ScheduleType.civil,
                  targets: <ScheduleApplyTarget>[
                    ScheduleApplyTarget(
                      estaca: polyIndex,
                      faixaIndex: 0,
                      polygonId: polygonId,
                      name: currentName,
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
                    civilBloc.add(
                      CivilPolygonDeleteRequested(polygonId!),
                    );

                    if (navigator.canPop()) {
                      navigator.pop();
                    }

                    civilBloc.add(const CivilRefreshRequested());

                    _notify(
                      title: 'Área apagada.',
                      type: NotificationStatus.warning,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    civilBloc.add(const CivilRefreshRequested());

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CivilScheduleBloc, CivilScheduleState>(
      listenWhen: (previous, current) {
        return previous.contractId != current.contractId ||
            previous.currentPage != current.currentPage ||
            previous.assets != current.assets ||
            previous.polygons != current.polygons ||
            previous.error != current.error;
      },
      listener: (ctx, state) async {
        await _hydrateFromBackend(state);

        if ((state.error ?? '').trim().isNotEmpty && mounted) {
          _notify(
            title: 'Erro',
            subtitle: state.error,
            type: NotificationStatus.error,
            duration: const Duration(seconds: 6),
          );
        }
      },
      builder: (ctx, state) {
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

        if (_docBytes == null || _dxf.image == null || _dxf.sizePx == null) {
          return Scaffold(
            body: Stack(
              children: <Widget>[
                const BackgroundChange(),
                ScheduleCivilBoard(
                  showBoard: true,
                  contentPadding: 24,
                  onInsetsReady: (inset, viewport) {},
                  childBuilder: (context, inset, viewport) {
                    return DxfPdfEmptyHint(
                      onPickFile:
                      widget.allowPickNewPdf ? _pickAndReplace : null,
                    );
                  },
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

        return Scaffold(
          body: Stack(
            children: <Widget>[
              const BackgroundChange(),
              ScheduleCivilBoard(
                showBoard: true,
                contentPadding: 0,
                onInsetsReady: _onInsetsReady,
                childBuilder: (context, inset, viewport) {
                  return _buildInteractiveViewer();
                },
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