// lib/screens/modules/operation/schedule/physical/horizontal/schedule_road_map.dart

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/line_segmentation.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_schedule.dart';

import 'package:sipged/_widgets/draw/shimmer/map_shimmer.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;
import 'package:sipged/_widgets/map/map/map_change.dart';

import 'package:sipged/screens/modules/operation/schedule/physical/horizontal/schedule_modal_square.dart';
import 'package:sipged/screens/modules/operation/schedule/physical/horizontal/schedule_status.dart';
import 'package:sipged/screens/modules/operation/schedule/physical/share/schedule_road_debug.dart';
import 'package:sipged/screens/modules/operation/schedule/physical/share/type.dart';

const double kLaneStrokeWidth = 6.0;
const double kLaneStrokeWidthSelected = 9.0;

class ScheduleRoadMap extends StatefulWidget {
  final ProcessData contractData;
  final ValueNotifier<bool>? externalPanelController;

  const ScheduleRoadMap({
    super.key,
    required this.contractData,
    this.externalPanelController,
  });

  @override
  State<ScheduleRoadMap> createState() => _ScheduleRoadMapState();
}

class _ScheduleRoadMapState extends State<ScheduleRoadMap> {
  MapController? _mapController;

  final Set<String> _selectedTags = <String>{};

  bool _multiSelectMode = false;
  bool _modalOpen = false;
  bool _importingGeometry = false;

  double _currentZoom = 14.0;

  VoidCallback? _panelListener;

  SegmentedAxis? _cachedSegmented;
  String? _segKey;

  String? _laneGeometryKey;
  List<_LaneGeometry> _cachedLaneGeometries = const <_LaneGeometry>[];

  String? _polylineKey;
  String? _lastServiceKey;

  String? _markerKey;
  List<Marker> _cachedMarkers = const <Marker>[];

  _RoadMapBuildResult _cachedRoad = const _RoadMapBuildResult.empty();

  @override
  void initState() {
    super.initState();

    if (widget.externalPanelController != null) {
      _panelListener = () {
        if (mounted) setState(() {});
      };

      widget.externalPanelController!.addListener(_panelListener!);
    }
  }

  @override
  void dispose() {
    if (_panelListener != null && widget.externalPanelController != null) {
      widget.externalPanelController!.removeListener(_panelListener!);
    }

    super.dispose();
  }

  void _toast(
      String msg, {
        NotificationStatus type = NotificationStatus.info,
        Duration duration = const Duration(seconds: 8),
      }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: msg,
        leadingLabel: 'Mapa',
        type: type,
        duration: duration,
      ),
    );
  }

  String _actorName() {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  Future<void> _notifySchedule({
    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = true,
    bool sendPush = true,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final actorId = currentUser?.uid.trim();
    final actorName = _actorName();

    await NotificationSchedule.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: leadingLabel ?? 'Cronograma',
      module: 'operation_schedule_road',
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: actorId,
      actorName: actorName,
      includeCurrentUser: true,
      extra: <String, dynamic>{
        'actorId': actorId,
        'actorName': actorName,
        ...extra,
      },
    );
  }

  Future<void> _importGeometryFromMap() async {
    if (_importingGeometry) return;

    final cubit = context.read<ScheduleRoadCubit>();
    final st = cubit.state;
    final contractId = st.contractId ?? widget.contractData.id ?? '';

    if (contractId.isEmpty) {
      _toast(
        'Contrato inválido para importar geometria.',
        type: NotificationStatus.error,
      );
      return;
    }

    setState(() => _importingGeometry = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['geojson', 'json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final Uint8List? bytes = result.files.first.bytes;

      if (bytes == null) {
        throw Exception(
          'Não foi possível ler o arquivo no navegador. Tente selecionar novamente.',
        );
      }

      final decoded = jsonDecode(utf8.decode(bytes));

      if (decoded is! Map<String, dynamic>) {
        throw Exception('O arquivo selecionado não contém um GeoJSON válido.');
      }

      await cubit.importGeoJson(
        geojson: decoded,
        summarySubjectContract: st.summarySubjectContract ?? contractId,
      );

      if (!mounted) return;

      _invalidateAllCaches();

      await _notifySchedule(
        title: 'Geometria do cronograma importada',
        subtitle: 'Geometria atualizada por ${_actorName()}.',
        details: st.summarySubjectContract ?? widget.contractData.displaySummary,
        leadingLabel: 'Mapa',
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'schedule_geometry_imported',
          'contractId': contractId,
          'serviceKey': st.currentServiceKey,
          'serviceLabel': st.titleForHeader,
          'source': 'schedule_road_map',
        },
      );
    } catch (e) {
      if (!mounted) return;

      _toast(
        'Erro ao importar geometria: $e',
        type: NotificationStatus.error,
      );
    } finally {
      if (mounted) setState(() => _importingGeometry = false);
    }
  }

  void _invalidateAllCaches() {
    _cachedSegmented = null;
    _segKey = null;
    _laneGeometryKey = null;
    _cachedLaneGeometries = const <_LaneGeometry>[];
    _polylineKey = null;
    _cachedRoad = const _RoadMapBuildResult.empty();
    _markerKey = null;
    _cachedMarkers = const <Marker>[];
  }

  void _invalidateRoadStyleCacheOnly() {
    _polylineKey = null;
    _cachedRoad = const _RoadMapBuildResult.empty();
  }

  String _makeAxisKey(List<LatLng> axis) {
    if (axis.isEmpty) return 'empty';

    final first = axis.first;
    final last = axis.last;

    return '${axis.length}:'
        '${first.latitude.toStringAsFixed(6)},'
        '${first.longitude.toStringAsFixed(6)}>'
        '${last.latitude.toStringAsFixed(6)},'
        '${last.longitude.toStringAsFixed(6)}';
  }

  SegmentedAxis _getSegmented({
    required List<LatLng> axis,
    required double stepMeters,
  }) {
    final key = '${_makeAxisKey(axis)}@$stepMeters';

    if (_cachedSegmented == null || _segKey != key) {
      _cachedSegmented = ScheduleRoadDebug.trackSync(
        'Map',
        '_getSegmented(axis=${axis.length})',
            () => splitAxisByFixedStep(
          axis: axis,
          stepMeters: stepMeters,
        ),
      );

      _segKey = key;
      _laneGeometryKey = null;
      _polylineKey = null;
      _markerKey = null;
    }

    return _cachedSegmented!;
  }

  String _resolveLaneLabel(dynamic lane) {
    if (lane == null) return '';

    if (lane is ScheduleRoadData) {
      return lane.laneLabel;
    }

    if (lane is Map) {
      final v = lane['label'] ??
          lane['labelText'] ??
          lane['laneLabel'] ??
          lane['name'] ??
          lane['nome'];

      if (v != null) return v.toString();
    }

    try {
      final value = (lane as dynamic).laneLabel;
      if (value != null) return value.toString();
    } catch (_) {}

    try {
      final value = (lane as dynamic).label;
      if (value != null) return value.toString();
    } catch (_) {}

    try {
      final value = (lane as dynamic).labelText;
      if (value != null) return value.toString();
    } catch (_) {}

    return lane.toString();
  }

  Color _colorForSegment({
    required int segIdx,
    required int faixaIndex,
    required ScheduleRoadState st,
  }) {
    final estaca = segIdx + 1;

    final data = st.execIndex[estaca]?[faixaIndex] ??
        ScheduleRoadData(
          numero: estaca,
          faixaIndex: faixaIndex,
          tipo: st.currentServiceKey,
          status: 'a iniciar',
          createdAt: null,
          comentario: null,
          key: st.currentServiceKey,
          label: st.currentServiceKey.toUpperCase(),
          icon: Icons.layers_outlined,
          color: Colors.grey,
        );

    return st.squareColor(data);
  }

  List<_LaneGeometry> _buildLaneGeometries({
    required SegmentedAxis segmented,
    required List<ScheduleRoadData> lanes,
    required int lanesRevision,
  }) {
    final key =
        '${_segKey ?? "no_seg"}|lanesRev=$lanesRevision|lanes=${lanes.length}|seg=${segmented.segmentCount}';

    if (_laneGeometryKey == key) return _cachedLaneGeometries;

    final built = ScheduleRoadDebug.trackSync(
      'Map',
      '_buildLaneGeometries(lanes=${lanes.length}, seg=${segmented.segmentCount})',
          () {
        const laneSpacing = 3.5;

        int le = 0;
        int ce = 0;
        int ld = 0;

        final out = <_LaneGeometry>[];

        for (int fi = 0; fi < lanes.length; fi++) {
          final rawLabel = _resolveLaneLabel(lanes[fi]);
          final label = rawLabel.toUpperCase();

          String side;

          if (label.contains('LE')) {
            side = 'LE';
          } else if (label.contains('LD')) {
            side = 'LD';
          } else {
            side = 'CE';
          }

          double offset = 0.0;
          bool buildRight = false;
          bool buildLeft = false;

          if (side == 'LE') {
            le += 1;
            offset = laneSpacing * le;
            buildLeft = true;
          } else if (side == 'LD') {
            ld += 1;
            offset = laneSpacing * ld;
            buildRight = true;
          } else {
            ce += 1;
            offset = ce == 1 ? 0.0 : laneSpacing * (ce - 1);
            buildRight = true;
          }

          for (var segIdx = 0; segIdx < segmented.segmentCount; segIdx++) {
            if (buildRight) {
              final pts = segmented.offsetSegmentRight(segIdx, offset);

              if (pts.length >= 2) {
                out.add(
                  _LaneGeometry(
                    tag: 'lane$fi#seg$segIdx#R',
                    faixaIndex: fi,
                    segIdx: segIdx,
                    points: List<LatLng>.unmodifiable(pts),
                  ),
                );
              }
            }

            if (buildLeft) {
              final pts = segmented.offsetSegmentLeft(segIdx, offset);

              if (pts.length >= 2) {
                out.add(
                  _LaneGeometry(
                    tag: 'lane$fi#seg$segIdx#L',
                    faixaIndex: fi,
                    segIdx: segIdx,
                    points: List<LatLng>.unmodifiable(pts),
                  ),
                );
              }
            }
          }
        }

        return List<_LaneGeometry>.unmodifiable(out);
      },
    );

    _laneGeometryKey = key;
    _cachedLaneGeometries = built;

    return built;
  }

  _RoadMapBuildResult _buildRoadMapData({
    required List<_LaneGeometry> geometries,
    required ScheduleRoadState st,
    required Set<String> selectedTags,
  }) {
    final selectedKey = selectedTags.toList()..sort();

    final key = '${st.currentServiceKey}|geom=${geometries.length}|'
        'execRev=${st.execRevision}|laneRev=${st.lanesRevision}|'
        'sel=${selectedKey.join(",")}';

    if (_polylineKey == key) return _cachedRoad;

    final result = ScheduleRoadDebug.trackSync(
      'Map',
      '_buildRoadMapData(service=${st.currentServiceKey}, geom=${geometries.length})',
          () {
        final renderPolylines = <Polyline<Object>>[];

        for (final g in geometries) {
          final selected = selectedTags.contains(g.tag);

          final baseColor = _colorForSegment(
            segIdx: g.segIdx,
            faixaIndex: g.faixaIndex,
            st: st,
          );

          final color = selected ? const Color(0xFFEC407A) : baseColor;

          final strokeWidth =
          selected ? kLaneStrokeWidthSelected : kLaneStrokeWidth;

          renderPolylines.add(
            Polyline<Object>(
              points: g.points,
              color: color,
              strokeWidth: strokeWidth,
              hitValue: g.tag,
            ),
          );
        }

        return _RoadMapBuildResult(
          renderPolylines: List<Polyline<Object>>.unmodifiable(
            renderPolylines,
          ),
        );
      },
    );

    _polylineKey = key;
    _cachedRoad = result;

    return result;
  }

  int _markerStepForZoom(double zoom) {
    if (zoom >= 18) return 1;
    if (zoom >= 16) return 10;
    if (zoom >= 14) return 40;
    if (zoom >= 12) return 80;

    return 160;
  }

  List<Marker> _buildStakeMarkers({
    required SegmentedAxis segmented,
    required double zoom,
  }) {
    final positions = segmented.stakePositions;

    if (positions.isEmpty) return const <Marker>[];

    final step = _markerStepForZoom(zoom);

    final key =
        '${_segKey ?? "no_seg"}|zoomStep=$step|count=${positions.length}';

    if (_markerKey == key) return _cachedMarkers;

    final markers = <Marker>[];

    for (int i = 0; i < positions.length; i++) {
      final estaca = i;

      if (estaca == 0 || estaca % step != 0) continue;

      markers.add(
        Marker(
          point: positions[i],
          width: 42,
          height: 20,
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Text(
              '$estaca',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                height: 1.0,
              ),
            ),
          ),
        ),
      );
    }

    _markerKey = key;
    _cachedMarkers = List<Marker>.unmodifiable(markers);

    return _cachedMarkers;
  }

  String _extractSide(String raw) {
    final m = RegExp(
      r'\b(LE|CE|LD)\b',
      caseSensitive: false,
    ).firstMatch(raw.toUpperCase());

    return (m?.group(1) ?? '').toUpperCase();
  }

  String _cleanLaneName(String raw) {
    final up = raw.toUpperCase();

    if (up.contains('DUPLICA')) return 'DUPLICAÇÃO';
    if (up.contains('PISTA ATUAL')) return 'PISTA ATUAL';
    if (up.contains('CANTEIRO')) return 'CANTEIRO';

    var cleaned = raw.replaceAll(
      RegExp(r'\b(LE|CE|LD)\b', caseSensitive: false),
      '',
    );

    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return cleaned.toUpperCase();
  }

  String _formatRoadName({
    required String laneLabel,
    required int estaca,
  }) {
    final side = _extractSide(laneLabel);
    final name = _cleanLaneName(laneLabel);

    return side.isNotEmpty
        ? '$name - $side - E: $estaca'
        : '$name - E: $estaca';
  }

  String _formatRoadNameForMany({
    required String laneLabel,
    required Iterable<int> estacas,
  }) {
    final side = _extractSide(laneLabel);
    final name = _cleanLaneName(laneLabel);
    final seq = (estacas.toList()..sort()).join(', ');
    final base = side.isNotEmpty ? '$name - $side' : name;

    return '$base - E(s): $seq';
  }

  int _segToEstaca(int segIdx) => segIdx + 1;

  LatLng _centerOf(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);

    double lat = 0;
    double lng = 0;

    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }

    return LatLng(lat / points.length, lng / points.length);
  }

  LatLngBounds _boundsFrom(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        const LatLng(-9.65, -35.73),
        const LatLng(-9.65, -35.73),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  Future<void> _handleExternalPolylineTap(
      Polyline<Object> polyline,
      ) async {
    final tag = polyline.hitValue?.toString();

    if (tag == null || tag.isEmpty) {
      return;
    }

    final parsed = _parseLaneSegFromTag(tag);

    if (parsed == null) {
      return;
    }

    if (_multiSelectMode) {
      setState(() {
        if (_selectedTags.contains(tag)) {
          _selectedTags.remove(tag);
        } else {
          _selectedTags.add(tag);
        }
      });

      return;
    }

    setState(() {
      _selectedTags
        ..clear()
        ..add(tag);
    });

    final cubit = context.read<ScheduleRoadCubit>();

    cubit.setSelectedPolyline(tag);

    await _openSingleSegmentModal(
      st: cubit.state,
      faixaIndex: parsed.faixaIndex,
      segIdx: parsed.segIdx,
    );
  }

  Future<void> _clearExternalPolylineSelection() async {
    if (!mounted) return;

    setState(() => _selectedTags.clear());

    context.read<ScheduleRoadCubit>().setSelectedPolyline(null);
  }

  Future<void> _openSingleSegmentModal({
    required ScheduleRoadState st,
    required int faixaIndex,
    required int segIdx,
  }) async {
    if (_modalOpen) return;

    if (!st.canEditSingleCell) {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    if (faixaIndex < 0 || faixaIndex >= st.lanes.length) {
      _toast(
        'Faixa inválida para edição.',
        type: NotificationStatus.error,
      );
      return;
    }

    final cubit = context.read<ScheduleRoadCubit>();

    final estaca = _segToEstaca(segIdx);
    final laneLabel = _resolveLaneLabel(st.lanes[faixaIndex]);

    final initialName = _formatRoadName(
      laneLabel: laneLabel,
      estaca: estaca,
    );

    final existedBefore = st.execIndex[estaca]?[faixaIndex] != null;

    final fotosAtuais = st.fotosAtuaisFor(estaca, faixaIndex);
    final metaByUrl = <String, pm.CarouselMetadata>{};

    final data = st.execIndex[estaca]?[faixaIndex];
    final metas = data?.fotosMeta ?? const <dynamic>[];

    for (final m in metas) {
      final url = m['url']?.toString() ?? '';

      if (url.isEmpty) continue;

      metaByUrl[url] = pm.CarouselMetadata(
        name: m['name']?.toString(),
        takenAt: (m['takenAtMs'] is num)
            ? DateTime.fromMillisecondsSinceEpoch(
          (m['takenAtMs'] as num).toInt(),
        )
            : (m['takenAt'] is num)
            ? DateTime.fromMillisecondsSinceEpoch(
          (m['takenAt'] as num).toInt(),
        )
            : null,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        make: m['make']?.toString(),
        model: m['model']?.toString(),
        orientation: (m['orientation'] is num)
            ? (m['orientation'] as num).toInt()
            : int.tryParse(m['orientation']?.toString() ?? ''),
        url: url,
      );
    }

    final initialStatus = () {
      final t = (data?.status ?? '').toLowerCase();

      if (t.contains('conclu')) return ScheduleStatus.concluido;

      if (t.contains('andament') || t.contains('progress')) {
        return ScheduleStatus.emAndamento;
      }

      return ScheduleStatus.aIniciar;
    }();

    try {
      _modalOpen = true;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: BlocProvider.value(
              value: cubit,
              child: ScheduleModalSquare(
                currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                tipoLabel: st.titleForHeader,
                type: ScheduleType.rodoviario,
                initialName: initialName,
                targets: [
                  ScheduleApplyTarget(
                    estaca: estaca,
                    faixaIndex: faixaIndex,
                    existingUrls: fotosAtuais,
                    existingMetaByUrl: metaByUrl,
                  ),
                ],
                initialStatus: initialStatus,
                initialTakenAt: data?.takenAt,
                initialComment: data?.comentario,
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      await cubit.reloadExecucoes();

      if (!mounted) return;

      final afterState = cubit.state;
      final existsAfter = afterState.execIndex[estaca]?[faixaIndex] != null;
      final wasDeleted = existedBefore && !existsAfter;

      await _notifySchedule(
        title: st.titleForHeader,
        subtitle: null,
        details: null,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action':
          wasDeleted ? 'schedule_stake_deleted' : 'schedule_stake_saved',
          'serviceKey': st.currentServiceKey,
          'serviceLabel': st.titleForHeader,
          'estaca': estaca,
          'faixaIndex': faixaIndex,
          'segIdx': segIdx,
          'stakeName': initialName,
          'segmentName': initialName,
          'source': 'schedule_road_map',
        },
      );
    } catch (e) {
      if (!mounted) return;

      _toast(
        'Falha ao salvar a estaca: $e',
        type: NotificationStatus.error,
      );
    } finally {
      _modalOpen = false;

      if (mounted) {
        setState(() => _selectedTags.clear());
      }
    }
  }

  Future<void> _openBulkModalFromSelected() async {
    final cubit = context.read<ScheduleRoadCubit>();
    final st = cubit.state;

    if (!st.canBulkApply) {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }

    if (_selectedTags.length <= 1 || _modalOpen) return;

    final targets = <ScheduleApplyTarget>[];
    final estacasSelecionadas = <int>[];
    final existingBefore = <String>{};

    int? firstFaixa;

    for (final tag in _selectedTags) {
      final parsed = _parseLaneSegFromTag(tag);

      if (parsed == null) continue;

      final estaca = _segToEstaca(parsed.segIdx);

      firstFaixa ??= parsed.faixaIndex;
      estacasSelecionadas.add(estaca);

      if (st.execIndex[estaca]?[parsed.faixaIndex] != null) {
        existingBefore.add('${estaca}_${parsed.faixaIndex}');
      }

      targets.add(
        ScheduleApplyTarget(
          estaca: estaca,
          faixaIndex: parsed.faixaIndex,
          existingUrls: st.fotosAtuaisFor(estaca, parsed.faixaIndex),
          existingMetaByUrl: const {},
        ),
      );
    }

    if (targets.isEmpty) return;

    final laneIndex = firstFaixa ?? 0;

    if (laneIndex < 0 || laneIndex >= st.lanes.length) {
      _toast(
        'Faixa inválida para edição em lote.',
        type: NotificationStatus.error,
      );
      return;
    }

    final laneLabel = _resolveLaneLabel(st.lanes[laneIndex]);

    final initialNameMany = _formatRoadNameForMany(
      laneLabel: laneLabel,
      estacas: estacasSelecionadas,
    );

    try {
      _modalOpen = true;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          final bottomInset = MediaQuery.viewInsetsOf(sheetCtx).bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: BlocProvider.value(
              value: cubit,
              child: ScheduleModalSquare(
                currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                tipoLabel: st.titleForHeader,
                type: ScheduleType.rodoviario,
                initialName: initialNameMany,
                targets: targets,
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      await cubit.reloadExecucoes();

      if (!mounted) return;

      final afterState = cubit.state;

      int deletedCount = 0;

      for (final key in existingBefore) {
        final parts = key.split('_');

        if (parts.length != 2) continue;

        final estaca = int.tryParse(parts[0]);
        final faixa = int.tryParse(parts[1]);

        if (estaca == null || faixa == null) continue;

        if (afterState.execIndex[estaca]?[faixa] == null) {
          deletedCount++;
        }
      }

      await _notifySchedule(
        title: st.titleForHeader,
        subtitle: null,
        details: null,
        type: NotificationStatus.success,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': deletedCount > 0
              ? 'schedule_bulk_stakes_saved_with_deletions'
              : 'schedule_bulk_stakes_saved',
          'serviceKey': st.currentServiceKey,
          'serviceLabel': st.titleForHeader,
          'targetsCount': targets.length,
          'deletedCount': deletedCount,
          'stakeName': initialNameMany,
          'segmentName': initialNameMany,
          'source': 'schedule_road_map',
        },
      );
    } catch (e) {
      if (!mounted) return;

      _toast(
        'Falha no lote: $e',
        type: NotificationStatus.error,
      );
    } finally {
      _modalOpen = false;

      if (mounted) {
        setState(() {
          _selectedTags.clear();
          _multiSelectMode = false;
        });
      }
    }
  }

  ({int faixaIndex, int segIdx})? _parseLaneSegFromTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;

    final m = RegExp(r'lane(\d+)#seg(\d+)#[RL]').firstMatch(tag);

    if (m == null) return null;

    final fi = int.tryParse(m.group(1)!);
    final si = int.tryParse(m.group(2)!);

    if (fi == null || si == null) return null;

    return (faixaIndex: fi, segIdx: si);
  }

  bool _shouldRebuildMap(ScheduleRoadState prev, ScheduleRoadState curr) {
    if (prev.initialized != curr.initialized) return true;
    if (prev.savingOrImporting != curr.savingOrImporting) return true;
    if (prev.geometryRevision != curr.geometryRevision) return true;
    if (prev.lanesRevision != curr.lanesRevision) return true;

    if (curr.loadingExecucoes) return false;

    if (prev.currentServiceKey != curr.currentServiceKey) return true;
    if (prev.execRevision != curr.execRevision) return true;
    if (prev.loadingExecucoes != curr.loadingExecucoes) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
      buildWhen: _shouldRebuildMap,
      builder: (context, st) {
        ScheduleRoadDebug.log(
          'Map',
          'rebuild => service=${st.currentServiceKey}, axis=${st.axis.length}, lanes=${st.lanes.length}, execRev=${st.execRevision}, loadingExec=${st.loadingExecucoes}',
        );

        if (_lastServiceKey != st.currentServiceKey) {
          _lastServiceKey = st.currentServiceKey;
          _selectedTags.clear();
          _invalidateRoadStyleCacheOnly();
        }

        final hasGeometry =
            st.axis.isNotEmpty || (st.multiLine?.isNotEmpty ?? false);

        if (!st.initialized || st.savingOrImporting) {
          return const MapShimmer();
        }

        if (st.axis.isEmpty) {
          return Stack(
            children: [
              const Center(
                child: Text(
                  'Geometria da obra ainda não carregada.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              _ImportGeoJsonButton(
                importing: _importingGeometry,
                hasGeometry: false,
                onPressed: _importingGeometry ? null : _importGeometryFromMap,
              ),
            ],
          );
        }

        if (st.lanes.isEmpty) {
          return Stack(
            children: [
              const Center(
                child: Text(
                  'Nenhuma faixa configurada para exibir no mapa.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              _ImportGeoJsonButton(
                importing: _importingGeometry,
                hasGeometry: hasGeometry,
                onPressed: (_importingGeometry || st.savingOrImporting)
                    ? null
                    : _importGeometryFromMap,
              ),
            ],
          );
        }

        final axis = List<LatLng>.from(st.axis, growable: false);

        final segmented = _getSegmented(
          axis: axis,
          stepMeters: 20.0,
        );

        final geometries = _buildLaneGeometries(
          segmented: segmented,
          lanes: List<ScheduleRoadData>.from(st.lanes, growable: false),
          lanesRevision: st.lanesRevision,
        );

        final roadData = _buildRoadMapData(
          geometries: geometries,
          st: st,
          selectedTags: _selectedTags,
        );

        final stakeMarkers = _buildStakeMarkers(
          segmented: segmented,
          zoom: _currentZoom,
        );

        final center = _centerOf(axis);
        final bounds = _boundsFrom(axis);

        return RepaintBoundary(
          child: Stack(
            children: [
              MapChange(
                features: const [],
                layersById: const {},
                orderedActiveLayerIds: const [],
                selectedFeatureKey: null,
                loading: st.loadingExecucoes,
                visualDataSignature: Object.hash(
                  st.geometryRevision,
                  st.lanesRevision,
                  st.execRevision,
                  st.currentServiceKey,
                  _currentZoom,
                  Object.hashAll(_selectedTags),
                ),
                initialCenter: center,
                initialZoom: _currentZoom,
                minZoom: 5,
                maxZoom: 20,
                showSearch: true,
                showControls: true,
                initialGeometryPoints: axis,
                fitInitialGeometryOnce: true,
                externalPolylines: roadData.renderPolylines,
                externalMarkers: stakeMarkers,
                onControllerReady: (controller) {
                  _mapController = controller;
                },
                onCameraChanged: (_, zoom) {
                  final rounded = double.parse(
                    zoom.toStringAsFixed(2),
                  );

                  if ((rounded - _currentZoom).abs() >= 0.5) {
                    setState(() => _currentZoom = rounded);
                  }
                },
                onFeatureTap: (_) {},
                onBackgroundTap: (_) {
                  setState(() => _selectedTags.clear());
                  context.read<ScheduleRoadCubit>().setSelectedPolyline(null);
                  return true;
                },
                onExternalPolylineTap: _handleExternalPolylineTap,
                onClearExternalPolylineSelection:
                _clearExternalPolylineSelection,
              ),
              Positioned(
                right: 12,
                top: 64,
                child: SafeArea(
                  child: FilledButton.icon(
                    onPressed: () {
                      try {
                        _mapController?.fitCamera(
                          CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(48),
                          ),
                        );
                      } catch (_) {}
                    },
                    icon: const Icon(
                      Icons.center_focus_strong,
                      size: 18,
                    ),
                    label: const Text(
                      'Centralizar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black45,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              _ImportGeoJsonButton(
                importing: _importingGeometry,
                hasGeometry: hasGeometry,
                onPressed: (_importingGeometry || st.savingOrImporting)
                    ? null
                    : _importGeometryFromMap,
              ),
              Positioned(
                right: 12,
                bottom: 86,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: _multiSelectMode
                            ? 'Sair da seleção múltipla'
                            : 'Ativar seleção múltipla',
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _multiSelectMode = !_multiSelectMode;

                              if (!_multiSelectMode) {
                                _selectedTags.clear();
                              }
                            });

                            _toast(
                              _multiSelectMode
                                  ? 'Modo seleção múltipla. Toque nos trechos para marcar.'
                                  : 'Modo seleção múltipla desativado.',
                            );
                          },
                          icon: Icon(
                            _multiSelectMode ? Icons.check : Icons.select_all,
                            size: 18,
                          ),
                          label: Text(
                            _multiSelectMode
                                ? 'Sair da seleção múltipla'
                                : 'Selecionar múltiplos',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black38,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_multiSelectMode)
                        Badge(
                          isLabelVisible: _selectedTags.isNotEmpty,
                          label: Text('${_selectedTags.length}'),
                          offset: const Offset(-6, 0),
                          child: FilledButton.icon(
                            onPressed: _selectedTags.length >= 2
                                ? _openBulkModalFromSelected
                                : null,
                            icon: const Icon(
                              Icons.done_all,
                              size: 18,
                            ),
                            label: const Text(
                              'Aplicar em lote',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImportGeoJsonButton extends StatelessWidget {
  final bool importing;
  final bool hasGeometry;
  final VoidCallback? onPressed;

  const _ImportGeoJsonButton({
    required this.importing,
    required this.hasGeometry,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      top: 12,
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: importing
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Icon(
            hasGeometry ? Icons.refresh : Icons.upload_file,
            size: 18,
          ),
          label: Text(
            importing
                ? 'Importando...'
                : hasGeometry
                ? 'Reimportar GeoJSON'
                : 'Importar GeoJSON',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black45,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class _LaneGeometry {
  final String tag;
  final int faixaIndex;
  final int segIdx;
  final List<LatLng> points;

  const _LaneGeometry({
    required this.tag,
    required this.faixaIndex,
    required this.segIdx,
    required this.points,
  });
}

class _RoadMapBuildResult {
  final List<Polyline<Object>> renderPolylines;

  const _RoadMapBuildResult({
    required this.renderPolylines,
  });

  const _RoadMapBuildResult.empty()
      : renderPolylines = const <Polyline<Object>>[];
}