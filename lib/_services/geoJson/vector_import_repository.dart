// lib/_services/geoJson/vector_import_repository.dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart' as archive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

import 'vector_import_data.dart';

class VectorImportRepository {
  Future<List<Map<String, dynamic>>> pickAndParseRawFeatures() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['geojson', 'json', 'kml', 'kmz'],
    );

    if (result == null) {
      throw Exception('Importação cancelada pelo usuário');
    }

    final file = result.files.first;
    final ext = (file.extension ?? '').toLowerCase();
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();

    if (ext == 'geojson' || ext == 'json') {
      return _featuresFromGeoJsonBytes(bytes);
    } else if (ext == 'kml' || ext == 'kmz') {
      return await _featuresFromKmlOrKmzBytes(bytes, file.name);
    } else {
      throw Exception('Formato não suportado: .$ext');
    }
  }

  // ---------------------------------------------------------------------------
  // Conversão de raw features -> ImportedFeatureData + columns
  // ---------------------------------------------------------------------------
  (List<ImportedFeatureData>, List<ImportColumnMeta>) buildImportedFeatures(
      List<Map<String, dynamic>> rawFeatures,
      ) {
    if (rawFeatures.isEmpty) {
      return ([], []);
    }

    // propriedades-base (a partir da primeira linha)
    final firstProps =
    Map<String, dynamic>.from(rawFeatures.first['properties'] ?? {});
    final columns = firstProps.keys
        .map(
          (name) => ImportColumnMeta(
        name: name,
        selected: true,
        type: TypeFieldGeoJson.string,
      ),
    )
        .toList();

    final features = <ImportedFeatureData>[];

    for (final feat in rawFeatures) {
      final props = Map<String, dynamic>.from(feat['properties'] ?? {});
      final geometry = feat['geometry'] ?? {};
      final geometryType = geometry['type'] ?? 'LineString';
      final coords = geometry['coordinates'];

      final points = _convertToLatLngList(geometryType, coords);
      final geoPoints = points
          .map(
            (p) => GeoPoint(p.latitude, p.longitude),
      )
          .toList();

      final colTypes = {
        for (final c in columns) c.name: c.type,
      };

      features.add(
        ImportedFeatureData(
          originalProperties: props,
          editedProperties: Map<String, dynamic>.from(props),
          columnTypes: colTypes,
          selected: true,
          saveGeometry: true,
          // nome "default" caso o usuário NÃO mapeie para outro campo (ex.: points)
          geometryFieldName: 'points',
          geometryPoints: geoPoints,
          geometryType: geometryType,
        ),
      );
    }

    return (features, columns);
  }

  // ---------------------------------------------------------------------------
  // Salvamento em Firestore
  // ---------------------------------------------------------------------------
  Future<void> saveToCollection({
    required String collectionPath,
    required List<ImportedFeatureData> features,
    required void Function(double progress) onProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final col = FirebaseFirestore.instance.collection(collectionPath);

    // apenas features marcadas como selecionadas
    final selecionadas =
    features.where((f) => f.selected == true).toList(growable: false);
    final total = selecionadas.length;
    if (total == 0) return;

    var salvas = 0;

    for (final feat in selecionadas) {
      final docRef = col.doc();
      // começa dos editedProperties já tratados pelo mapeamento
      final data = Map<String, dynamic>.from(feat.editedProperties);

      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = uid;
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['updatedBy'] = uid;
      data['geometryType'] = feat.geometryType;

      // -------------------------------------------------------------------
      // GEOMETRIA
      // -------------------------------------------------------------------
      // Caso o usuário tenha mapeado explicitamente a geometria para
      // algum campo (ex.: "points"), o _applyFieldMapping já colocou
      // `geometryPoints` naquele campo.
      //
      // Aqui só adicionamos o campo "default" (geometryFieldName)
      // se NÃO houver nenhum campo recebendo a geometria ainda.
      //
      final hasGeometryInProps = data.values.any(
            (v) => v is List && v.isNotEmpty && v.first is GeoPoint,
      );

      if (feat.saveGeometry &&
          feat.geometryPoints.isNotEmpty &&
          !hasGeometryInProps) {
        // fallback: salva em geometryFieldName (ex.: "points")
        data[feat.geometryFieldName] = feat.geometryPoints;
      }

      await docRef.set(data, SetOptions(merge: true));

      salvas++;
      onProgress(salvas / total);
    }
  }

  // ==================== Helpers privados ====================

  // GeoJSON
  List<Map<String, dynamic>> _featuresFromGeoJsonBytes(List<int> bytes) {
    final Map<String, dynamic> geoJson = json.decode(utf8.decode(bytes));
    final type = geoJson['type'];

    if (type == 'FeatureCollection') {
      final feats = (geoJson['features'] as List?) ?? const [];
      return feats.whereType<Map<String, dynamic>>().toList();
    }
    if (type == 'Feature') {
      return [geoJson.cast<String, dynamic>()];
    }
    if (type == 'LineString' || type == 'MultiLineString') {
      return [
        {
          'type': 'Feature',
          'properties': const <String, dynamic>{},
          'geometry': geoJson,
        }
      ];
    }
    return const <Map<String, dynamic>>[];
  }

  // KML/KMZ
  Future<List<Map<String, dynamic>>> _featuresFromKmlOrKmzBytes(
      List<int> bytes,
      String filename,
      ) async {
    try {
      String kmlText;
      if (filename.toLowerCase().endsWith('.kmz')) {
        final zip = archive.ZipDecoder().decodeBytes(bytes);
        final entry = zip.firstWhere(
              (e) => e.name.toLowerCase().endsWith('.kml'),
          orElse: () => throw Exception('KMZ sem .kml interno.'),
        );
        final data = entry.content as List<int>;
        kmlText = utf8.decode(data, allowMalformed: true);
      } else {
        kmlText = utf8.decode(bytes, allowMalformed: true);
      }
      return _featuresFromKmlText(kmlText);
    } catch (e) {
      throw Exception('Erro lendo KML/KMZ: $e');
    }
  }

  List<Map<String, dynamic>> _featuresFromKmlText(String kmlText) {
    final kmlDoc = xml.XmlDocument.parse(kmlText);

    final placemarks = kmlDoc.findAllElements('Placemark');
    final feats = <Map<String, dynamic>>[];

    for (final pm in placemarks) {
      final name = pm.getElement('name')?.innerText ?? '';
      final desc = pm.getElement('description')?.innerText ?? '';

      final props = <String, dynamic>{
        if (name.isNotEmpty) 'name': name,
        if (desc.isNotEmpty) 'description': desc,
      };

      final ext = pm.findElements('ExtendedData');
      for (final ed in ext) {
        for (final d in ed.findAllElements('Data')) {
          final k = d.getAttribute('name') ?? '';
          final v = d.getElement('value')?.innerText ?? '';
          if (k.isNotEmpty) props[k] = v;
        }
      }

      final multi = pm.findElements('MultiGeometry');
      final lineStrings = <List<List<double>>>[];

      void _collectFromNode(xml.XmlElement node) {
        for (final ls in node.findAllElements('LineString')) {
          final raw = ls.getElement('coordinates')?.innerText ?? '';
          final coords = _parseKmlCoordinates(raw);
          if (coords.isNotEmpty) lineStrings.add(coords);
        }
      }

      if (multi.isNotEmpty) {
        for (final m in multi) {
          _collectFromNode(m);
        }
      } else {
        _collectFromNode(pm);
      }

      if (lineStrings.isEmpty) continue;

      Map<String, dynamic> geometry;
      if (lineStrings.length == 1) {
        geometry = {'type': 'LineString', 'coordinates': lineStrings.first};
      } else {
        geometry = {'type': 'MultiLineString', 'coordinates': lineStrings};
      }

      feats.add({
        'type': 'Feature',
        'properties': props,
        'geometry': geometry,
      });
    }

    return feats;
  }

  List<List<double>> _parseKmlCoordinates(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final coords = <List<double>>[];
    for (final p in parts) {
      final t = p.split(',');
      if (t.length >= 2) {
        final lon = double.tryParse(t[0].trim());
        final lat = double.tryParse(t[1].trim());
        if (lat != null && lon != null) coords.add([lon, lat]);
      }
    }
    return coords;
  }

  List<LatLng> _convertToLatLngList(String type, dynamic coords) {
    final pontos = <LatLng>[];

    if (coords is List && coords.isNotEmpty) {
      if (type == 'MultiLineString') {
        for (final sub in coords) {
          for (final p in (sub as List)) {
            if (p is List && p.length >= 2) {
              pontos.add(
                LatLng(
                  (p[1] as num).toDouble(),
                  (p[0] as num).toDouble(),
                ),
              );
            }
          }
        }
      } else {
        for (final p in coords) {
          if (p is List && p.length >= 2) {
            pontos.add(
              LatLng(
                (p[1] as num).toDouble(),
                (p[0] as num).toDouble(),
              ),
            );
          }
        }
      }
    }

    return pontos;
  }
}
