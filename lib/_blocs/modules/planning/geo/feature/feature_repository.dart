import 'dart:convert';

import 'package:archive/archive.dart' as archive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart'
as vector_import_file_reader;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_enums.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_import.dart';
import 'package:xml/xml.dart' as xml;

import 'feature_data.dart';

class FeatureRepository {
  FeatureRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const int _batchChunkSize = 400;

  Future<List<FeatureData>> loadFeatures({
    required String layerId,
    required String collectionPath,
    int limit = 5000,
    String orderByField = 'updatedAt',
    bool orderDescending = false,
  }) async {
    final query = _firestore.collection(collectionPath);

    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await query
          .orderBy(orderByField, descending: orderDescending)
          .limit(limit)
          .get();
    } catch (_) {
      snap = await query.limit(limit).get();
    }

    final features = <FeatureData>[];

    for (final doc in snap.docs) {
      try {
        final feature = FeatureData.fromFirestore(
          docId: doc.id,
          layerId: layerId,
          map: doc.data(),
          selected: false,
        );

        if (feature.hasGeometry) {
          features.add(feature);
        }
      } catch (_) {
        // ignora documento inválido
      }
    }

    return List<FeatureData>.unmodifiable(features);
  }

  Future<List<String>> loadFieldNames({
    required String collectionPath,
    int limit = 300,
    String orderByField = 'updatedAt',
    bool orderDescending = false,
  }) async {
    final query = _firestore.collection(collectionPath);

    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await query
          .orderBy(orderByField, descending: orderDescending)
          .limit(limit)
          .get();
    } catch (_) {
      snap = await query.limit(limit).get();
    }

    final keys = <String>{};

    for (final doc in snap.docs) {
      final props = FeatureData.resolveProperties(doc.data());
      keys.addAll(props.keys);
    }

    final result = keys.toList()..sort();
    return List<String>.unmodifiable(result);
  }

  Future<List<Map<String, dynamic>>> pickAndParseRawFeatures() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['geojson', 'json', 'kml', 'kmz'],
      withData: true,
    );

    if (result == null) {
      throw Exception('Importação cancelada pelo usuário.');
    }

    final file = result.files.first;
    final ext = (file.extension ?? '').toLowerCase();

    final bytes = file.bytes ??
        await vector_import_file_reader.readBytes(
          Uri.file(file.path!),
        );

    switch (ext) {
      case 'geojson':
      case 'json':
        return _featuresFromGeoJsonBytes(bytes);

      case 'kml':
      case 'kmz':
        return _featuresFromKmlOrKmzBytes(bytes, file.name);

      default:
        throw Exception('Formato não suportado: .$ext');
    }
  }

  (List<FeatureData>, List<FeatureImport>) buildImportedFeatures(
      List<Map<String, dynamic>> rawFeatures,
      ) {
    if (rawFeatures.isEmpty) {
      return (const <FeatureData>[], const <FeatureImport>[]);
    }

    final keys = <String>{};
    final inferredTypes = <String, TypeFieldGeoJson>{};

    for (final raw in rawFeatures) {
      final props = FeatureData.resolveProperties(raw);

      keys.addAll(props.keys);

      for (final entry in props.entries) {
        inferredTypes[entry.key] = FeatureData.mergeInferredType(
          inferredTypes[entry.key],
          FeatureData.inferFieldType(entry.value),
        );
      }
    }

    final sortedKeys = keys.toList()..sort();

    final columns = sortedKeys
        .map(
          (name) => FeatureImport(
        name: name,
        selected: true,
        type: inferredTypes[name] ?? TypeFieldGeoJson.string,
      ),
    )
        .toList(growable: false);

    final features = rawFeatures.map((raw) {
      final feature = FeatureData.fromImportedRawFeature(raw);

      final edited = <String, dynamic>{
        for (final key in sortedKeys) key: feature.editedProperties[key],
      };

      final colTypes = <String, TypeFieldGeoJson>{
        for (final c in columns) c.name: c.type,
      };

      return feature.copyWith(
        editedProperties: edited,
        columnTypes: colTypes,
        selected: true,
      );
    }).toList(growable: false);

    return (
    List<FeatureData>.unmodifiable(features),
    List<FeatureImport>.unmodifiable(columns),
    );
  }

  Future<(List<FeatureData>, List<FeatureImport>)>
  loadFromFirestoreAsImportedFeatures({
    required String collectionPath,
    String? sourceLayerId,
    int limit = 2000,
    String orderByField = 'createdAt',
    bool orderDescending = true,
  }) async {
    final q = _firestore.collection(collectionPath);

    Future<QuerySnapshot<Map<String, dynamic>>> tryGet(bool withOrder) async {
      Query<Map<String, dynamic>> query = q;
      if (withOrder) {
        query = query.orderBy(orderByField, descending: orderDescending);
      }
      return query.limit(limit).get();
    }

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await tryGet(true);
    } catch (_) {
      snap = await tryGet(false);
    }

    final docs = snap.docs;
    if (docs.isEmpty) {
      return (const <FeatureData>[], const <FeatureImport>[]);
    }

    final keys = <String>{};
    final inferredTypes = <String, TypeFieldGeoJson>{};

    for (final doc in docs) {
      final props = FeatureData.resolveProperties(doc.data());

      for (final entry in props.entries) {
        keys.add(entry.key);
        inferredTypes[entry.key] = FeatureData.mergeInferredType(
          inferredTypes[entry.key],
          FeatureData.inferFieldType(entry.value),
        );
      }
    }

    final sortedKeys = keys.toList()..sort();

    final columns = sortedKeys
        .map(
          (name) => FeatureImport(
        name: name,
        selected: true,
        type: inferredTypes[name] ?? TypeFieldGeoJson.string,
      ),
    )
        .toList(growable: false);

    final features = <FeatureData>[];

    for (final doc in docs) {
      try {
        final data = doc.data();

        final resolvedLayerId = (sourceLayerId != null &&
            sourceLayerId.trim().isNotEmpty)
            ? sourceLayerId.trim()
            : (data['layerId'] ?? '').toString().trim();

        final feature = FeatureData.fromFirestore(
          docId: doc.id,
          layerId: resolvedLayerId,
          map: data,
          selected: false,
        );

        final edited = <String, dynamic>{
          for (final key in sortedKeys) key: feature.editedProperties[key],
        };

        final colTypes = <String, TypeFieldGeoJson>{
          for (final c in columns) c.name: c.type,
        };

        features.add(
          feature.copyWith(
            layerId: resolvedLayerId,
            editedProperties: edited,
            columnTypes: colTypes,
            selected: false,
          ),
        );
      } catch (_) {
        // ignora documento inválido
      }
    }

    return (
    List<FeatureData>.unmodifiable(features),
    List<FeatureImport>.unmodifiable(columns),
    );
  }

  Future<void> saveFeaturesToCollection({
    required String collectionPath,
    required List<FeatureData> features,
    required void Function(double progress) onProgress,
  }) async {
    if (features.isEmpty) return;

    final uid = _auth.currentUser?.uid ?? '';
    final col = _firestore.collection(collectionPath);

    int written = 0;
    onProgress(0.01);

    for (int i = 0; i < features.length; i += _batchChunkSize) {
      final end = (i + _batchChunkSize < features.length)
          ? i + _batchChunkSize
          : features.length;

      final chunk = features.sublist(i, end);
      final batch = _firestore.batch();

      for (final feature in chunk) {
        final isUpdate = feature.id != null && feature.id!.trim().isNotEmpty;
        final docRef = isUpdate ? col.doc(feature.id) : col.doc();

        final props = Map<String, dynamic>.from(feature.editedProperties);
        final geometry = FeatureData.encodeGeometryForFirestore(feature.rawGeometry);
        final searchTitle = _resolveSearchTitle(props, docRef.id);

        final data = <String, dynamic>{
          'id': docRef.id,
          if (feature.layerId != null && feature.layerId!.trim().isNotEmpty)
            'layerId': feature.layerId,
          'editor': props,
          'geometryType': feature.geometryTypeName,
          'geometry': geometry,
          'searchTitle': searchTitle,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        };

        if (!isUpdate) {
          data.addAll({
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': uid,
          });
        }

        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();

      written += chunk.length;
      onProgress((written / features.length).clamp(0.0, 1.0));
    }
  }

  Future<void> deleteFeaturesFromCollection({
    required String collectionPath,
    required List<String> docIds,
    required void Function(double progress) onProgress,
  }) async {
    if (docIds.isEmpty) return;

    final col = _firestore.collection(collectionPath);

    int deleted = 0;
    onProgress(0.01);

    for (int i = 0; i < docIds.length; i += _batchChunkSize) {
      final end = (i + _batchChunkSize < docIds.length)
          ? i + _batchChunkSize
          : docIds.length;
      final chunk = docIds.sublist(i, end);
      final batch = _firestore.batch();

      for (final id in chunk) {
        batch.delete(col.doc(id));
      }

      await batch.commit();

      deleted += chunk.length;
      onProgress((deleted / docIds.length).clamp(0.0, 1.0));
    }
  }

  Future<void> addPointFeaturesBatch({
    required String layerId,
    required String collectionPath,
    required List<LatLng> points,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    if (points.isEmpty) return;

    final uid = _auth.currentUser?.uid ?? '';
    final collection = _firestore.collection(collectionPath);

    for (int i = 0; i < points.length; i += _batchChunkSize) {
      final end =
      (i + _batchChunkSize < points.length) ? i + _batchChunkSize : points.length;
      final chunk = points.sublist(i, end);
      final batch = _firestore.batch();

      for (int j = 0; j < chunk.length; j++) {
        final globalIndex = i + j;
        final point = chunk[j];
        final doc = collection.doc();

        batch.set(doc, {
          'id': doc.id,
          'layerId': layerId,
          'editor': {
            ...commonProperties,
            'draftIndex': globalIndex + 1,
          },
          'geometryType': 'Point',
          'geometry': {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          },
          'searchTitle': '${commonProperties['title'] ?? 'Ponto'} ${globalIndex + 1}',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        });
      }

      await batch.commit();
    }
  }

  Future<void> addLineFeaturesBatch({
    required String layerId,
    required String collectionPath,
    required List<List<LatLng>> lines,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final validLines = lines.where((e) => e.length >= 2).toList(growable: false);
    if (validLines.isEmpty) return;

    final uid = _auth.currentUser?.uid ?? '';
    final collection = _firestore.collection(collectionPath);

    for (int i = 0; i < validLines.length; i += _batchChunkSize) {
      final end = (i + _batchChunkSize < validLines.length)
          ? i + _batchChunkSize
          : validLines.length;
      final chunk = validLines.sublist(i, end);
      final batch = _firestore.batch();

      for (int j = 0; j < chunk.length; j++) {
        final globalIndex = i + j;
        final line = chunk[j];
        final doc = collection.doc();

        batch.set(doc, {
          'id': doc.id,
          'layerId': layerId,
          'editor': {
            ...commonProperties,
            'draftIndex': globalIndex + 1,
          },
          'geometryType': 'LineString',
          'geometry': {
            'type': 'LineString',
            'coordinates': line
                .map((p) => [p.longitude, p.latitude])
                .toList(growable: false),
          },
          'searchTitle': '${commonProperties['title'] ?? 'Linha'} ${globalIndex + 1}',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        });
      }

      await batch.commit();
    }
  }

  Future<void> addPolygonFeaturesBatch({
    required String layerId,
    required String collectionPath,
    required List<List<LatLng>> polygons,
    Map<String, dynamic> commonProperties = const {},
  }) async {
    final validPolygons =
    polygons.where((e) => e.length >= 3).toList(growable: false);
    if (validPolygons.isEmpty) return;

    final uid = _auth.currentUser?.uid ?? '';
    final collection = _firestore.collection(collectionPath);

    for (int i = 0; i < validPolygons.length; i += _batchChunkSize) {
      final end = (i + _batchChunkSize < validPolygons.length)
          ? i + _batchChunkSize
          : validPolygons.length;
      final chunk = validPolygons.sublist(i, end);
      final batch = _firestore.batch();

      for (int j = 0; j < chunk.length; j++) {
        final globalIndex = i + j;
        final polygon = chunk[j];
        final doc = collection.doc();

        final closedRing = List<LatLng>.from(polygon);
        final first = closedRing.first;
        final last = closedRing.last;

        if (first.latitude != last.latitude || first.longitude != last.longitude) {
          closedRing.add(first);
        }

        batch.set(doc, {
          'id': doc.id,
          'layerId': layerId,
          'editor': {
            ...commonProperties,
            'draftIndex': globalIndex + 1,
          },
          'geometryType': 'Polygon',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              closedRing
                  .map((p) => [p.longitude, p.latitude])
                  .toList(growable: false),
            ],
          },
          'searchTitle':
          '${commonProperties['title'] ?? 'Polígono'} ${globalIndex + 1}',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        });
      }

      await batch.commit();
    }
  }

  List<Map<String, dynamic>> _featuresFromGeoJsonBytes(List<int> bytes) {
    final decoded = json.decode(utf8.decode(bytes));

    if (decoded is! Map<String, dynamic>) {
      throw Exception('GeoJSON inválido.');
    }

    final type = decoded['type'];

    if (type == 'FeatureCollection') {
      final feats = (decoded['features'] as List?) ?? const [];
      return feats
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }

    if (type == 'Feature') {
      return [decoded];
    }

    if (_isStandaloneGeometryType(type?.toString() ?? '')) {
      return [
        {
          'type': 'Feature',
          'properties': const <String, dynamic>{},
          'geometry': decoded,
        }
      ];
    }

    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _featuresFromKmlOrKmzBytes(
      List<int> bytes,
      String filename,
      ) {
    try {
      String kmlText;

      if (filename.toLowerCase().endsWith('.kmz')) {
        final zip = archive.ZipDecoder().decodeBytes(bytes);
        final entry = zip.firstWhere(
              (e) => e.name.toLowerCase().endsWith('.kml'),
          orElse: () => throw Exception('KMZ sem arquivo .kml interno.'),
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
      final name = pm.getElement('name')?.innerText.trim() ?? '';
      final desc = pm.getElement('description')?.innerText.trim() ?? '';

      final props = <String, dynamic>{
        if (name.isNotEmpty) 'name': name,
        if (desc.isNotEmpty) 'description': desc,
      };

      final ext = pm.findElements('ExtendedData');
      for (final ed in ext) {
        for (final d in ed.findAllElements('Data')) {
          final key = d.getAttribute('name') ?? '';
          final value = d.getElement('value')?.innerText ?? '';
          if (key.trim().isNotEmpty) {
            props[key.trim()] = value;
          }
        }
      }

      final multi = pm.findElements('MultiGeometry');

      final pointGeometries = <List<double>>[];
      final lineGeometries = <List<List<double>>>[];
      final polygonGeometries = <List<List<List<double>>>>[];

      void collect(xml.XmlElement node) {
        for (final pt in node.findAllElements('Point')) {
          final raw = pt.getElement('coordinates')?.innerText ?? '';
          final coords = _parseKmlCoordinates(raw);
          if (coords.isNotEmpty) {
            pointGeometries.add(coords.first);
          }
        }

        for (final ls in node.findAllElements('LineString')) {
          final raw = ls.getElement('coordinates')?.innerText ?? '';
          final coords = _parseKmlCoordinates(raw);
          if (coords.length >= 2) {
            lineGeometries.add(coords);
          }
        }

        for (final poly in node.findAllElements('Polygon')) {
          final outer = poly.findAllElements('outerBoundaryIs');
          for (final o in outer) {
            final raw =
            o.findAllElements('coordinates').map((e) => e.innerText).join(' ');
            final coords = _parseKmlCoordinates(raw);
            if (coords.length >= 3) {
              polygonGeometries.add([coords]);
            }
          }
        }
      }

      if (multi.isNotEmpty) {
        for (final m in multi) {
          collect(m);
        }
      } else {
        collect(pm);
      }

      Map<String, dynamic>? geometry;

      if (polygonGeometries.isNotEmpty) {
        geometry = polygonGeometries.length == 1
            ? {
          'type': 'Polygon',
          'coordinates': polygonGeometries.first,
        }
            : {
          'type': 'MultiPolygon',
          'coordinates': polygonGeometries,
        };
      } else if (lineGeometries.isNotEmpty) {
        geometry = lineGeometries.length == 1
            ? {
          'type': 'LineString',
          'coordinates': lineGeometries.first,
        }
            : {
          'type': 'MultiLineString',
          'coordinates': lineGeometries,
        };
      } else if (pointGeometries.isNotEmpty) {
        geometry = pointGeometries.length == 1
            ? {
          'type': 'Point',
          'coordinates': pointGeometries.first,
        }
            : {
          'type': 'MultiPoint',
          'coordinates': pointGeometries,
        };
      }

      if (geometry == null) continue;

      feats.add({
        'type': 'Feature',
        'properties': props,
        'geometry': geometry,
      });
    }

    return List<Map<String, dynamic>>.unmodifiable(feats);
  }

  List<List<double>> _parseKmlCoordinates(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final coords = <List<double>>[];
    for (final part in parts) {
      final tokens = part.split(',');
      if (tokens.length >= 2) {
        final lon = double.tryParse(tokens[0].trim());
        final lat = double.tryParse(tokens[1].trim());
        if (lat != null && lon != null) {
          coords.add([lon, lat]);
        }
      }
    }
    return coords;
  }

  bool _isStandaloneGeometryType(String type) {
    return const {
      'Point',
      'MultiPoint',
      'LineString',
      'MultiLineString',
      'Polygon',
      'MultiPolygon',
    }.contains(type);
  }

  String _resolveSearchTitle(Map<String, dynamic> props, String fallback) {
    const keys = [
      'title',
      'titulo',
      'name',
      'nome',
      'label',
      'descricao',
      'description',
      'codigo',
      'id',
    ];

    for (final key in keys) {
      final value = props[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }
}