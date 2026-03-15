// lib/screens/modules/operation/schedule/road/schedule_road_map.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_widgets/schedule/modal/type.dart';
import 'package:sipged/screens/modules/operation/schedule/physical/road/schedule_modal_square.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

// Notificações centralizadas
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

// ✅ Cubit/State do cronograma rodoviário
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_state.dart';

import 'package:sipged/_widgets/schedule/linear/schedule_status.dart';

import 'package:sipged/_widgets/schedule/stakes/line_segmentation.dart';
import 'package:sipged/_widgets/schedule/stakes/zoom_listener.dart';

import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:sipged/_widgets/map/markers/tagged_marker.dart';
import 'package:sipged/_widgets/schedule/stakes/stakes_up_right.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';

// ✅ Janela macOS-like

// ====== constantes de estilo ======
const double kLaneStrokeWidth = 7.0;
const double kLaneStrokeWidthSelected = 10.0;
const double kHitStrokeMin = 22.0; // área mínima de toque

class ScheduleRoadMap extends StatefulWidget {
  final ProcessData contractData;

  /// Mantido apenas para compatibilidade com o Workspace (não é mais usado aqui).
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
  // Seleção múltipla no mapa
  final Set<String> _selectedTags = <String>{};
  bool _multiSelectMode = false;
  bool _modalOpen = false;

  VoidCallback? _panelListener; // (compat) não usado para layout

  // cache de segmentação
  SegmentedAxis? _cachedSegmented;
  String? _segKey;

  @override
  void initState() {
    super.initState();

    // Compat: ouvimos o ValueNotifier só para manter estado local se precisar no futuro.
    if (widget.externalPanelController != null) {
      _panelListener = () {
        setState(() {});
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

  // ===== helpers de chave/cache =====
  String _makeAxisKey(List<LatLng> axis) {
    if (axis.isEmpty) return 'empty';
    final a = axis.first, b = axis.last;
    return '${axis.length}:${a.latitude.toStringAsFixed(6)},${a.longitude.toStringAsFixed(6)}>'
        '${b.latitude.toStringAsFixed(6)},${b.longitude.toStringAsFixed(6)}';
  }

  double _bucketZoom(double z) => (z * 4).round() / 4.0;

  SegmentedAxis _getSegmented({
    required List<LatLng> axis,
    required double stepMeters,
    required double zoom,
  }) {
    final key = '${_makeAxisKey(axis)}@$stepMeters@${_bucketZoom(zoom)}';
    if (_cachedSegmented == null || _segKey != key) {
      _cachedSegmented = splitAxisByFixedStep(axis: axis, stepMeters: stepMeters);
      _segKey = key;
    }
    return _cachedSegmented!;
  }

  // ===== apagar traçado salvo =====

  // ===== cópia segura (mantém tag e flags) =====
  TappableChangedPolyline _copyKeepingFlags(
      TappableChangedPolyline p, {
        Color? color,
        double? strokeWidth,
      }) {
    return TappableChangedPolyline(
      points: p.points,
      tag: p.tag,
      color: color ?? p.color,
      defaultColor: p.defaultColor,
      strokeWidth: strokeWidth ?? p.strokeWidth,
      isDotted: p.isDotted,
      hitTestable: p.hitTestable,
    );
  }

  // ===== estilo de seleção (suporta múltiplas) =====
  List<TappableChangedPolyline> _applySelectionStyle(
      List<TappableChangedPolyline> polylines,
      Set<String> selectedTags,
      ) {
    if (selectedTags.isEmpty) {
      return polylines
          .map(
            (p) => _copyKeepingFlags(
          p,
          strokeWidth: kLaneStrokeWidth,
          color: p.defaultColor ?? p.color,
        ),
      )
          .toList();
    }

    return polylines.map((p) {
      final sel = p.tag != null && selectedTags.contains(p.tag.toString());
      return _copyKeepingFlags(
        p,
        color: sel ? const Color(0xFFEC407A) : (p.defaultColor ?? p.color),
        strokeWidth: sel ? kLaneStrokeWidthSelected : kLaneStrokeWidth,
      );
    }).toList();
  }

  // ===== helpers “tocáveis” (ampliam área de toque) =====
  List<TappableChangedPolyline> _withTapHelpers(
      List<TappableChangedPolyline> src,
      ) {
    final helpers = <TappableChangedPolyline>[];
    for (final p in src) {
      helpers.add(
        _copyKeepingFlags(
          p,
          color: Colors.black.withValues(alpha: 0.01), // invisível mas clicável
          strokeWidth: math.max(p.strokeWidth, kHitStrokeMin),
        ),
      );
    }
    return [...helpers, ...src];
  }

  // ===== resolver label da faixa, independente da estrutura =====
  String _resolveLaneLabel(dynamic lane) {
    if (lane == null) return '';

    // Se for Map
    if (lane is Map) {
      final v = lane['label'] ?? lane['labelText'] ?? lane['name'];
      if (v != null) return v.toString();
    }

    // Tenta .label
    try {
      final value = (lane as dynamic).label;
      if (value != null) return value.toString();
    } catch (_) {}

    // Tenta .labelText
    try {
      final value = (lane as dynamic).labelText;
      if (value != null) return value.toString();
    } catch (_) {}

    // Fallback
    return lane.toString();
  }

  // ===== cor por segmento =====
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

  // ===== lanes -> polylines segmentadas clicáveis =====
  List<TappableChangedPolyline> _buildLanePolylines({
    required SegmentedAxis segmented,
    required List lanes,
    required ScheduleRoadState st,
  }) {
    const laneSpacing = 3.5; // distância lateral entre faixas (m)
    int le = 0, ce = 0, ld = 0;
    final out = <TappableChangedPolyline>[];

    for (int fi = 0; fi < lanes.length; fi++) {
      final rawLabel = _resolveLaneLabel(lanes[fi]);
      final label = rawLabel.toUpperCase();

      // ===== identifica lado (LE / LD / CE) =====
      String side;
      if (label.contains('LE')) {
        side = 'LE';
      } else if (label.contains('LD')) {
        side = 'LD';
      } else {
        side = 'CE';
      }

      // ===== define offset e direção de construção =====
      double offset = 0.0;
      bool buildRight = false, buildLeft = false;

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
        offset = (ce == 1) ? 0.0 : laneSpacing * (ce - 1);
        buildRight = true;
      }

      // ===== cor por segmento =====
      Color colorForIdx(int segIdx) => _colorForSegment(
        segIdx: segIdx,
        faixaIndex: fi,
        st: st,
      );

      final totalSegs = segmented.segmentCount;

      // ===== gera cada trecho de 20 m =====
      for (var segIdx = 0; segIdx < totalSegs; segIdx++) {
        if (buildRight) {
          final ptsR = segmented.offsetSegmentRight(segIdx, offset);
          if (ptsR.length >= 2) {
            out.add(
              TappableChangedPolyline(
                points: ptsR,
                tag: 'lane$fi#seg$segIdx#R',
                color: colorForIdx(segIdx),
                defaultColor: colorForIdx(segIdx),
                strokeWidth: kLaneStrokeWidth,
                isDotted: false,
                hitTestable: true,
              ),
            );
          }
        }

        if (buildLeft) {
          final ptsL = segmented.offsetSegmentLeft(segIdx, offset);
          if (ptsL.length >= 2) {
            out.add(
              TappableChangedPolyline(
                points: ptsL,
                tag: 'lane$fi#seg$segIdx#L',
                color: colorForIdx(segIdx),
                defaultColor: colorForIdx(segIdx),
                strokeWidth: kLaneStrokeWidth,
                isDotted: false,
                hitTestable: true,
              ),
            );
          }
        }
      }
    }

    return out;
  }

  // ===== layer de estacas =====
  Widget _stakesLayer({
    required List<TaggedChangedMarker<Map<String, dynamic>>> markers,
  }) {
    if (markers.isEmpty) return const SizedBox.shrink();
    return MarkerLayer(
      markers: markers
          .map(
            (m) => Marker(
          point: m.point,
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: StakesUpRight(
            label: m.properties['label']?.toString() ?? '',
            normalAngle: (m.properties['normalAngle'] as double?) ?? 0.0,
            tickPx: (m.properties['tickPx'] as double?) ?? 12.0,
          ),
        ),
      )
          .toList(),
    );
  }

  // ===================== Helpers de nome (mesma regra do Board) =====================
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
      RegExp(
        r'\b(LE|CE|LD)\b',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s*-\s*'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return cleaned.toUpperCase();
  }

  String _formatRoadName({required String laneLabel, required int estaca}) {
    final side = _extractSide(laneLabel);
    final name = _cleanLaneName(laneLabel);
    return side.isNotEmpty ? '$name - $side - E: $estaca' : '$name - E: $estaca';
  }

  String _formatRoadNameForMany({
    required String laneLabel,
    required Iterable<int> estacas,
  }) {
    final side = _extractSide(laneLabel);
    final name = _cleanLaneName(laneLabel);
    final seq = (estacas.toList()..sort()).join(', ');
    final base = side.isNotEmpty ? '$name - $side' : name;
    return '$base - E(s):$seq';
  }

  // ========================= Parse de TAG para (faixaIndex, segIdx) =========================
  ({int faixaIndex, int segIdx})? _parseLaneSegFromTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    // padrão principal: lane$fi#seg$segIdx#R|L
    final m = RegExp(r'lane(\d+)#seg(\d+)#(?:R|L)').firstMatch(tag);
    if (m != null) {
      final fi = int.tryParse(m.group(1)!);
      final si = int.tryParse(m.group(2)!);
      if (fi != null && si != null) return (faixaIndex: fi, segIdx: si);
    }
    // fallback para segR:12 / segL:34
    final m2 = RegExp(r'seg[RL]:(\d+)').firstMatch(tag);
    if (m2 != null) {
      final si = int.tryParse(m2.group(1)!);
      if (si != null) return (faixaIndex: 0, segIdx: si);
    }
    return null;
  }

  int _segToEstaca(int segIdx) => segIdx + 1;

  // ========================= Modal de célula única =========================
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

    final estaca = _segToEstaca(segIdx);
    final laneLabel = _resolveLaneLabel(st.lanes[faixaIndex]);
    final initialName = _formatRoadName(laneLabel: laneLabel, estaca: estaca);

    // fotos/meta existentes
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
            : ((m['takenAt'] is num)
            ? DateTime.fromMillisecondsSinceEpoch(
          (m['takenAt'] as num).toInt(),
        )
            : null),
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
              value: context.read<ScheduleRoadCubit>(),
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

      await context.read<ScheduleRoadCubit>().reloadExecucoes();
      _toast(
        'Célula atualizada com sucesso!',
        type: AppNotificationType.success,
      );
    } catch (e) {
      _toast(
        'Falha ao salvar a célula: $e',
        type: AppNotificationType.error,
      );
    } finally {
      _modalOpen = false;
      if (mounted) setState(() => _selectedTags.clear());
    }
  }

  // ========================= Modal de lote a partir da seleção =========================
  Future<void> _openBulkModalFromSelected() async {
    final st = context.read<ScheduleRoadCubit>().state;
    if (!st.canBulkApply) {
      _toast('Selecione um serviço específico para editar em lote.');
      return;
    }
    if (_selectedTags.length <= 1 || _modalOpen) return;

    final targets = <ScheduleApplyTarget>[];
    final estacasSelecionadas = <int>[];
    int? firstFaixa;

    for (final tag in _selectedTags) {
      final parsed = _parseLaneSegFromTag(tag);
      if (parsed == null) continue;
      final estaca = _segToEstaca(parsed.segIdx);
      firstFaixa ??= parsed.faixaIndex;
      estacasSelecionadas.add(estaca);

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

    final laneLabel = _resolveLaneLabel(st.lanes[firstFaixa ?? 0]);
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
              value: context.read<ScheduleRoadCubit>(),
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

      await context.read<ScheduleRoadCubit>().reloadExecucoes();
      _toast(
        'Aplicado em lote: ${targets.length} segmento(s).',
        type: AppNotificationType.success,
      );
    } catch (e) {
      _toast('Falha no lote: $e', type: AppNotificationType.error);
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

  // ===================== Notificações centralizadas =====================
  void _toast(
      String msg, {
        AppNotificationType type = AppNotificationType.info,
      }) {
    NotificationCenter.instance.show(
      AppNotification(
        type: type,
        title: Text(msg),
        leadingLabel: const Text('Aviso'),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  // ===================== Exportar seleção para GeoJSON (ToolBoxWidget) =====================
  String _buildSelectedGeoJSON({
    required List<TappableChangedPolyline> laneSegments,
    required bool normalized,
  }) {
    // usamos somente os segmentos "visíveis" (sem helpers de hit)
    final visible = laneSegments.where((p) => p.tag != null).toList();
    final selected = _selectedTags.isEmpty
        ? visible
        : visible.where((p) => _selectedTags.contains(p.tag.toString())).toList();

    final features = selected.map((p) {
      final coords =
      p.points.map((pt) => [pt.longitude, pt.latitude]).toList();
      final tag = p.tag?.toString() ?? '';
      final props = {
        'tag': tag,
        'stroke': (p.defaultColor ?? p.color).value,
        'strokeWidth': p.strokeWidth,
      };

      return {
        'type': 'Feature',
        'editor': normalized ? _normalizeProps(props) : props,
        'geometry': {
          'type': 'LineString',
          'coordinates': coords,
        },
      };
    }).toList();

    final fc = {
      'type': 'FeatureCollection',
      'features': features,
    };
    return const JsonEncoder.withIndent('  ').convert(fc);
  }

  Map<String, dynamic> _normalizeProps(Map<String, dynamic> m) {
    final out = <String, dynamic>{};
    for (final e in m.entries) {
      final k = e.key.trim();
      out[k] = e.value;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
        ScheduleRoadCubit,
        ScheduleRoadState,
        ({
        bool initialized,
        bool savingOrImporting,
        double mapZoom,
        List<LatLng> axis,
        List lanes,
        String currentServiceKey,
        Map<int, Map<int, ScheduleRoadData>> execIndex,
        })>(
      selector: (st) => (
      initialized: st.initialized,
      savingOrImporting: st.savingOrImporting,
      mapZoom: st.mapZoom,
      axis: st.axis,
      lanes: st.lanes,
      currentServiceKey: st.currentServiceKey,
      execIndex: st.execIndex,
      ),
      builder: (context, sel) {
        if (!sel.initialized || sel.savingOrImporting) {
          return const MapLoadingShimmer();
        }

        final segmented =
        _getSegmented(axis: sel.axis, stepMeters: 20.0, zoom: sel.mapZoom);
        final stFull = context.read<ScheduleRoadCubit>().state;

        // constroi os segmentos por faixa
        final laneSegments = _buildLanePolylines(
          segmented: segmented,
          lanes: sel.lanes,
          st: stFull,
        );

        // aplica seleção (múltipla) e amplia área de toque
        final styled = _applySelectionStyle(laneSegments, _selectedTags);
        final tappables = _withTapHelpers(styled);

        // markers de estacas
        final showStakes = sel.mapZoom >= 14.0;
        final stakeMarkers = (!showStakes || sel.axis.isEmpty)
            ? const <TaggedChangedMarker<Map<String, dynamic>>>[]
            : buildStakeMarkersUprightWithTickRight(
          axis: sel.axis,
          stepMeters: 20.0,
          zoom: sel.mapZoom,
          minLabelPixelGap: dynamicStakeGapPx(
            axis: sel.axis,
            zoom: sel.mapZoom,
            stepMeters: 20.0,
            bubbleWidthPx: 34.0,
            marginPx: 8.0,
          ),
        );

        // ===== Mapa base (SEM painel interno) =====
        return RepaintBoundary(
          child: Stack(
            children: [
              MapInteractivePage<Map<String, dynamic>>(
                showSearch: true,
                showChangeMapType: true,
                showMyLocation: true,
                searchTargetZoom: 16,
                showSearchMarker: true,
                tappablePolylines: tappables,
                overlayBuilder: (mc, _) => IgnorePointer(
                  ignoring: true,
                  child: ZoomListener(mapController: mc),
                ),
                onClearPolylineSelection: () async {
                  setState(() => _selectedTags.clear());
                  context.read<ScheduleRoadCubit>().setSelectedPolyline(null);
                },
                onSelectPolyline: (pl) async {
                  final tag = pl.tag?.toString();
                  if (tag == null) return;

                  final parsed = _parseLaneSegFromTag(tag);

                  if (_multiSelectMode) {
                    setState(() {
                      if (_selectedTags.contains(tag)) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                    return; // não abre modal no modo múltiplo
                  }

                  // modo normal: abre modal de célula única (se possível parsear)
                  setState(() {
                    _selectedTags
                      ..clear()
                      ..add(tag);
                  });
                  context.read<ScheduleRoadCubit>().setSelectedPolyline(tag);

                  if (parsed != null) {
                    await _openSingleSegmentModal(
                      st: context.read<ScheduleRoadCubit>().state,
                      faixaIndex: parsed.faixaIndex,
                      segIdx: parsed.segIdx,
                    );
                  }
                },
                taggedMarkers: stakeMarkers,
                clusterWidgetBuilder: (tagged, selectedPos, onSel) =>
                    _stakesLayer(markers: tagged),
              ),

              // ===== FABs seleção múltipla / aplicar em lote =====
              Positioned(
                left: 12,
                bottom: 12,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle seleção múltipla
                      Tooltip(
                        message: _multiSelectMode
                            ? 'Sair da seleção múltipla'
                            : 'Ativar seleção múltipla',
                        child: FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _multiSelectMode = !_multiSelectMode;
                              if (!_multiSelectMode) _selectedTags.clear();
                            });
                            _toast(
                              _multiSelectMode
                                  ? 'Modo seleção múltipla. Toque em segmentos para marcar.'
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

                      // Aplicar em lote (apenas no modo múltiplo)
                      if (_multiSelectMode)
                        Tooltip(
                          message: _selectedTags.length >= 2
                              ? 'Aplicar em lote'
                              : 'Selecione ao menos 2 segmentos',
                          child: Badge(
                            isLabelVisible: _selectedTags.isNotEmpty,
                            label: Text('${_selectedTags.length}'),
                            offset: const Offset(-6, 0),
                            child: FilledButton.icon(
                              onPressed: _selectedTags.length >= 2
                                  ? _openBulkModalFromSelected
                                  : null,
                              icon: const Icon(Icons.done_all, size: 18),
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
                                tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
