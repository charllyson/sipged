// lib/screens/modules/operation/schedule/horizontal/schedule_linear_map.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/line_segmentation.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_schedule.dart';

import 'package:sipged/_widgets/draw/shimmer/map_shimmer.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;
import 'package:sipged/_widgets/map/map/map_change.dart';

import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_widget.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_type.dart';
import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_status.dart';

const double kLaneStrokeWidth = 6.0;
const double kLaneStrokeWidthSelected = 9.0;

/// Abaixo desse zoom, o mapa renderiza apenas visualização compacta.
/// Isso evita travamento com milhares de segmentos.
const double kDetailedRoadZoom = 15.0;

/// Proteção para impedir renderização detalhada absurda.
/// No seu caso atual: 1901 segmentos x 5 faixas = 9505 geometrias.
/// Então 12000 ainda permite detalhar quando aproximar o zoom.
const int kMaxDetailedPolylines = 12000;

/// No modo compacto, cada trecho visual representa aproximadamente 500m.
/// Isso reduz drasticamente a quantidade de polylines em zoom baixo.
const double kCompactSegmentStepMeters = 500.0;

class ScheduleLinearMap extends StatefulWidget {
  final ContractData contractData;
  final ValueNotifier<bool>? externalPanelController;

  const ScheduleLinearMap({
    super.key,
    required this.contractData,
    this.externalPanelController,
  });

  @override
  State<ScheduleLinearMap> createState() => _ScheduleLinearMapState();
}

class _ScheduleLinearMapState extends State<ScheduleLinearMap> {
  final Set<String> _selectedTags = <String>{};


  final bool _multiSelectMode = false;
  bool _modalOpen = false;

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
      _cachedSegmented = splitAxisByFixedStep(
        axis: axis,
        stepMeters: stepMeters,
      );

      _segKey = key;
      _laneGeometryKey = null;
      _polylineKey = null;
      _markerKey = null;
    }

    return _cachedSegmented!;
  }

  List<List<LatLng>> _linesFromState(ScheduleRoadState st) {
    if (st.multiLine != null && st.multiLine!.isNotEmpty) {
      return st.multiLine!
          .where((line) => line.length >= 2)
          .map((line) => List<LatLng>.from(line, growable: false))
          .toList(growable: false);
    }

    if (st.points != null && st.points!.length >= 2) {
      return <List<LatLng>>[
        List<LatLng>.from(st.points!, growable: false),
      ];
    }

    if (st.axis.length >= 2) {
      return <List<LatLng>>[
        List<LatLng>.from(st.axis, growable: false),
      ];
    }

    return const <List<LatLng>>[];
  }

  List<LatLng> _flatAxisFromLines(List<List<LatLng>> lines) {
    return lines.expand((line) => line).toList(growable: false);
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
      final value = (lane as dynamic).labelSection;
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

    final built = List<_LaneGeometry>.unmodifiable(out);

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
        'serviceRev=${st.servicesRevision}|'
        'sel=${selectedKey.join(",")}';

    if (_polylineKey == key) return _cachedRoad;

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

    final result = _RoadMapBuildResult(
      renderPolylines: List<Polyline<Object>>.unmodifiable(renderPolylines),
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

  _DetailedRoadBuildResult _buildDetailedGeometryPack({
    required BuildContext context,
    required ScheduleRoadState st,
    required List<List<LatLng>> lines,
    required double zoom,
  }) {
    final axis = _flatAxisFromLines(lines);

    final segmented = _getSegmented(
      axis: axis,
      stepMeters: 20.0,
    );

    final geometries = _buildLaneGeometries(
      segmented: segmented,
      lanes: List<ScheduleRoadData>.from(st.lanes, growable: false),
      lanesRevision: st.lanesRevision,
    );

    final markers = _buildStakeMarkers(
      segmented: segmented,
      zoom: zoom,
    );

    if (kDebugMode) {
      debugPrint(
        '[ScheduleLinearMap][detailed] '
            'contract=${st.contractId} '
            'lines=${lines.length} '
            'segments=${segmented.segmentCount} '
            'lanes=${st.lanes.length} '
            'geometries=${geometries.length} '
            'markers=${markers.length} '
            'service=${st.currentServiceKey} '
            'zoom=${zoom.toStringAsFixed(2)}',
      );
    }

    return _DetailedRoadBuildResult(
      geometries: geometries,
      markers: markers,
      fitAxis: axis,
    );
  }

  _CompactRoadBuildResult _buildCompactRoadForService({
    required ScheduleRoadState st,
    required List<List<LatLng>> lines,
  }) {
    if (lines.isEmpty || st.lanes.isEmpty) {
      return const _CompactRoadBuildResult.empty();
    }

    const laneSpacing = 3.5;

    final polylines = <Polyline<Object>>[];
    final fitAxis = <LatLng>[];

    final Color compactColor = st.isGeral
        ? Colors.blueGrey.withValues(alpha: 0.55)
        : st.colorForHeader.withValues(alpha: 0.75);

    for (final line in lines) {
      if (line.length < 2) continue;

      fitAxis.addAll(line);

      int le = 0;
      int ce = 0;
      int ld = 0;

      for (int fi = 0; fi < st.lanes.length; fi++) {
        final lane = st.lanes[fi];

        if (!st.isGeral && !lane.isAllowed(st.currentServiceKey)) {
          continue;
        }

        final rawLabel = _resolveLaneLabel(lane);
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

        final segmented = splitAxisByFixedStep(
          axis: line,
          stepMeters: kCompactSegmentStepMeters,
        );

        if (segmented.segmentCount <= 0) continue;

        for (int segIdx = 0; segIdx < segmented.segmentCount; segIdx++) {
          if (buildRight) {
            final pts = segmented.offsetSegmentRight(segIdx, offset);

            if (pts.length >= 2) {
              polylines.add(
                Polyline<Object>(
                  points: pts,
                  color: compactColor,
                  strokeWidth: 5,
                ),
              );
            }
          }

          if (buildLeft) {
            final pts = segmented.offsetSegmentLeft(segIdx, offset);

            if (pts.length >= 2) {
              polylines.add(
                Polyline<Object>(
                  points: pts,
                  color: compactColor,
                  strokeWidth: 5,
                ),
              );
            }
          }
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[ScheduleLinearMap][compact] '
            'contract=${st.contractId} '
            'lines=${lines.length} '
            'lanes=${st.lanes.length} '
            'polylines=${polylines.length} '
            'service=${st.currentServiceKey} '
            'zoom=${_currentZoom.toStringAsFixed(2)}',
      );
    }

    return _CompactRoadBuildResult(
      renderPolylines: List<Polyline<Object>>.unmodifiable(polylines),
      markers: const <Marker>[],
      fitAxis: List<LatLng>.unmodifiable(fitAxis),
    );
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

        _invalidateRoadStyleCacheOnly();
      });

      return;
    }

    setState(() {
      _selectedTags
        ..clear()
        ..add(tag);
      _invalidateRoadStyleCacheOnly();
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

    setState(() {
      _selectedTags.clear();
      _invalidateRoadStyleCacheOnly();
    });

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
    final metas = data?.fotosMeta ?? const <Map<String, dynamic>>[];

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
              child: ScheduleModalWidget(
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
        setState(() {
          _selectedTags.clear();
          _invalidateRoadStyleCacheOnly();
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
    if (prev.servicesRevision != curr.servicesRevision) return true;

    if (curr.loadingExecucoes) return false;

    if (prev.currentServiceKey != curr.currentServiceKey) return true;
    if (prev.execRevision != curr.execRevision) return true;
    if (prev.loadingServices != curr.loadingServices) return true;
    if (prev.loadingLanes != curr.loadingLanes) return true;
    if (prev.loadingExecucoes != curr.loadingExecucoes) return true;
    if (prev.busyReason != curr.busyReason) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
      buildWhen: _shouldRebuildMap,
      builder: (context, st) {
        if (_lastServiceKey != st.currentServiceKey) {
          _lastServiceKey = st.currentServiceKey;
          _selectedTags.clear();
          _invalidateRoadStyleCacheOnly();
        }

        if (!st.initialized || st.savingOrImporting) {
          return const MapShimmer();
        }

        final lines = _linesFromState(st);

        if (lines.isEmpty) {
          return const Center(
            child: Text(
              'Geometria da obra ainda não carregada.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          );
        }

        if (st.lanes.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma faixa configurada para exibir no mapa.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          );
        }

        final shouldUseDetailedMode = _currentZoom >= kDetailedRoadZoom;

        late final _RoadMapBuildResult roadData;
        late final List<Marker> externalMarkers;
        late final List<LatLng> fitAxis;

        if (shouldUseDetailedMode) {
          final pack = _buildDetailedGeometryPack(
            context: context,
            st: st,
            lines: lines,
            zoom: _currentZoom,
          );

          final tooManyPolylines = pack.geometries.length > kMaxDetailedPolylines;

          if (tooManyPolylines) {
            final compact = _buildCompactRoadForService(
              st: st,
              lines: lines,
            );

            roadData = _RoadMapBuildResult(
              renderPolylines: compact.renderPolylines,
            );

            externalMarkers = compact.markers;

            fitAxis = compact.fitAxis.isNotEmpty
                ? compact.fitAxis
                : _flatAxisFromLines(lines);
          } else {
            roadData = _buildRoadMapData(
              geometries: pack.geometries,
              st: st,
              selectedTags: _selectedTags,
            );

            externalMarkers = pack.markers;

            fitAxis =
            pack.fitAxis.isNotEmpty ? pack.fitAxis : _flatAxisFromLines(lines);
          }
        } else {
          final compact = _buildCompactRoadForService(
            st: st,
            lines: lines,
          );

          roadData = _RoadMapBuildResult(
            renderPolylines: compact.renderPolylines,
          );

          externalMarkers = compact.markers;

          fitAxis =
          compact.fitAxis.isNotEmpty ? compact.fitAxis : _flatAxisFromLines(lines);
        }

        final center = _centerOf(fitAxis);

        return RepaintBoundary(
          child: MapChange(
            features: const [],
            layersById: const {},
            orderedActiveLayerIds: const [],
            selectedFeatureKey: null,
            loading: st.loadingExecucoes,
            visualDataSignature: Object.hash(
              st.geometryRevision,
              st.lanesRevision,
              st.servicesRevision,
              st.execRevision,
              st.currentServiceKey,
              _currentZoom,
              Object.hashAll(_selectedTags.toList()..sort()),
            ),
            initialCenter: center,
            initialZoom: _currentZoom,
            minZoom: 5,
            maxZoom: 20,
            showSearch: true,
            showControls: true,
            showZoomSlider: true,
            showMapTypeButton: true,
            initialGeometryPoints: fitAxis,
            fitInitialGeometryOnce: true,
            externalPolylines: roadData.renderPolylines,
            externalMarkers: externalMarkers,
            onControllerReady: (controller) {
            },
            onCameraChanged: (_, zoom) {
              final rounded = double.parse(
                zoom.toStringAsFixed(2),
              );

              if ((rounded - _currentZoom).abs() >= 0.5) {
                setState(() {
                  _currentZoom = rounded;
                  _markerKey = null;
                });
              }
            },
            onFeatureTap: (_) {},
            onBackgroundTap: (_) {
              setState(() {
                _selectedTags.clear();
                _invalidateRoadStyleCacheOnly();
              });

              context.read<ScheduleRoadCubit>().setSelectedPolyline(null);
              return true;
            },
            onExternalPolylineTap: shouldUseDetailedMode
                ? _handleExternalPolylineTap
                : (_) async {
              _toast(
                'Aproxime o zoom para editar os segmentos da obra.',
                type: NotificationStatus.info,
                duration: const Duration(seconds: 3),
              );
            },
            onClearExternalPolylineSelection: _clearExternalPolylineSelection,
          ),
        );
      },
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

class _DetailedRoadBuildResult {
  final List<_LaneGeometry> geometries;
  final List<Marker> markers;
  final List<LatLng> fitAxis;

  const _DetailedRoadBuildResult({
    required this.geometries,
    required this.markers,
    required this.fitAxis,
  });
}

class _CompactRoadBuildResult {
  final List<Polyline<Object>> renderPolylines;
  final List<Marker> markers;
  final List<LatLng> fitAxis;

  const _CompactRoadBuildResult({
    required this.renderPolylines,
    required this.markers,
    required this.fitAxis,
  });

  const _CompactRoadBuildResult.empty()
      : renderPolylines = const <Polyline<Object>>[],
        markers = const <Marker>[],
        fitAxis = const <LatLng>[];
}