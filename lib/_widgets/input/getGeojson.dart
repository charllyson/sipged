import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class GeojsonViewer extends StatefulWidget {
  const GeojsonViewer({super.key});

  @override
  State<GeojsonViewer> createState() => _GeojsonViewerState();
}

class _GeojsonViewerState extends State<GeojsonViewer> {
  String? _nomeArquivoSelecionado;
  List<LatLng> _pontos = [];
  List<LatLng> _linha = [];
  List<List<LatLng>> _poligonos = [];

  void _uploadGeoJsonWeb() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.geojson,.json';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) async {
        final content = reader.result as String;
        await _parseGeoJsonWeb(content);

        setState(() {
          _nomeArquivoSelecionado = file.name;
        });
      });

      reader.readAsText(file);
    });
  }

  Future<void> _parseGeoJsonWeb(String content) async {
    final decoded = json.decode(content);
    final features = decoded['features'] as List;

    _pontos.clear();
    _linha.clear();
    _poligonos.clear();

    for (var feature in features) {
      final geometry = feature['geometry'];
      if (geometry == null) continue; // ✅ ignora features sem geometria

      final coords = geometry['coordinates'];
      final type = geometry['type'];

      if (type == 'Point') {
        _pontos.add(LatLng(coords[1], coords[0]));
      } else if (type == 'LineString') {
        for (var coord in coords) {
          _linha.add(LatLng(coord[1], coord[0]));
        }
      } else if (type == 'Polygon') {
        for (var ring in coords) {
          final pontosAnel = <LatLng>[];
          for (var coord in ring) {
            pontosAnel.add(LatLng(coord[1], coord[0]));
          }
          _poligonos.add(pontosAnel);
        }
      }
    }
  }

  void _limpar() {
    setState(() {
      _nomeArquivoSelecionado = null;
      _pontos.clear();
      _linha.clear();
      _poligonos.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPoints = [..._pontos, ..._linha, ..._poligonos.expand((p) => p)];

    final bounds = () {
      if (allPoints.length >= 2) {
        final b = LatLngBounds(allPoints.first, allPoints[1]);
        for (final p in allPoints) {
          b.extend(p);
        }
        return b;
      } else if (allPoints.length == 1) {
        return LatLngBounds(allPoints.first, allPoints.first);
      } else {
        return LatLngBounds(LatLng(0, 0), LatLng(0, 0));
      }
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _uploadGeoJsonWeb,
              icon: const Icon(Icons.upload_file),
              label: const Text("Selecionar GeoJSON (Web)"),
            ),
            const SizedBox(width: 12),
            if (_nomeArquivoSelecionado != null)
              ElevatedButton.icon(
                onPressed: _limpar,
                icon: const Icon(Icons.clear),
                label: const Text("Limpar"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              ),
          ],
        ),
        if (_nomeArquivoSelecionado != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("Arquivo: $_nomeArquivoSelecionado"),
          ),
        const SizedBox(height: 12),
        if (allPoints.isNotEmpty)
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                bounds: allPoints.length >= 2 ? bounds : null,
                center: allPoints.length == 1 ? allPoints.first : null,
                zoom: allPoints.length == 1 ? 15 : null,
                boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(16)),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                if (_pontos.isNotEmpty)
                  MarkerLayer(
                    markers: _pontos.map((p) => Marker(
                      point: p,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red),
                    )).toList(),
                  ),
                if (_linha.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: _linha, strokeWidth: 4, color: Colors.blue),
                    ],
                  ),
                if (_poligonos.isNotEmpty)
                  PolygonLayer(
                    polygons: _poligonos.map((ring) => Polygon(
                      points: ring,
                      color: Colors.green.withOpacity(0.4),
                      borderColor: Colors.green,
                      borderStrokeWidth: 2,
                    )).toList(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
