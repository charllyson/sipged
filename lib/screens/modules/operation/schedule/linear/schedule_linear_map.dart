// lib/screens/modules/operation/schedule/linear/schedule_linear_map.dart

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_stakes.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_state.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_schedule.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_widgets/draw/shimmer/map_shimmer.dart';
import 'package:sipged/_widgets/map/map/map_change.dart';

import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_status.dart';
import 'package:sipged/screens/modules/operation/schedule/common/modal/schedule_modal_widget.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_type.dart';

const double kEarthRadiusMeters = 6378137.0;
const double kLaneSpacingMeters = 3.5;
const double kLaneStrokeWidthMin = 5.5;
const double kLaneStrokeWidthSelectedExtra = 3.0;
const double kCompactLaneStrokeWidthMin = 4.5;
const double kDetailedRoadZoom = 15.0;
const int kMaxDetailedPolylines = 12000;

const double kStakeRulerVisibleZoom = 10.5;
const double kStakeRulerStepMeters = 20.0;
const int kStakeRulerMajorEvery = 5;
const int kStakeRulerPrincipalEvery = 25;
const double kStakeRulerMinFontSize = 10.5;
const double kStakeRulerMaxFontSize = 17.0;
const double kStakeRulerMarkerWidth = 190.0;
const double kStakeRulerMarkerHeight = 126.0;
const double kStakeRulerLabelGapPx = 16.0;

/// Mesmo em zoom compacto, o mapa precisa manter:
/// 1 fragmento da geometria = 1 estaca = 20 metros.
const double kCompactSegmentStepMeters = kStakeRulerStepMeters;

/// Margem mínima, em metros, depois da borda externa da última faixa.
const double kStakeRulerClearanceBeyondOuterLaneMeters = 1.2;

/// Limite máximo apenas para evitar afastamentos absurdos em cenários extremos.
const double kStakeRulerMaxDynamicOffsetMeters = 80.0;

/// Distância mínima absoluta entre eixo e régua quando existe apenas uma faixa.
const double kStakeRulerMinOffsetFromAxisMeters = 4.5;

class ScheduleLinearMap extends StatefulWidget {
  const ScheduleLinearMap({
    super.key,
    required this.contractData,
    this.externalPanelController,
  });

  final ContractData contractData;
  final ValueNotifier<bool>? externalPanelController;

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

  String _cellKey({
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) {
    return '${serviceKey.trim()}_${faixaIndex}_$estaca';
  }

  bool _cellVisibleForActiveDateFilter({
    required ScheduleLinearState st,
    required ScheduleLinearCellData? cell,
  }) {
    if (!st.hasActiveDateFilter) return true;
    if (cell == null) return false;

    return st.matchesActiveDateFilter(cell);
  }

  bool _isDoneOrInProgressCell(ScheduleLinearCellData cell) {
    return cell.isConcluido || cell.isEmAndamento;
  }

  ScheduleStatus _scheduleStatusFromCellStatus(ScheduleLinearCellStatus status) {
    switch (status) {
      case ScheduleLinearCellStatus.concluido:
        return ScheduleStatus.concluido;
      case ScheduleLinearCellStatus.emAndamento:
        return ScheduleStatus.emAndamento;
      case ScheduleLinearCellStatus.aIniciar:
        return ScheduleStatus.aIniciar;
    }
  }

  Map<String, Map<String, dynamic>> _photoMetaByUrlFromCell(
      ScheduleLinearCellData? cell,
      List<String> urls,
      ) {
    final metaByUrl = <String, Map<String, dynamic>>{};

    final metas = cell?.fotosMeta ?? const <Map<String, dynamic>>[];

    for (final rawMeta in metas) {
      final meta = Map<String, dynamic>.from(rawMeta);
      final url = meta['url']?.toString().trim() ?? '';

      if (url.isEmpty) continue;

      metaByUrl[url] = <String, dynamic>{
        ...meta,
        'id': meta['id']?.toString() ?? url,
        'url': url,
        'name': meta['name']?.toString() ?? url.split('/').last,
      };
    }

    for (final rawUrl in urls) {
      final url = rawUrl.trim();

      if (url.isEmpty) continue;
      if (metaByUrl.containsKey(url)) continue;

      metaByUrl[url] = <String, dynamic>{
        'id': url,
        'url': url,
        'name': url.split('/').last,
        if (cell?.primaryDate != null)
          'takenAtMs': cell!.primaryDate!.millisecondsSinceEpoch,
      };
    }

    return metaByUrl;
  }

  ScheduleLinearCellData? _priorityCellForGeral({
    required ScheduleLinearState st,
    required int estaca,
    required int faixaIndex,
  }) {
    final services = ScheduleLinearServicesData.specificSortedByLayer(
      st.services,
    );

    for (final service in services) {
      final serviceKey = service.key.trim();

      if (serviceKey.isEmpty ||
          serviceKey == ScheduleLinearServicesData.geralKey) {
        continue;
      }

      if (faixaIndex < 0 || faixaIndex >= st.lanes.length) {
        continue;
      }

      if (!st.lanes[faixaIndex].isAllowed(serviceKey)) {
        continue;
      }

      final data = st.execIndex[_cellKey(
        serviceKey: serviceKey,
        estaca: estaca,
        faixaIndex: faixaIndex,
      )];

      if (data == null) continue;

      if (st.hasActiveDateFilter && !st.matchesActiveDateFilter(data)) {
        continue;
      }

      if (_isDoneOrInProgressCell(data)) {
        return data;
      }
    }

    return null;
  }

  bool _shouldRenderSegment({
    required int segIdx,
    required int faixaIndex,
    required ScheduleLinearState st,
  }) {
    if (segIdx < 0) return false;

    if (st.totalEstacas > 0 && segIdx >= st.totalEstacas) {
      return false;
    }

    if (faixaIndex < 0 || faixaIndex >= st.lanes.length) {
      return false;
    }

    if (!st.isGeral && !st.lanes[faixaIndex].isAllowed(st.currentServiceKey)) {
      return false;
    }

    return true;
  }

  bool _laneEnabledForMap({
    required ScheduleLinearState st,
    required ScheduleLinearLaneData lane,
  }) {
    if (st.isGeral) return true;

    return lane.isAllowed(st.currentServiceKey);
  }

  List<int> _visibleLaneIndexesForMap({
    required ScheduleLinearState st,
    required List<ScheduleLinearLaneData> lanes,
  }) {
    final indexes = <int>[];

    for (int i = 0; i < lanes.length; i++) {
      if (_laneEnabledForMap(st: st, lane: lanes[i])) {
        indexes.add(i);
      }
    }

    return indexes;
  }

  double _orderedLaneOffsetMeters({
    required int visibleOrderIndex,
    required int visibleLaneCount,
  }) {
    if (visibleLaneCount <= 1) return 0.0;

    final center = (visibleLaneCount - 1) / 2.0;

    return (visibleOrderIndex - center) * kLaneSpacingMeters;
  }

  double _outerLaneCenterOffsetMeters(int visibleLaneCount) {
    if (visibleLaneCount <= 1) return 0.0;

    return ((visibleLaneCount - 1) / 2.0) * kLaneSpacingMeters;
  }

  List<LatLng> _offsetSegmentBySignedMeters({
    required SegmentedAxis segmented,
    required int segIdx,
    required double signedOffsetMeters,
  }) {
    if (signedOffsetMeters.abs() < 0.001) {
      return segmented.offsetSegmentRight(segIdx, 0.0);
    }

    if (signedOffsetMeters > 0) {
      return segmented.offsetSegmentRight(segIdx, signedOffsetMeters);
    }

    return segmented.offsetSegmentLeft(segIdx, signedOffsetMeters.abs());
  }

  String _sideTagFromOffset(double signedOffsetMeters) {
    return signedOffsetMeters < 0 ? 'L' : 'R';
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
        'module': 'operation_schedule_road',
        'route': 'operation_schedule_road',
        'source': 'schedule_road_map',
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

  List<List<LatLng>> _linesFromState(ScheduleLinearState st) {
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

  String _resolveLaneLabel(ScheduleLinearLaneData lane) {
    return lane.laneLabel;
  }

  Color _colorForSegment({
    required int segIdx,
    required int faixaIndex,
    required ScheduleLinearState st,
  }) {
    final estaca = segIdx + 1;

    if (st.isGeral) {
      final priorityCell = _priorityCellForGeral(
        st: st,
        estaca: estaca,
        faixaIndex: faixaIndex,
      );

      if (priorityCell != null) {
        return st.squareColor(priorityCell);
      }

      return const Color(0xFFE0E0E0);
    }

    final data = st.execIndex[_cellKey(
      serviceKey: st.currentServiceKey,
      estaca: estaca,
      faixaIndex: faixaIndex,
    )];

    if (data != null) {
      if (!_cellVisibleForActiveDateFilter(st: st, cell: data)) {
        return const Color(0xFFE0E0E0);
      }

      return st.squareColor(data);
    }

    final emptyCell = ScheduleLinearCellData(
      numero: estaca,
      faixaIndex: faixaIndex,
      serviceKey: st.currentServiceKey,
      status: ScheduleLinearCellStatus.aIniciar,
      comentario: null,
      fotos: const <String>[],
      fotosMeta: const <Map<String, dynamic>>[],
      takenAtMs: null,
      createdAt: null,
      createdBy: null,
      updatedAt: null,
      updatedBy: null,
    );

    return st.squareColor(emptyCell);
  }

  Color _colorForCompactSegment({
    required int compactSegIdx,
    required int faixaIndex,
    required ScheduleLinearState st,
  }) {
    return _colorForSegment(
      segIdx: compactSegIdx,
      faixaIndex: faixaIndex,
      st: st,
    );
  }

  double _pixelsPerMeterAtZoom({
    required double zoom,
    required double latitude,
  }) {
    const earthCircumferenceMeters = 40075016.686;
    const tileSize = 256.0;

    final latRad = latitude * math.pi / 180.0;
    final cosLat = math.cos(latRad).abs().clamp(0.15, 1.0).toDouble();

    return (tileSize * math.pow(2.0, zoom).toDouble()) /
        (earthCircumferenceMeters * cosLat);
  }

  double _dynamicLaneStrokeWidth({
    required double zoom,
    required double latitude,
    required int laneCount,
    bool compact = false,
    bool selected = false,
  }) {
    final pixelsPerMeter = _pixelsPerMeterAtZoom(
      zoom: zoom,
      latitude: latitude,
    );

    final laneSpacingInPixels = kLaneSpacingMeters * pixelsPerMeter;
    final minWidth = compact ? kCompactLaneStrokeWidthMin : kLaneStrokeWidthMin;
    final maxWidth = compact ? 80.0 : 180.0;
    final overlapFactor = laneCount > 1 ? 1.20 : 0.72;
    final calculated = laneSpacingInPixels * overlapFactor;
    final base = math.max(minWidth, calculated).clamp(minWidth, maxWidth);

    if (!selected) return base.toDouble();

    final extra = math.max(kLaneStrokeWidthSelectedExtra, base * 0.18);
    return (base + extra).clamp(minWidth, maxWidth + 28.0).toDouble();
  }

  double _normalizePi(double angle) {
    var value = angle;

    while (value <= -math.pi) {
      value += 2.0 * math.pi;
    }

    while (value > math.pi) {
      value -= 2.0 * math.pi;
    }

    return value;
  }

  double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return math.atan2(y, x);
  }

  LatLng _offsetByMeters({
    required LatLng point,
    required double distanceMeters,
    required double bearingRad,
  }) {
    final lat = point.latitude * math.pi / 180.0;
    final lon = point.longitude * math.pi / 180.0;
    final dDivR = distanceMeters / kEarthRadiusMeters;

    final newLat = math.asin(
      math.sin(lat) * math.cos(dDivR) +
          math.cos(lat) * math.sin(dDivR) * math.cos(bearingRad),
    );

    final newLon = lon +
        math.atan2(
          math.sin(bearingRad) * math.sin(dDivR) * math.cos(lat),
          math.cos(dDivR) - math.sin(lat) * math.sin(newLat),
        );

    return LatLng(newLat * 180.0 / math.pi, newLon * 180.0 / math.pi);
  }

  double _dynamicStakeRulerOffsetMeters({
    required LatLng point,
    required double zoom,
    required int visibleLaneCount,
    required bool compact,
  }) {
    final laneCount = math.max(1, visibleLaneCount);

    final pixelsPerMeter = _pixelsPerMeterAtZoom(
      zoom: zoom,
      latitude: point.latitude,
    );

    final laneStrokeWidthPx = _dynamicLaneStrokeWidth(
      zoom: zoom,
      latitude: point.latitude,
      laneCount: laneCount,
      compact: compact,
    );

    final rawHalfStrokeMeters =
    pixelsPerMeter <= 0 ? 0.0 : (laneStrokeWidthPx / pixelsPerMeter) / 2.0;

    final halfStrokeMeters = rawHalfStrokeMeters.clamp(0.0, 2.2).toDouble();

    final outerLaneCenterOffset = _outerLaneCenterOffsetMeters(laneCount);

    final calculated = outerLaneCenterOffset +
        halfStrokeMeters +
        kStakeRulerClearanceBeyondOuterLaneMeters;

    return math
        .max(kStakeRulerMinOffsetFromAxisMeters, calculated)
        .clamp(
      kStakeRulerMinOffsetFromAxisMeters,
      kStakeRulerMaxDynamicOffsetMeters,
    )
        .toDouble();
  }

  Offset _latLngToWorldPixel({
    required LatLng point,
    required double zoom,
  }) {
    const tileSize = 256.0;
    final scale = tileSize * math.pow(2.0, zoom).toDouble();
    final sinLat = math.sin(point.latitude * math.pi / 180.0);
    final x = (point.longitude + 180.0) / 360.0 * scale;
    final y =
        (0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi)) *
            scale;

    return Offset(x, y);
  }

  bool _shouldShowStakeRuler(double zoom) => zoom >= kStakeRulerVisibleZoom;

  _StakeRulerProfile _stakeRulerProfile(double zoom) {
    if (zoom < 11.2) {
      return const _StakeRulerProfile(
        tickEvery: 10,
        labelEvery: 50,
        tickMinGapPx: 10,
        labelMinGapPx: 110,
        minorTickLength: 5,
        majorTickLength: 13,
        principalTickLength: 19,
        minorTickAlpha: 0.18,
        majorTickAlpha: 0.42,
        principalTickAlpha: 0.70,
        showMinorLabels: false,
      );
    }

    if (zoom < 12.4) {
      return const _StakeRulerProfile(
        tickEvery: 5,
        labelEvery: 25,
        tickMinGapPx: 8,
        labelMinGapPx: 96,
        minorTickLength: 6,
        majorTickLength: 15,
        principalTickLength: 22,
        minorTickAlpha: 0.20,
        majorTickAlpha: 0.48,
        principalTickAlpha: 0.74,
        showMinorLabels: false,
      );
    }

    if (zoom < 13.6) {
      return const _StakeRulerProfile(
        tickEvery: 2,
        labelEvery: 10,
        tickMinGapPx: 7,
        labelMinGapPx: 82,
        minorTickLength: 7,
        majorTickLength: 17,
        principalTickLength: 24,
        minorTickAlpha: 0.22,
        majorTickAlpha: 0.54,
        principalTickAlpha: 0.78,
        showMinorLabels: false,
      );
    }

    if (zoom < 15.4) {
      return const _StakeRulerProfile(
        tickEvery: 1,
        labelEvery: 5,
        tickMinGapPx: 5,
        labelMinGapPx: 58,
        minorTickLength: 8,
        majorTickLength: 18,
        principalTickLength: 25,
        minorTickAlpha: 0.24,
        majorTickAlpha: 0.60,
        principalTickAlpha: 0.82,
        showMinorLabels: false,
      );
    }

    if (zoom < 16.8) {
      return const _StakeRulerProfile(
        tickEvery: 1,
        labelEvery: 5,
        tickMinGapPx: 3,
        labelMinGapPx: 48,
        minorTickLength: 9,
        majorTickLength: 19,
        principalTickLength: 26,
        minorTickAlpha: 0.28,
        majorTickAlpha: 0.66,
        principalTickAlpha: 0.86,
        showMinorLabels: false,
      );
    }

    if (zoom < 17.8) {
      return const _StakeRulerProfile(
        tickEvery: 1,
        labelEvery: 2,
        tickMinGapPx: 2,
        labelMinGapPx: 36,
        minorTickLength: 10,
        majorTickLength: 20,
        principalTickLength: 27,
        minorTickAlpha: 0.32,
        majorTickAlpha: 0.70,
        principalTickAlpha: 0.90,
        showMinorLabels: true,
      );
    }

    return const _StakeRulerProfile(
      tickEvery: 1,
      labelEvery: 1,
      tickMinGapPx: 0,
      labelMinGapPx: 24,
      minorTickLength: 10,
      majorTickLength: 21,
      principalTickLength: 28,
      minorTickAlpha: 0.34,
      majorTickAlpha: 0.74,
      principalTickAlpha: 0.92,
      showMinorLabels: true,
    );
  }

  bool _isMajorStake(int estaca) {
    return estaca == 0 || estaca % kStakeRulerMajorEvery == 0;
  }

  bool _isPrincipalStake(int estaca) {
    return estaca == 0 || estaca % kStakeRulerPrincipalEvery == 0;
  }

  bool _isEndpointStake({
    required int estaca,
    required int lastIndex,
  }) {
    return estaca == 0 || estaca == lastIndex;
  }

  bool _shouldRenderStakeTick({
    required int estaca,
    required int lastIndex,
    required double zoom,
  }) {
    if (!_shouldShowStakeRuler(zoom)) return false;

    if (_isEndpointStake(estaca: estaca, lastIndex: lastIndex)) {
      return true;
    }

    final profile = _stakeRulerProfile(zoom);

    if (_isPrincipalStake(estaca) || _isMajorStake(estaca)) {
      return true;
    }

    return estaca % profile.tickEvery == 0;
  }

  bool _shouldShowStakeLabel({
    required int estaca,
    required int lastIndex,
    required double zoom,
  }) {
    if (!_shouldShowStakeRuler(zoom)) return false;

    if (_isEndpointStake(estaca: estaca, lastIndex: lastIndex)) {
      return true;
    }

    final profile = _stakeRulerProfile(zoom);

    if (_isPrincipalStake(estaca)) return true;

    if (_isMajorStake(estaca)) {
      return estaca % profile.labelEvery == 0 || profile.labelEvery <= 5;
    }

    if (!profile.showMinorLabels) return false;

    return estaca % profile.labelEvery == 0;
  }

  double _stakeRulerFontSizeForZoom({
    required double zoom,
    required bool principal,
    required bool major,
    required bool minor,
  }) {
    final base = () {
      if (zoom >= 18) return kStakeRulerMaxFontSize;
      if (zoom >= 17) return 15.5;
      if (zoom >= 16) return 14.0;
      if (zoom >= 15) return 12.8;
      if (zoom >= 13) return 11.8;
      return kStakeRulerMinFontSize;
    }();

    if (principal) return base;
    if (major) return math.max(kStakeRulerMinFontSize, base - 0.4);
    if (minor) return math.max(9.8, base - 1.0);

    return base;
  }

  double _localBearingForStake({
    required List<LatLng> positions,
    required int index,
  }) {
    if (positions.length < 2) return 0;
    if (index <= 0) return _bearing(positions[0], positions[1]);

    if (index >= positions.length - 1) {
      return _bearing(positions[index - 1], positions[index]);
    }

    final before = _bearing(positions[index - 1], positions[index]);
    final after = _bearing(positions[index], positions[index + 1]);
    final x = math.cos(before) + math.cos(after);
    final y = math.sin(before) + math.sin(after);

    if (x.abs() < 1e-9 && y.abs() < 1e-9) return after;

    return math.atan2(y, x);
  }

  Widget _buildStakeRulerMarkerChild({
    required int estaca,
    required double zoom,
    required double normalAngle,
    required bool major,
    required bool principal,
    required bool endpoint,
    required bool showLabel,
  }) {
    final profile = _stakeRulerProfile(zoom);
    final minor = !major && !principal && !endpoint;

    final tickLength = endpoint
        ? profile.principalTickLength + 2.0
        : principal
        ? profile.principalTickLength
        : major
        ? profile.majorTickLength
        : profile.minorTickLength;

    final tickHeight = endpoint
        ? 3.0
        : principal
        ? 2.8
        : major
        ? 2.0
        : 1.15;

    final alpha = endpoint
        ? 0.92
        : principal
        ? profile.principalTickAlpha
        : major
        ? profile.majorTickAlpha
        : profile.minorTickAlpha;

    final tickColor = Colors.black.withValues(alpha: alpha);
    final screenNormalAngle = _normalizePi(normalAngle - math.pi / 2.0);
    final label = '$estaca';
    final dirX = math.cos(screenNormalAngle);
    final dirY = math.sin(screenNormalAngle);

    final tickOffset = Offset(
      dirX * (tickLength / 2.0),
      dirY * (tickLength / 2.0),
    );

    final labelOffset = Offset(
      dirX * (tickLength + kStakeRulerLabelGapPx),
      dirY * (tickLength + kStakeRulerLabelGapPx),
    );

    final fontSize = _stakeRulerFontSizeForZoom(
      zoom: zoom,
      principal: principal || endpoint,
      major: major,
      minor: minor,
    );

    return IgnorePointer(
      child: SizedBox(
        width: kStakeRulerMarkerWidth,
        height: kStakeRulerMarkerHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: tickOffset,
              child: Transform.rotate(
                angle: screenNormalAngle,
                child: Container(
                  width: tickLength,
                  height: tickHeight,
                  decoration: BoxDecoration(
                    color: tickColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: minor
                        ? const []
                        : [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.86),
                        blurRadius: 1.8,
                        spreadRadius: 0.35,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 2.4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showLabel)
              Transform.translate(
                offset: labelOffset,
                child: Transform.rotate(
                  angle: screenNormalAngle,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: endpoint || principal ? 5.5 : 5,
                      vertical: endpoint || principal ? 2.8 : 2.4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.16),
                        width: 0.7,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: endpoint || principal
                            ? FontWeight.w900
                            : FontWeight.w800,
                        color: Colors.black87,
                        height: 1.0,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildStakeRulerMarkersFromPositions({
    required List<LatLng> positions,
    required double zoom,
    required String cacheSource,
    required int visibleLaneCount,
    required bool compact,
  }) {
    if (!_shouldShowStakeRuler(zoom)) return const <Marker>[];
    if (positions.length < 2) return const <Marker>[];

    final profile = _stakeRulerProfile(zoom);
    final lastIndex = positions.length - 1;

    final key = '$cacheSource'
        '|positions=${positions.length}'
        '|zoom=${zoom.toStringAsFixed(2)}'
        '|profile=${profile.cacheKey}'
        '|visibleLaneCount=$visibleLaneCount'
        '|compact=$compact';

    if (_markerKey == key) return _cachedMarkers;

    final markers = <Marker>[];
    Offset? lastTickPixel;
    Offset? lastLabelPixel;

    for (int i = 0; i < positions.length; i++) {
      final estaca = i;
      final endpoint = _isEndpointStake(estaca: estaca, lastIndex: lastIndex);

      if (!_shouldRenderStakeTick(
        estaca: estaca,
        lastIndex: lastIndex,
        zoom: zoom,
      )) {
        continue;
      }

      final originalPoint = positions[i];
      final bearing = _localBearingForStake(positions: positions, index: i);
      final normalAngle = _normalizePi(bearing + math.pi / 2.0);

      final dynamicOffsetMeters = _dynamicStakeRulerOffsetMeters(
        point: originalPoint,
        zoom: zoom,
        visibleLaneCount: visibleLaneCount,
        compact: compact,
      );

      final rulerPoint = _offsetByMeters(
        point: originalPoint,
        distanceMeters: dynamicOffsetMeters,
        bearingRad: normalAngle,
      );

      final pixel = _latLngToWorldPixel(point: rulerPoint, zoom: zoom);

      if (!endpoint && profile.tickMinGapPx > 0 && lastTickPixel != null) {
        if ((pixel - lastTickPixel).distance < profile.tickMinGapPx) continue;
      }

      lastTickPixel = pixel;

      final major = _isMajorStake(estaca);
      final principal = _isPrincipalStake(estaca);

      var showLabel = _shouldShowStakeLabel(
        estaca: estaca,
        lastIndex: lastIndex,
        zoom: zoom,
      );

      if (showLabel &&
          !endpoint &&
          !principal &&
          profile.labelMinGapPx > 0 &&
          lastLabelPixel != null) {
        if ((pixel - lastLabelPixel).distance < profile.labelMinGapPx) {
          showLabel = false;
        }
      }

      if (showLabel) lastLabelPixel = pixel;

      markers.add(
        Marker(
          point: rulerPoint,
          width: kStakeRulerMarkerWidth,
          height: kStakeRulerMarkerHeight,
          alignment: Alignment.center,
          child: _buildStakeRulerMarkerChild(
            estaca: estaca,
            zoom: zoom,
            normalAngle: normalAngle,
            major: major,
            principal: principal,
            endpoint: endpoint,
            showLabel: showLabel,
          ),
        ),
      );
    }

    _markerKey = key;
    _cachedMarkers = List<Marker>.unmodifiable(markers);

    return _cachedMarkers;
  }

  List<Marker> _buildStakeRulerMarkers({
    required SegmentedAxis segmented,
    required double zoom,
    required int visibleLaneCount,
  }) {
    return _buildStakeRulerMarkersFromPositions(
      positions: segmented.stakePositions,
      zoom: zoom,
      cacheSource: _segKey ?? 'detailed',
      visibleLaneCount: visibleLaneCount,
      compact: false,
    );
  }

  List<Marker> _buildCompactStakeRulerMarkers({
    required List<LatLng> axis,
    required double zoom,
    required int visibleLaneCount,
  }) {
    if (!_shouldShowStakeRuler(zoom)) return const <Marker>[];
    if (axis.length < 2) return const <Marker>[];

    final segmented = splitAxisByFixedStep(
      axis: axis,
      stepMeters: kStakeRulerStepMeters,
    );

    return _buildStakeRulerMarkersFromPositions(
      positions: segmented.stakePositions,
      zoom: zoom,
      cacheSource: 'compact:${_makeAxisKey(axis)}',
      visibleLaneCount: visibleLaneCount,
      compact: true,
    );
  }

  List<_LaneGeometry> _buildLaneGeometries({
    required SegmentedAxis segmented,
    required List<ScheduleLinearLaneData> lanes,
    required int lanesRevision,
    required ScheduleLinearState st,
  }) {
    final visibleLaneIndexes = _visibleLaneIndexesForMap(
      st: st,
      lanes: lanes,
    );

    final lanesHash = Object.hashAll(
      lanes.map(
            (lane) => Object.hash(
          lane.faixaIndex,
          lane.resolvedPos,
          lane.resolvedNome,
          lane.resolvedAltura,
          lane.allowedByService,
          lane.color.toARGB32(),
        ),
      ),
    );

    final key = '${_segKey ?? "no_seg"}'
        '|lanesRev=$lanesRevision'
        '|lanesHash=$lanesHash'
        '|visible=${visibleLaneIndexes.join(",")}'
        '|seg=${segmented.segmentCount}'
        '|service=${st.currentServiceKey}'
        '|dateFilter=${st.dateFilterSignature}'
        '|statusFilter=${st.statusFilterSignature}';

    if (_laneGeometryKey == key) return _cachedLaneGeometries;

    final out = <_LaneGeometry>[];

    for (int orderIndex = 0;
    orderIndex < visibleLaneIndexes.length;
    orderIndex++) {
      final faixaIndex = visibleLaneIndexes[orderIndex];

      final signedOffsetMeters = _orderedLaneOffsetMeters(
        visibleOrderIndex: orderIndex,
        visibleLaneCount: visibleLaneIndexes.length,
      );

      final sideTag = _sideTagFromOffset(signedOffsetMeters);

      for (int segIdx = 0; segIdx < segmented.segmentCount; segIdx++) {
        if (!_shouldRenderSegment(
          segIdx: segIdx,
          faixaIndex: faixaIndex,
          st: st,
        )) {
          continue;
        }

        final pts = _offsetSegmentBySignedMeters(
          segmented: segmented,
          segIdx: segIdx,
          signedOffsetMeters: signedOffsetMeters,
        );

        if (pts.length < 2) continue;

        out.add(
          _LaneGeometry(
            tag: 'lane$faixaIndex#seg$segIdx#$sideTag',
            faixaIndex: faixaIndex,
            segIdx: segIdx,
            points: List<LatLng>.unmodifiable(pts),
          ),
        );
      }
    }

    final built = List<_LaneGeometry>.unmodifiable(out);

    _laneGeometryKey = key;
    _cachedLaneGeometries = built;

    return built;
  }

  _RoadMapBuildResult _buildRoadMapData({
    required List<_LaneGeometry> geometries,
    required ScheduleLinearState st,
    required Set<String> selectedTags,
    required double zoom,
    required double latitude,
  }) {
    final selectedKey = selectedTags.toList()..sort();

    final visibleLaneIndexes = _visibleLaneIndexesForMap(
      st: st,
      lanes: st.lanes,
    );

    final laneCountForWidth =
    visibleLaneIndexes.isEmpty ? st.lanes.length : visibleLaneIndexes.length;

    final baseStrokeWidth = _dynamicLaneStrokeWidth(
      zoom: zoom,
      latitude: latitude,
      laneCount: laneCountForWidth,
    );

    final selectedStrokeWidth = _dynamicLaneStrokeWidth(
      zoom: zoom,
      latitude: latitude,
      laneCount: laneCountForWidth,
      selected: true,
    );

    final key = '${st.currentServiceKey}'
        '|geom=${geometries.length}'
        '|execRev=${st.execRevision}'
        '|laneRev=${st.lanesRevision}'
        '|serviceRev=${st.servicesRevision}'
        '|dateFilter=${st.dateFilterSignature}'
        '|statusFilter=${st.statusFilterSignature}'
        '|zoom=${zoom.toStringAsFixed(2)}'
        '|lat=${latitude.toStringAsFixed(5)}'
        '|sel=${selectedKey.join(",")}';

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

      renderPolylines.add(
        Polyline<Object>(
          points: g.points,
          color: color,
          strokeWidth: selected ? selectedStrokeWidth : baseStrokeWidth,
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

  _DetailedRoadBuildResult _buildDetailedGeometryPack({
    required BuildContext context,
    required ScheduleLinearState st,
    required List<List<LatLng>> lines,
    required double zoom,
    required int visibleLaneCount,
  }) {
    final axis = _flatAxisFromLines(lines);

    final segmented = _getSegmented(
      axis: axis,
      stepMeters: kStakeRulerStepMeters,
    );

    final geometries = _buildLaneGeometries(
      segmented: segmented,
      lanes: List<ScheduleLinearLaneData>.from(st.lanes, growable: false),
      lanesRevision: st.lanesRevision,
      st: st,
    );

    final markers = _buildStakeRulerMarkers(
      segmented: segmented,
      zoom: zoom,
      visibleLaneCount: visibleLaneCount,
    );

    return _DetailedRoadBuildResult(
      geometries: geometries,
      markers: markers,
      fitAxis: axis,
    );
  }

  _CompactRoadBuildResult _buildCompactRoadForService({
    required ScheduleLinearState st,
    required List<List<LatLng>> lines,
    required double zoom,
    required double latitude,
  }) {
    if (lines.isEmpty || st.lanes.isEmpty) {
      return const _CompactRoadBuildResult.empty();
    }

    final visibleLaneIndexes = _visibleLaneIndexesForMap(
      st: st,
      lanes: st.lanes,
    );

    if (visibleLaneIndexes.isEmpty) {
      return const _CompactRoadBuildResult.empty();
    }

    final axis = _flatAxisFromLines(lines);

    if (axis.length < 2) {
      return const _CompactRoadBuildResult.empty();
    }

    final segmented = splitAxisByFixedStep(
      axis: axis,
      stepMeters: kCompactSegmentStepMeters,
    );

    if (segmented.segmentCount <= 0) {
      return const _CompactRoadBuildResult.empty();
    }

    final polylines = <Polyline<Object>>[];

    final compactStrokeWidth = _dynamicLaneStrokeWidth(
      zoom: zoom,
      latitude: latitude,
      laneCount: visibleLaneIndexes.length,
      compact: true,
    );

    for (int orderIndex = 0;
    orderIndex < visibleLaneIndexes.length;
    orderIndex++) {
      final faixaIndex = visibleLaneIndexes[orderIndex];

      final signedOffsetMeters = _orderedLaneOffsetMeters(
        visibleOrderIndex: orderIndex,
        visibleLaneCount: visibleLaneIndexes.length,
      );

      for (int segIdx = 0; segIdx < segmented.segmentCount; segIdx++) {
        if (!_shouldRenderSegment(
          segIdx: segIdx,
          faixaIndex: faixaIndex,
          st: st,
        )) {
          continue;
        }

        final color = _colorForCompactSegment(
          compactSegIdx: segIdx,
          faixaIndex: faixaIndex,
          st: st,
        );

        final pts = _offsetSegmentBySignedMeters(
          segmented: segmented,
          segIdx: segIdx,
          signedOffsetMeters: signedOffsetMeters,
        );

        if (pts.length < 2) continue;

        polylines.add(
          Polyline<Object>(
            points: pts,
            color: color,
            strokeWidth: compactStrokeWidth,
          ),
        );
      }
    }

    return _CompactRoadBuildResult(
      renderPolylines: List<Polyline<Object>>.unmodifiable(polylines),
      markers: const <Marker>[],
      fitAxis: List<LatLng>.unmodifiable(axis),
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

  Future<void> _handleExternalPolylineTap(Polyline<Object> polyline) async {
    final tag = polyline.hitValue?.toString();

    if (tag == null || tag.isEmpty) return;

    final parsed = _parseLaneSegFromTag(tag);
    if (parsed == null) return;

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

    final cubit = context.read<ScheduleLinearCubit>();
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

    context.read<ScheduleLinearCubit>().setSelectedPolyline(null);
  }

  Future<void> _openSingleSegmentModal({
    required ScheduleLinearState st,
    required int faixaIndex,
    required int segIdx,
  }) async {
    if (_modalOpen) return;

    if (!st.canEditSingleCell) {
      _toast('Para editar, selecione um serviço específico.');
      return;
    }

    if (faixaIndex < 0 || faixaIndex >= st.lanes.length) {
      _toast('Faixa inválida para edição.', type: NotificationStatus.error);
      return;
    }

    if (!st.lanes[faixaIndex].isAllowed(st.currentServiceKey)) {
      _toast(
        'Este serviço não é aplicável nesta faixa.',
        type: NotificationStatus.warning,
      );
      return;
    }

    final cubit = context.read<ScheduleLinearCubit>();
    final estaca = _segToEstaca(segIdx);
    final laneLabel = _resolveLaneLabel(st.lanes[faixaIndex]);

    final initialName = _formatRoadName(
      laneLabel: laneLabel,
      estaca: estaca,
    );

    final indexKey = _cellKey(
      serviceKey: st.currentServiceKey,
      estaca: estaca,
      faixaIndex: faixaIndex,
    );

    final data = st.execIndex[indexKey];
    final existedBefore = data != null;
    final fotosAtuais = st.fotosAtuaisFor(estaca, faixaIndex);
    final metaByUrl = _photoMetaByUrlFromCell(data, fotosAtuais);

    final initialStatus = data == null
        ? ScheduleStatus.aIniciar
        : _scheduleStatusFromCellStatus(data.status);

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

      final existsAfter = afterState.execIndex.containsKey(
        _cellKey(
          serviceKey: afterState.currentServiceKey,
          estaca: estaca,
          faixaIndex: faixaIndex,
        ),
      );

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

  bool _shouldRebuildMap(ScheduleLinearState prev, ScheduleLinearState curr) {
    if (prev.initialized != curr.initialized) return true;
    if (prev.savingOrImporting != curr.savingOrImporting) return true;
    if (prev.geometryRevision != curr.geometryRevision) return true;
    if (prev.lanesRevision != curr.lanesRevision) return true;
    if (prev.servicesRevision != curr.servicesRevision) return true;
    if (prev.dateFilterSignature != curr.dateFilterSignature) return true;
    if (prev.statusFilterSignature != curr.statusFilterSignature) return true;

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
    return BlocBuilder<ScheduleLinearCubit, ScheduleLinearState>(
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
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          );
        }

        if (st.lanes.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma faixa configurada para exibir no mapa.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          );
        }

        final visibleLaneIndexes = _visibleLaneIndexesForMap(
          st: st,
          lanes: st.lanes,
        );

        if (visibleLaneIndexes.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma faixa aplicável ao serviço selecionado.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          );
        }

        final visibleLaneCount = visibleLaneIndexes.length;
        final fallbackAxis = _flatAxisFromLines(lines);
        final fallbackCenter = _centerOf(fallbackAxis);
        final scaleLatitude = fallbackCenter.latitude;
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
            visibleLaneCount: visibleLaneCount,
          );

          final tooManyPolylines =
              pack.geometries.length > kMaxDetailedPolylines;

          if (tooManyPolylines) {
            final compact = _buildCompactRoadForService(
              st: st,
              lines: lines,
              zoom: _currentZoom,
              latitude: scaleLatitude,
            );

            roadData = _RoadMapBuildResult(
              renderPolylines: compact.renderPolylines,
            );

            fitAxis =
            compact.fitAxis.isNotEmpty ? compact.fitAxis : fallbackAxis;

            externalMarkers = _buildCompactStakeRulerMarkers(
              axis: fitAxis,
              zoom: _currentZoom,
              visibleLaneCount: visibleLaneCount,
            );
          } else {
            roadData = _buildRoadMapData(
              geometries: pack.geometries,
              st: st,
              selectedTags: _selectedTags,
              zoom: _currentZoom,
              latitude: scaleLatitude,
            );

            externalMarkers = pack.markers;
            fitAxis = pack.fitAxis.isNotEmpty ? pack.fitAxis : fallbackAxis;
          }
        } else {
          final compact = _buildCompactRoadForService(
            st: st,
            lines: lines,
            zoom: _currentZoom,
            latitude: scaleLatitude,
          );

          roadData = _RoadMapBuildResult(
            renderPolylines: compact.renderPolylines,
          );

          fitAxis = compact.fitAxis.isNotEmpty ? compact.fitAxis : fallbackAxis;

          externalMarkers = _buildCompactStakeRulerMarkers(
            axis: fitAxis,
            zoom: _currentZoom,
            visibleLaneCount: visibleLaneCount,
          );
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
              st.dateFilterSignature,
              st.statusFilterSignature,
              _currentZoom,
              visibleLaneCount,
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
            onControllerReady: (_) {},
            onCameraChanged: (_, zoom) {
              final rounded = double.parse(zoom.toStringAsFixed(2));

              if ((rounded - _currentZoom).abs() >= 0.25) {
                setState(() {
                  _currentZoom = rounded;
                  _markerKey = null;
                  _invalidateRoadStyleCacheOnly();
                });
              }
            },
            onFeatureTap: (_) {},
            onBackgroundTap: (_) {
              setState(() {
                _selectedTags.clear();
                _invalidateRoadStyleCacheOnly();
              });

              context.read<ScheduleLinearCubit>().setSelectedPolyline(null);

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

class _StakeRulerProfile {
  const _StakeRulerProfile({
    required this.tickEvery,
    required this.labelEvery,
    required this.tickMinGapPx,
    required this.labelMinGapPx,
    required this.minorTickLength,
    required this.majorTickLength,
    required this.principalTickLength,
    required this.minorTickAlpha,
    required this.majorTickAlpha,
    required this.principalTickAlpha,
    required this.showMinorLabels,
  });

  final int tickEvery;
  final int labelEvery;
  final double tickMinGapPx;
  final double labelMinGapPx;
  final double minorTickLength;
  final double majorTickLength;
  final double principalTickLength;
  final double minorTickAlpha;
  final double majorTickAlpha;
  final double principalTickAlpha;
  final bool showMinorLabels;

  String get cacheKey {
    return '$tickEvery:$labelEvery:'
        '${tickMinGapPx.toStringAsFixed(1)}:'
        '${labelMinGapPx.toStringAsFixed(1)}:'
        '${minorTickLength.toStringAsFixed(1)}:'
        '${majorTickLength.toStringAsFixed(1)}:'
        '${principalTickLength.toStringAsFixed(1)}:'
        '$showMinorLabels';
  }
}

class _LaneGeometry {
  const _LaneGeometry({
    required this.tag,
    required this.faixaIndex,
    required this.segIdx,
    required this.points,
  });

  final String tag;
  final int faixaIndex;
  final int segIdx;
  final List<LatLng> points;
}

class _RoadMapBuildResult {
  const _RoadMapBuildResult({
    required this.renderPolylines,
  });

  const _RoadMapBuildResult.empty()
      : renderPolylines = const <Polyline<Object>>[];

  final List<Polyline<Object>> renderPolylines;
}

class _DetailedRoadBuildResult {
  const _DetailedRoadBuildResult({
    required this.geometries,
    required this.markers,
    required this.fitAxis,
  });

  final List<_LaneGeometry> geometries;
  final List<Marker> markers;
  final List<LatLng> fitAxis;
}

class _CompactRoadBuildResult {
  const _CompactRoadBuildResult({
    required this.renderPolylines,
    required this.markers,
    required this.fitAxis,
  });

  const _CompactRoadBuildResult.empty()
      : renderPolylines = const <Polyline<Object>>[],
        markers = const <Marker>[],
        fitAxis = const <LatLng>[];

  final List<Polyline<Object>> renderPolylines;
  final List<Marker> markers;
  final List<LatLng> fitAxis;
}