// lib/screens/sectors/planning/rightWay/planning_right_way_map.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// 👉 cluster animado já usado no OAEs
import 'package:siged/_widgets/map/markers/animated_cluster_marker_widget.dart';

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
  final List<TaggedChangedMarker<Map<String, dynamic>>> _markers = [];

  // cache idProp -> ownerName
  final Map<String, String> _ownersByPropId = {};

  bool _loading = true;
  String? _error;

  // apenas se o chamador não fornecer um notifier próprio
  late final ValueNotifier<String?> _localSelectedPropId;
  ValueNotifier<String?> get _selectedPropNotifier =>
      widget.selectedPropertyIdNotifier ?? _localSelectedPropId;

  // zoom atual (se quiser reagir a zoom no futuro)
  double _currentZoom = 9;

  // Subscrições
  StreamSubscription? _mapSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _propsSub;
  VoidCallback? _refreshListener;

  @override
  void initState() {
    super.initState();
    _localSelectedPropId = ValueNotifier<String?>(null);

    // carrega geometrias inicialmente
    _loadAllGeoFromStorage();

    // escuta alterações do Firestore para atualizar labels dos markers
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
      if (changed) _updateMarkerLabels();
    });
  }

  void _updateMarkerLabels() {
    bool any = false;
    for (final m in _markers) {
      final propId = (m.properties['propertyId'] as String?) ?? '';
      final newOwner = _ownersByPropId[propId];
      if (newOwner != null && newOwner.isNotEmpty) {
        if (m.properties['label'] != newOwner) {
          m.properties['label'] = newOwner;
          m.data['owner'] = newOwner; // <- reflete no titleBuilder
          any = true;
        }
      }
    }
    if (any && mounted) setState(() {});
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
    });
    await _loadAllGeoFromStorage();
  }

  // ----------------------------- LOAD STORAGE + PROPRIETÁRIOS -----------------------------

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

            _ingestGeometries(geoms, label: owner, propertyId: propertyId);
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

  Future<({Uint8List bytes, String? contentType})> _downloadWithType(
      String url) async {
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
    final head = utf8.decode(bytes.take(64).toList(), allowMalformed: true).toLowerCase();
    if (head.contains('<kml')) return 'kml';
    if (head.trimLeft().startsWith('{')) return 'geojson';
    return 'unknown';
  }

  // ----------------------------- PARSERS -----------------------------

  Future<List<_Geom>> _parseGeometries(
      String name, Uint8List bytes, String kind) async {
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

  List<_Geom> _parseGeoJson(String text) {
    final data = json.decode(text) as Map<String, dynamic>;
    final List<_Geom> out = [];

    void addLine(List coords) {
      final pts = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          pts.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
      }
      if (pts.length >= 2) out.add(_Geom.line(pts));
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
      if (pts.length >= 3) out.add(_Geom.polygon(pts));
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

  List<_Geom> _parseKml(String xml) {
    final List<_Geom> out = [];

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
      out.add(_Geom.line(ls));
    }
    for (final pg in _extractPolys()) {
      out.add(_Geom.polygon(pg));
    }
    return out;
  }

  Future<List<_Geom>> _parseKmz(Uint8List bytes) async {
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

  // ------------------- INGEST + MARKERS (centróides + propriedades) -------------------

  void _ingestGeometries(
      List<_Geom> geoms, {
        required String label,
        required String propertyId,
      }) {
    for (final g in geoms) {
      if (g.type == _GeomType.line && g.points.length >= 2) {
        _lines.add(
          TappableChangedPolyline(
            points: g.points,
            color: Colors.redAccent,
            strokeWidth: 3.0,
            tag: 'Traçado',
          ),
        );
        _addMarker(_centroidLine(g.points), label, propertyId);
      } else if (g.type == _GeomType.polygon && g.points.length >= 3) {
        _polygons.add(
          Polygon(
            points: g.points,
            color: Colors.orange.withOpacity(0.35),
            borderColor: Colors.orange,
            borderStrokeWidth: 1.2,
          ),
        );
        _addMarker(_centroidPolygon(g.points), label, propertyId);
      }
    }
  }

  void _addMarker(LatLng? p, String ownerLabel, String propertyId) {
    if (p == null) return;
    _markers.add(
      TaggedChangedMarker<Map<String, dynamic>>(
        point: p,
        properties: {'label': ownerLabel, 'propertyId': propertyId},
        data: {
          'source': 'storage',
          'owner': ownerLabel,     // <- usado pelo titleBuilder
          'propertyId': propertyId // <- usado no onViewDetails
        },
      ),
    );
  }


  LatLng? _centroidLine(List<LatLng> pts) {
    if (pts.isEmpty) return null;
    double lat = 0, lon = 0;
    for (final p in pts) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return LatLng(lat / pts.length, lon / pts.length);
  }

  /// Centróide de polígono pelo método do "shoelace"
  LatLng? _centroidPolygon(List<LatLng> pts) {
    if (pts.length < 3) return null;

    // remove repetição final (polígonos fechados com último == primeiro)
    final clean = <LatLng>[];
    for (var i = 0; i < pts.length; i++) {
      if (i == pts.length - 1 &&
          (pts[i].latitude == pts.first.latitude &&
              pts[i].longitude == pts.first.longitude)) {
        break;
      }
      clean.add(pts[i]);
    }
    if (clean.length < 3) return null;

    double twiceArea = 0.0;
    double cx = 0.0;
    double cy = 0.0;

    for (var i = 0; i < clean.length; i++) {
      final j = (i + 1) % clean.length;
      final xi = clean[i].longitude;
      final yi = clean[i].latitude;
      final xj = clean[j].longitude;
      final yj = clean[j].latitude;

      final cross = (xi * yj) - (xj * yi);
      twiceArea += cross;
      cx += (xi + xj) * cross;
      cy += (yi + yj) * cross;
    }

    if (twiceArea == 0) {
      double lat = 0, lon = 0;
      for (final p in clean) {
        lat += p.latitude;
        lon += p.longitude;
      }
      return LatLng(lat / clean.length, lon / clean.length);
    }

    final area = twiceArea / 2.0;
    final centroidLon = cx / (6.0 * area);
    final centroidLat = cy / (6.0 * area);

    return LatLng(centroidLat, centroidLon);
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
        taggedMarkers: _markers,

        // 🍇 cluster animado com tooltip e "Ver detalhes"
        clusterWidgetBuilder: (taggedMarkers, selectedMarkerPosition, onMarkerSelected) {
          return AnimatedClusterMarkerLayer<Map<String, dynamic>>(
            taggedMarkers: taggedMarkers,
            selectedMarkerPosition: selectedMarkerPosition,
            onMarkerSelected: onMarkerSelected,

            // clicar fora / X: limpa com tolerância
            onClearSelection: () {
              final selPos = selectedMarkerPosition;
              if (selPos == null) return;

              // 1) igualdade com tolerância ~1.1 m
              const tol = 1e-5;
              final i1 = taggedMarkers.indexWhere((m) =>
              (m.point.latitude  - selPos.latitude ).abs() < tol &&
                  (m.point.longitude - selPos.longitude).abs() < tol
              );
              if (i1 != -1) {
                onMarkerSelected(taggedMarkers[i1]);
                return;
              }

              // 2) fallback: mais próximo dentro de ~5 m
              double best = double.infinity;
              int bestIdx = -1;
              for (int i = 0; i < taggedMarkers.length; i++) {
                final m = taggedMarkers[i];
                final dLat = m.point.latitude  - selPos.latitude;
                final dLon = m.point.longitude - selPos.longitude;
                final approx = dLat * dLat + dLon * dLon;
                if (approx < best) {
                  best = approx;
                  bestIdx = i;
                }
              }
              const maxApproxSq = 2e-9; // ~5 m^2 em graus^2
              if (bestIdx != -1 && best < maxApproxSq) {
                onMarkerSelected(taggedMarkers[bestIdx]);
              }
            },

            markerBuilder: (context, tagged) => const Icon(
              Icons.location_on, size: 28, color: Colors.deepPurple,
            ),
            titleBuilder: (data) =>
            (data['owner'] as String?) ?? 'Proprietário não informado',
            subTitleBuilder: (data) => 'Imóvel',
            onViewDetails: (ctx, marker) {
              final propId = (marker.data['propertyId'] as String?) ?? '';
              if (propId.isNotEmpty) {
                _selectedPropNotifier.value = propId;
                widget.externalPanelController?.value = true;
              }
            },
          );
        },



        // escuta zoom com inscrição única e cancela no dispose
        overlayBuilder: (mapController, _) {
          _mapSub ??= mapController.mapEventStream.listen((evt) {
            final z = evt.camera.zoom;
            if (z != _currentZoom && mounted) {
              setState(() => _currentZoom = z);
            }
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------- modelos internos ----------------

enum _GeomType { line, polygon }

class _Geom {
  final _GeomType type;
  final List<LatLng> points;

  const _Geom._(this.type, this.points);
  factory _Geom.line(List<LatLng> pts) => _Geom._(_GeomType.line, pts);
  factory _Geom.polygon(List<LatLng> pts) => _Geom._(_GeomType.polygon, pts);
}
