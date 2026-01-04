// lib/screens/sectors/planning/rightWay/planning_right_way_map.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:siged/_services/geometry/geometry_utils.dart';

// === SIGED widgets ===
import 'package:siged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_blocs/_process/process_data.dart';

// cluster animado
import 'package:siged/_widgets/map/clusters/cluster_animated_marker_widget.dart';
// pin com bico alinhado no bottom-center
import 'package:siged/_widgets/map/pin/pin_changed.dart';

// tooltip visual

class PlanningRightWayPropertyMap extends StatefulWidget {
  final ProcessData contractData;

  /// Controla abrir/fechar o painel lateral (true = abrir).
  final ValueNotifier<bool>? externalPanelController;

  /// Notifica o id do imóvel selecionado (para o painel carregar os detalhes).
  final ValueNotifier<String?>? selectedPropertyIdNotifier;

  /// Notificador externo para forçar reload (ex.: controller.mapRefresh)
  final ValueListenable<Object?>? refreshListenable;

  const PlanningRightWayPropertyMap({
    super.key,
    required this.contractData,
    this.externalPanelController,
    this.selectedPropertyIdNotifier,
    this.refreshListenable,
  });

  @override
  State<PlanningRightWayPropertyMap> createState() =>
      _PlanningRightWayPropertyMapState();
}

class _PlanningRightWayPropertyMapState
    extends State<PlanningRightWayPropertyMap> {
  final _storage = FirebaseStorage.instance;
  final _db = FirebaseFirestore.instance;

  final List<Polygon> _polygons = [];
  final List<TappableChangedPolyline> _lines = [];

  // markers (pins) no ponto ótimo do polígono
  final List<TaggedChangedMarker<Map<String, dynamic>>> _markers = [];

  // cache idProp -> ownerName
  final Map<String, String> _ownersByPropId = {};

  bool _loading = true;
  String? _error;

  late final ValueNotifier<String?> _localSelectedPropId;

  StreamSubscription? _mapSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _propsSub;
  VoidCallback? _refreshListener;

  LatLng? _tooltipAnchor;                  // LatLng âncora (coincide com topo do chip)
  Offset? _tooltipScreenPos;               // posição de tela do LatLng
  List<MapEntry<String, String>> _tooltipEntries = const [];
  VoidCallback? _tooltipOnDetails;
  VoidCallback? _tooltipOnClose;

  final GlobalKey _tooltipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _localSelectedPropId = ValueNotifier<String?>(null);

    _loadAllGeoFromStorage();
    _listenOwnersRealtime();

    if (widget.refreshListenable != null) {
      _refreshListener = _reloadAll;
      widget.refreshListenable!.addListener(_refreshListener!);
    }
  }

  @override
  void didUpdateWidget(covariant PlanningRightWayPropertyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshListenable != widget.refreshListenable) {
      if (oldWidget.refreshListenable != null && _refreshListener != null) {
        oldWidget.refreshListenable!.removeListener(_refreshListener!);
      }
      if (widget.refreshListenable != null) {
        _refreshListener = _reloadAll;
        widget.refreshListenable!.addListener(_refreshListener!);
      } else {
        _refreshListener = null;
      }
    }
  }

  @override
  void dispose() {
    _mapSub?.cancel();
    _mapSub = null;

    _propsSub?.cancel();
    _propsSub = null;

    if (widget.refreshListenable != null && _refreshListener != null) {
      widget.refreshListenable!.removeListener(_refreshListener!);
    }

    _localSelectedPropId.dispose();
    super.dispose();
  }

  // ----------------------------- Realtime owners (labels) -----------------------------

  void _listenOwnersRealtime() {
    final contractId = widget.contractData.id;
    if (contractId == null || contractId.isEmpty) return;

    final propsCol = _db
        .collection('contracts')
        .doc(contractId)
        .collection('planning_right_way_properties')
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
      toFirestore: (data, _) => data,
    );

    _propsSub = propsCol.snapshots().listen((qs) {
      var changed = false;
      for (final d in qs.docs) {
        final owner = (d.data()['ownerName'] as String?)?.trim() ?? '';
        final old = _ownersByPropId[d.id];
        if (owner.isNotEmpty && owner != old) {
          _ownersByPropId[d.id] = owner;
          changed = true;
        }
      }
      if (changed && mounted) setState(() {});
    });
  }

  // ----------------------------- Reload all -----------------------------

  Future<void> _reloadAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _polygons.clear();
      _lines.clear();
      _markers.clear();
      _closeTooltip(); // fecha tooltip em reload
    });
    await _loadAllGeoFromStorage();
  }

  // ----------------------------- LOAD STORAGE + PROPRIETÁRIOS -----------------------------

  Future<({Uint8List bytes, String? contentType})> _downloadWithType(
      String url,
      ) async {
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return (bytes: r.bodyBytes, contentType: r.headers['content-type']);
  }

  // ------------------- INGEST + MARKERS (polylabel) -------------------

  void _ingestGeometries(
      List<Geom> geoms, {
        required String ownerName,
        required String propertyId,
      }) {
    for (final g in geoms) {
      if (g.type == GeometryType.line && g.points.length >= 2) {
        _lines.add(
          TappableChangedPolyline(
            points: g.points,
            color: Colors.redAccent,
            strokeWidth: 3.0,
            tag: 'Traçado',
          ),
        );
      } else if (g.type == GeometryType.polygon && g.points.length >= 3) {
        _polygons.add(
          Polygon<String>(
            points: g.points,
            hitValue: propertyId,
            color: Colors.orange.withOpacity(0.35),
            borderColor: Colors.orange,
            borderStrokeWidth: 1.2,
          ),
        );

        // ponto de rótulo DENTRO do polígono (polylabel util)
        final labelPoint = labelPointForPolygon(
          g.points,
          strategy: LabelPointStrategy.centroid,
          ensureInside: true,
          polylabelPrecision: 1e-6,
        );

        _markers.add(
          TaggedChangedMarker<Map<String, dynamic>>(
            point: labelPoint,
            data: {'propertyId': propertyId},
            properties: {
              'ownerName': ownerName,
              'pinLabel': _initials3(ownerName),
            },
          ),
        );
      }
    }
  }

  // ----------------------------- CARREGAMENTO do Storage -----------------------------

  Future<void> _loadAllGeoFromStorage() async {
    final contractId = widget.contractData.id;
    if (contractId == null || contractId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Contrato sem ID.';
      });
      return;
    }

    try {
      final propsCol = _db
          .collection('contracts')
          .doc(contractId)
          .collection('planning_right_way_properties');
      try {
        final q = await propsCol.get();
        for (final d in q.docs) {
          final data = d.data();
          final owner = (data['ownerName'] as String?)?.trim();
          if (owner != null && owner.isNotEmpty) {
            _ownersByPropId[d.id] = owner;
          }
        }
      } catch (_) {}

      final root = _storage.ref(
        'contracts/$contractId/planning_highway_domain/properties',
      );
      final propsLevel = await root.listAll();

      final List<Reference> geoFolders = [];
      for (final p in propsLevel.prefixes) {
        final geo = p.child('geo');
        try {
          final res = await geo.listAll();
          if (res.items.isNotEmpty) geoFolders.add(geo);
        } catch (_) {}
      }

      for (final folder in geoFolders) {
        final propertyId = folder.parent?.name ?? '';
        final list = await folder.listAll();
        for (final item in list.items) {
          try {
            final url = await item.getDownloadURL();
            final dl = await _downloadWithType(url);

            final kind = GeometryParsers.detectKind(item.name, dl.contentType, dl.bytes);
            final geoms = await GeometryParsers.parseGeometries(item.name, dl.bytes, kind);

            final owner =
                _ownersByPropId[propertyId] ?? 'Proprietário não informado';

            _ingestGeometries(geoms, ownerName: owner, propertyId: propertyId);
          } catch (_) {}
        }
      }

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Erro ao carregar arquivos do Storage: $e';
      });
    }
  }

  // ------------------- helpers -------------------

  String _initials3(String owner) {
    final tokens = owner
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return 'IMV';
    final letters = tokens.take(3).map((t) => t.characters.first).join();
    return letters.toUpperCase().padRight(3, ' ').substring(0, 3);
  }

  // ======== Overlay helpers ========

  void _recomputeTooltipScreenPos(MapController? mapController) {
    if (_tooltipAnchor == null || mapController == null) return;
    final cam = mapController.camera;
    final pos = MapMath.latLngToScreen(cam, _tooltipAnchor!);
    setState(() => _tooltipScreenPos = pos);
  }

  void _openTooltip({
    required LatLng latLng,
    required List<MapEntry<String, String>> entries,
    VoidCallback? onDetails,
    VoidCallback? onClose,
    MapController? mapController,
  }) {
    _tooltipAnchor = latLng;
    _tooltipEntries = entries;
    _tooltipOnDetails = onDetails;
    _tooltipOnClose = () {
      _closeTooltip();
      onClose?.call();
    };
    _recomputeTooltipScreenPos(mapController);

    // garante novo cálculo depois que o Card medir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recomputeTooltipScreenPos(mapController);
    });
  }

  void _closeTooltip() {
    if (!mounted) return;

    setState(() {
      _tooltipAnchor = null;
      _tooltipScreenPos = null;
      _tooltipEntries = const [];
      _tooltipOnDetails = null;
      _tooltipOnClose = null;
    });

    // 👇 DESSELECIONA e FECHA o painel de detalhes
    widget.selectedPropertyIdNotifier?.value = null;
    widget.externalPanelController?.value = false;
  }


  // ----------------------------- UI -----------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Carregando áreas...'),
              SizedBox(height: 12),
              CircularProgressIndicator(color: Colors.grey),
            ],
          ),
        ),
      );
    }
    if (_error != null) return Center(child: Text(_error!));

    return RepaintBoundary(
      child: MapInteractivePage<Map<String, dynamic>>(
        showSearch: true,
        searchTargetZoom: 16,
        showSearchMarker: true,

        polygon: _polygons,
        tappablePolylines: _lines,

        // pins dentro dos polígonos
        taggedMarkers: _markers,

        // camada de cluster/markers
        clusterWidgetBuilder: (
            taggedMarkers,
            selectedMarkerPosition,
            onMarkerSelected,
            ) {
          return ClusterAnimatedMarkerLayer<Map<String, dynamic>>(
            taggedMarkers: taggedMarkers,
            selectedMarkerPosition: selectedMarkerPosition,
            onMarkerSelected: onMarkerSelected,
            inlineTooltip: true,
            inlineMaxWidth: 240,
            inlineClearance: -45.0,
            markerAlignment: Alignment.topCenter,
            // PIN visual + cor por seleção
            markerBuilder: (context, tagged, isSelected) {
              final label = (tagged.properties['pinLabel'] as String?)?.trim() ?? 'IMV';
              final Color pinColor = isSelected ? Colors.amber.shade700 : Colors.black26;

              return PinChanged(
                size: 50,
                label: label,
                color: pinColor,
                halo: isSelected,
                haloOpacity: 0.20,
                haloScale: 1.85,
              );
            },
            // Título/Subtítulo do tooltip
            titleBuilder: (data) {
              final owner = (data['ownerName'] as String?) ??
                  (taggedMarkers.firstWhere((m) => m.data == data).properties['ownerName'] as String?) ??
                  'Proprietário';
              return owner;
            },
            subTitleBuilder: (data) => '',

            // Botão "Detalhes" → abre painel direito
            onViewDetails: (ctx, tagged) {
              final propId = tagged.data['propertyId'] as String?;
              if (propId == null || propId.isEmpty) return;
              widget.externalPanelController?.value = true;
              widget.selectedPropertyIdNotifier?.value = propId;
            },
            onClearSelection: _closeTooltip,
          );
        },
      ),
    );
  }
}
