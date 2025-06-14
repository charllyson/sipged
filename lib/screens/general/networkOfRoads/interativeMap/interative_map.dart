import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:latlong2/latlong.dart';

class InteractiveMapPage extends StatefulWidget {
  const InteractiveMapPage({super.key});

  @override
  State<InteractiveMapPage> createState() => _InteractiveMapPageState();
}

class _InteractiveMapPageState extends State<InteractiveMapPage> {
  List<Polygon> _polygons = [];
  List<TaggedPolyline> _polylines = [];
  bool _isLoading = true;
  String _selectedMapStyle = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Mapeamento das propriedades
  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadGeoJson();  // Carrega o GeoJSON inicial
  }

  // Função para carregar o GeoJSON
  Future<void> _loadGeoJson() async {
    final data = await rootBundle.loadString('assets/roads/all-roads.geojson');
    final geojson = json.decode(data);
    final features = geojson['features'] as List;

    final List<TaggedPolyline> loadedPolylines = [];
    final List<Polygon> loadedPolygons = [];

    // Processa cada feature no GeoJSON
    for (final feature in features) {
      final geometry = feature['geometry'];
      final type = geometry['type'];
      final coordinates = geometry['coordinates'];
      final properties = Map<String, dynamic>.from(feature['properties'] ?? {});

      if (type == 'Polygon') {
        final rings = List<List>.from(coordinates);
        for (final ring in rings) {
          final points = ring.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          final polygon = Polygon(
            points: points,
            color: Colors.green.withOpacity(0.3),
            borderColor: Colors.green,
            borderStrokeWidth: 3,
          );
          loadedPolygons.add(polygon);
        }
      } else if (type == 'MultiLineString') {
        final lines = List<List>.from(coordinates);
        for (final line in lines) {
          final points = line.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          final polyline = TaggedPolyline(
            points: points,
            tag: jsonEncode(properties),
            color: Colors.green,
            strokeWidth: 2,
          );
          loadedPolylines.add(polyline);
        }
      }
    }

    setState(() {
      _polylines = loadedPolylines;
      _polygons = loadedPolygons;
      _isLoading = false;
    });
  }

  // Função para carregar um novo GeoJSON
  Future<void> _loadNewGeoJson() async {
    final data = await rootBundle.loadString('assets/roads/new-roads.geojson'); // Novo arquivo
    final geojson = json.decode(data);
    final features = geojson['features'] as List;

    final List<TaggedPolyline> loadedPolylines = [];
    final List<Polygon> loadedPolygons = [];

    // Processa cada feature do novo GeoJSON
    for (final feature in features) {
      final geometry = feature['geometry'];
      final type = geometry['type'];
      final coordinates = geometry['coordinates'];
      final properties = Map<String, dynamic>.from(feature['properties'] ?? {});

      if (type == 'Polygon') {
        final rings = List<List>.from(coordinates);
        for (final ring in rings) {
          final points = ring.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          final polygon = Polygon(
            points: points,
            color: Colors.blue.withOpacity(0.3),
            borderColor: Colors.blue,
            borderStrokeWidth: 3,
          );
          loadedPolygons.add(polygon);
        }
      } else if (type == 'MultiLineString') {
        final lines = List<List>.from(coordinates);
        for (final line in lines) {
          final points = line.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          final polyline = TaggedPolyline(
            points: points,
            tag: jsonEncode(properties),
            color: Colors.blue,
            strokeWidth: 2,
          );
          loadedPolylines.add(polyline);
        }
      }
    }

    setState(() {
      _polylines.addAll(loadedPolylines);  // Adiciona novas linhas
      _polygons.addAll(loadedPolygons);    // Adiciona novos polígonos
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Interativo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: LatLng(-9.6071, -36.6701),
              zoom: 9.5,
            ),
            children: [
              TileLayer(urlTemplate: _selectedMapStyle),
              PolygonLayer(polygons: _polygons),
              TappablePolylineLayer(
                polylines: _polylines,
                onTap: (tappedLines, tapDetails) {},
              ),
            ],
          ),
          // Botão flutuante para carregar novo GeoJSON
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _loadNewGeoJson,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
