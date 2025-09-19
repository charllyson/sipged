// lib/screens/sectors/planning/rightWay/planning_right_way_map.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:siged/_widgets/map/geometry/geometry_cell.dart';

import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// cluster animado
import 'package:siged/_widgets/map/clusters/cluster_animated_marker_widget.dart';
// pin com bico alinhado no bottom-center
import 'package:siged/_widgets/map/pin/pin_changed.dart';

// tooltip visual
import 'package:siged/_widgets/map/tooltip/tooltip_animated_card.dart';
import 'package:siged/_widgets/map/tooltip/tooltip_balloon_tip.dart';

import 'package:siged/_widgets/map/geometry/geometry_type.dart';

class PlanningRightWayPropertyMap extends StatefulWidget {
  final ContractData contractData;

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

  // apenas se o chamador não fornecer um notifier próprio
  late final ValueNotifier<String?> _localSelectedPropId;

  // zoom atual
  double _currentZoom = 9;

  StreamSubscription? _mapSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _propsSub;
  VoidCallback? _refreshListener;

  // ======== MapController ref (para overlay calcular posição) ========
  MapController? _mapControllerRef;

  // ======== Overlay do tooltip ========
  LatLng? _tooltipAnchor;                  // LatLng âncora do tooltip
  Offset? _tooltipScreenPos;               // posição de tela atual (pixel)
  List<MapEntry<String, String>> _tooltipEntries = const [];
  VoidCallback? _tooltipOnDetails;
  VoidCallback? _tooltipOnClose;

  @override
  void initState() {
    super.initState();
    _localSelectedPropId = ValueNotifier<String?>(null);

    _loadAllGeoFromStorage();
    _listenOwnersRealtime();

    // escuta refresh externo (ex.: controller.mapRefresh)
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

  String _detectKind(String fileName, String? contentType, Uint8List bytes) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.kml')) return 'kml';
    if (lower.endsWith('.kmz')) return 'kmz';
    if (lower.endsWith('.geojson') || lower.endsWith('.json')) return 'geojson';

    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('kml')) return 'kml';
    if (ct.contains('kmz') || ct.contains('zip')) return 'kmz';
    if (ct.contains('geo+json') || ct.contains('json')) return 'geojson';

    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) return 'kmz';
    final head =
    utf8.decode(bytes.take(64).toList(), allowMalformed: true).toLowerCase();
    if (head.contains('<kml')) return 'kml';
    if (head.trimLeft().startsWith('{')) return 'geojson';
    return 'unknown';
  }

  Future<List<Geom>> _parseGeometries(
      String name,
      Uint8List bytes,
      String kind,
      ) async {
    switch (kind) {
      case 'kml':
        return _parseKml(utf8.decode(bytes, allowMalformed: true));
      case 'kmz':
        return _parseKmz(bytes);
      case 'geojson':
        return _parseGeoJson(utf8.decode(bytes, allowMalformed: true));
      default:
        return const [];
    }
  }

  List<Geom> _parseGeoJson(String text) {
    final data = json.decode(text) as Map<String, dynamic>;
    final List<Geom> out = [];

    void addLine(List coords) {
      final pts = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          pts.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
      }
      if (pts.length >= 2) out.add(Geom.line(pts));
    }

    void addPoly(List coords) {
      if (coords.isEmpty) return;
      final ring = coords.first as List;
      final pts = <LatLng>[];
      for (final c in ring) {
        if (c is List && c.length >= 2) {
          pts.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
      }
      if (pts.length >= 3) out.add(Geom.polygon(pts));
    }

    void parseGeom(Map<String, dynamic> g) {
      final type = (g['type'] ?? '').toString();
      final coords = g['coordinates'];
      if (type == 'LineString' && coords is List) {
        addLine(coords);
      } else if (type == 'MultiLineString' && coords is List) {
        for (final ls in coords) {
          if (ls is List) addLine(ls);
        }
      } else if (type == 'Polygon' && coords is List) {
        addPoly(coords);
      } else if (type == 'MultiPolygon' && coords is List) {
        for (final pg in coords) {
          if (pg is List) addPoly(pg);
        }
      }
    }

    final type = (data['type'] ?? '').toString();
    if (type == 'FeatureCollection' && data['features'] is List) {
      for (final f in (data['features'] as List)) {
        if (f is Map<String, dynamic>) {
          final g = f['geometry'] as Map<String, dynamic>?;
          if (g != null) parseGeom(g);
        }
      }
    } else if (type == 'Feature' && data['geometry'] is Map<String, dynamic>) {
      parseGeom(data['geometry'] as Map<String, dynamic>);
    } else if (data['type'] is String && data['coordinates'] != null) {
      parseGeom(data);
    }

    return out;
  }

  List<Geom> _parseKml(String xml) {
    final List<Geom> out = [];

    Iterable<List<LatLng>> _extractLines() sync* {
      final reg = RegExp(
        r'<LineString[^>]*>.*?<coordinates>(.*?)</coordinates>.*?</LineString>',
        dotAll: true,
        caseSensitive: false,
      );
      for (final m in reg.allMatches(xml)) {
        final pts = _coordsToLatLng(m.group(1) ?? '');
        if (pts.length >= 2) yield pts;
      }
    }

    Iterable<List<LatLng>> _extractPolys() sync* {
      final reg = RegExp(
        r'<Polygon[^>]*>.*?<outerBoundaryIs>.*?<coordinates>(.*?)</coordinates>.*?</outerBoundaryIs>.*?</Polygon>',
        dotAll: true,
        caseSensitive: false,
      );
      for (final m in reg.allMatches(xml)) {
        final pts = _coordsToLatLng(m.group(1) ?? '');
        if (pts.length >= 3) yield pts;
      }
    }

    for (final ls in _extractLines()) {
      out.add(Geom.line(ls));
    }
    for (final pg in _extractPolys()) {
      out.add(Geom.polygon(pg));
    }
    return out;
  }

  Future<List<Geom>> _parseKmz(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    for (final f in archive.files) {
      if (f.isFile && f.name.toLowerCase().endsWith('.kml')) {
        final content =
        utf8.decode(f.content as List<int>, allowMalformed: true);
        return _parseKml(content);
      }
    }
    return const [];
  }

  List<LatLng> _coordsToLatLng(String coordsTxt) {
    final pts = <LatLng>[];
    final tokens = coordsTxt
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final t in tokens) {
      final p = t.split(',');
      if (p.length >= 2) {
        final lon = double.tryParse(p[0]);
        final lat = double.tryParse(p[1]);
        if (lat != null && lon != null) pts.add(LatLng(lat, lon));
      }
    }
    return pts;
  }

  // =================== RÓTULO DENTRO DO POLÍGONO (polylabel) ===================

  double _hypot(double a, double b) => math.sqrt(a * a + b * b);

  double _pointToSegDist(
      double x,
      double y,
      double x1,
      double y1,
      double x2,
      double y2,
      ) {
    final dx = x2 - x1, dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return _hypot(x - x1, y - y1);
    }

    var t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
    t = (t.clamp(0.0, 1.0)) as double;

    final px = x1 + t * dx;
    final py = y1 + t * dy;

    return _hypot(x - px, y - py);
  }

  double _pointToPolygonDist(double x, double y, List<LatLng> poly) {
    bool inside = false;
    double minDist = double.infinity;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].longitude, yi = poly[i].latitude;
      final xj = poly[j].longitude, yj = poly[j].latitude;

      final intersect =
          ((yi > y) != (yj > y)) &&
              (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;

      final dist = _pointToSegDist(x, y, xi, yi, xj, yj);
      if (dist < minDist) minDist = dist;
    }
    return (inside ? 1 : -1) * minDist;
  }

  ({double minX, double minY, double maxX, double maxY}) _bbox(
      List<LatLng> poly,
      ) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final p in poly) {
      final x = p.longitude, y = p.latitude;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  LatLng _polylabel(List<LatLng> polygon, {double precision = 1e-4}) {
    final b = _bbox(polygon);
    final double w = b.maxX - b.minX, h = b.maxY - b.minY;
    final double cellSize = math.min(w, h);
    if (cellSize == 0) return polygon.first;
    final double h2 = cellSize / 2;

    GeometryCell bestCell = GeometryCell(
      (b.minX + b.maxX) / 2,
      (b.minY + b.maxY) / 2,
      0,
      _pointToPolygonDist(
        (b.minX + b.maxX) / 2,
        (b.minY + b.maxY) / 2,
        polygon,
      ),
    );

    GeometryCell? best;
    final List<GeometryCell> queue = [];
    for (double x = b.minX; x < b.maxX; x += cellSize) {
      for (double y = b.minY; y < b.maxY; y += cellSize) {
        final c = GeometryCell(
          x + h2,
          y + h2,
          h2,
          _pointToPolygonDist(x + h2, y + h2, polygon),
        );
        queue.add(c);
        if (best == null || c.d > best!.d) best = c;
      }
    }
    if (best != null && best!.d > bestCell.d) bestCell = best!;

    queue.sort((a, b) => b.max.compareTo(a.max));
    final double tolerance = precision;

    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);

      if (cell.d > bestCell.d) bestCell = cell;

      if (cell.max - bestCell.d <= tolerance) continue;

      final h2c = cell.h / 2;
      for (final dx in [-h2c, h2c]) {
        for (final dy in [-h2c, h2c]) {
          final c = GeometryCell(
            cell.x + dx,
            cell.y + dy,
            h2c,
            _pointToPolygonDist(cell.x + dx, cell.y + dy, polygon),
          );
          queue.add(c);
        }
      }
      queue.sort((a, b) => b.max.compareTo(a.max));
    }

    return LatLng(bestCell.y, bestCell.x);
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

  // ======== Overlay helpers (usando APENAS MapController) ========

  // Projeta LatLng para "coordenada de mundo" (Web Mercator), em pixels na escala do zoom.
  ({double x, double y}) _mercatorProject(LatLng ll, double zoom) {
    const double tileSize = 256.0;
    final double scale = tileSize * math.pow(2.0, zoom).toDouble();

    // longitude: [-180,180] -> [0, scale]
    final double x = (ll.longitude + 180.0) / 360.0 * scale;

    // latitude -> mercator Y
    final double sinLat = math.sin(ll.latitude * math.pi / 180.0);
    final double y = (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;

    return (x: x, y: y);
  }

  // Recalcula a posição do tooltip na tela (sem usar MapController.project / MapCamera.latLngToScreenPoint)
  void _recomputeTooltipScreenPos(MapController? mapController) {
    if (_tooltipAnchor == null || mapController == null) return;

    final cam = mapController.camera;
    final size = cam.nonRotatedSize;         // tamanho do mapa (sem rotação)
    final zoom = cam.zoom;
    final center = cam.center;

    // mundo (pixels na escala do zoom) do centro e do ponto alvo
    final c = _mercatorProject(center, zoom);
    final p = _mercatorProject(_tooltipAnchor!, zoom);

    // origem dos pixels visíveis (top-left) = mundo(centro) - metade do tamanho do mapa
    final originX = c.x - size.width  / 2.0;
    final originY = c.y - size.height / 2.0;

    // posição em tela = mundo(ponto) - origem
    final screenX = p.x - originX;
    final screenY = p.y - originY;

    setState(() {
      _tooltipScreenPos = Offset(screenX, screenY);
    });
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
  }

  void _closeTooltip() {
    setState(() {
      _tooltipAnchor = null;
      _tooltipScreenPos = null;
      _tooltipEntries = const [];
      _tooltipOnDetails = null;
      _tooltipOnClose = null;
    });
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

        // ponto de rótulo DENTRO do polígono
        final labelPoint = _polylabel(g.points, precision: 1e-4);

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
      // 1) Pré-carrega proprietários (id -> ownerName)
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

      // 2) Lista pastas de propriedades com geo
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

      // 3) Varre arquivos geo de cada propriedade
      for (final folder in geoFolders) {
        final propertyId = folder.parent?.name ?? '';
        final list = await folder.listAll();
        for (final item in list.items) {
          try {
            final url = await item.getDownloadURL();
            final dl = await _downloadWithType(url);
            final kind = _detectKind(item.name, dl.contentType, dl.bytes);
            final geoms = await _parseGeometries(item.name, dl.bytes, kind);

            final owner =
                _ownersByPropId[propertyId] ?? 'Proprietário não informado';

            _ingestGeometries(geoms, ownerName: owner, propertyId: propertyId);
          } catch (_) {
            // ignora itens problemáticos
          }
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

            // PIN visual (âncora no bottom-center do Marker)
            markerBuilder: (context, tagged) {
              final label =
                  (tagged.properties?['pinLabel'] as String?)?.trim() ?? 'IMV';
              return PinChanged(
                size: 36,
                color: const Color(0xFFE67E22),
                borderColor: const Color(0xFF5A3A12),
                showShadow: true,
                innerDot: true,
                label: label, // 3 letras
              );
            },

            // Título/Subtítulo do tooltip
            titleBuilder: (data) {
              final owner = (data['ownerName'] as String?) ??
                  (taggedMarkers
                      .firstWhere((m) => m.data == data)
                      .properties?['ownerName'] as String?) ??
                  'Proprietário';
              return owner;
            },
            subTitleBuilder: (data) => '', // opcional

            // Botão "Detalhes" → abre painel direito
            onViewDetails: (ctx, tagged) {
              final propId = tagged.data['propertyId'] as String?;
              if (propId == null || propId.isEmpty) return;
              widget.externalPanelController?.value = true; // abre painel
              widget.selectedPropertyIdNotifier?.value = propId; // carrega detalhes
            },

            // 👇 Abre tooltip em overlay no PAI (usa o MapController salvo)
            onShowTooltipAcima: ({
              required BuildContext context,
              required LatLng position,
              required List<MapEntry<String, String>> entries,
              VoidCallback? onDetails,
              VoidCallback? onClose,
            }) {
              _openTooltip(
                latLng: position,
                entries: entries,
                onDetails: onDetails,
                onClose: onClose,
                mapController: _mapControllerRef,
              );
            },

            onClearSelection: _closeTooltip,
          );
        },

        // ======== Overlay acima do mapa ========
        overlayBuilder: (mapController, _) {
          // guarda referência do mapController para uso em callbacks
          _mapControllerRef ??= mapController;

          // escuta eventos do mapa (zoom/pan) para manter o tooltip posicionado
          _mapSub ??= mapController.mapEventStream.listen((evt) {
            final z = evt.camera.zoom;
            if (z != _currentZoom && mounted) {
              setState(() => _currentZoom = z);
            }
            _recomputeTooltipScreenPos(mapController);
          });

          return Stack(
            children: [
              // barreira de clique-fora (só quando tooltip aberto)
              if (_tooltipScreenPos != null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _closeTooltip,
                    child: const SizedBox.shrink(),
                  ),
                ),

              // Tooltip posicionado por coordenada de tela
              if (_tooltipScreenPos != null)
                Positioned(
                  // centralize conforme sua largura/altura do card
                  left: _tooltipScreenPos!.dx - 140, // 280/2
                  top: _tooltipScreenPos!.dy - 145,  // sobe acima do pin
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TooltipAnimatedCard(
                        title: _tooltipEntries
                            .firstWhere(
                              (e) => e.key == 'title',
                          orElse: () => const MapEntry('title', 'Detalhe'),
                        )
                            .value,
                        subtitle: () {
                          final s = _tooltipEntries
                              .firstWhere(
                                (e) => e.key == 'subtitle',
                            orElse: () => const MapEntry('subtitle', ''),
                          )
                              .value
                              .trim();
                          return s.isEmpty ? null : s;
                        }(),
                        maxWidth: 280,
                        onDetails: _tooltipOnDetails,
                        onClose: _tooltipOnClose ?? _closeTooltip,
                      ),
                      const TooltipBalloonTip(color: Colors.black87, height: 6, width: 14),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
