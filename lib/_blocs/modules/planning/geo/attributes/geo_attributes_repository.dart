import 'dart:convert';

import 'package:archive/archive.dart' as archive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart' as vector_import_file_reader;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xml/xml.dart' as xml;

import 'geo_attributes_data.dart';

class GeoAttributesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GeoAttributesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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

  (List<GeoAttributesData>, List<ImportColumnMeta>) buildImportedFeatures(
      List<Map<String, dynamic>> rawFeatures,
      ) {
    if (rawFeatures.isEmpty) return (const [], const []);

    final keys = <String>{};
    final inferredTypes = <String, TypeFieldGeoJson>{};

    for (final feat in rawFeatures) {
      final props = _resolveFeatureProperties(feat);
      keys.addAll(props.keys);

      props.forEach((key, value) {
        inferredTypes[key] = _mergeInferredType(
          inferredTypes[key],
          _inferFieldType(value),
        );
      });
    }

    final sortedKeys = keys.toList()..sort();

    final columns = sortedKeys
        .map(
          (name) => ImportColumnMeta(
        name: name,
        selected: true,
        type: inferredTypes[name] ?? TypeFieldGeoJson.string,
      ),
    )
        .toList(growable: false);

    final features = rawFeatures.map((feat) {
      final props = _resolveFeatureProperties(feat);
      final geometry = Map<String, dynamic>.from(feat['geometry'] ?? {});
      final geometryType = (geometry['type'] ?? 'Unknown').toString();

      final preview = _buildGeometryPreview(geometry);

      final colTypes = {
        for (final c in columns) c.name: c.type,
      };

      final edited = <String, dynamic>{
        for (final k in sortedKeys) k: props[k],
      };

      return GeoAttributesData(
        docId: null,
        originalProperties: props,
        editedProperties: edited,
        columnTypes: colTypes,
        selected: true,
        geometry: geometry,
        geometryType: geometryType,
        geometryPoints: preview.geometryPoints,
        geometryParts: preview.geometryParts,
      );
    }).toList(growable: false);

    return (features, columns);
  }

  Future<(List<GeoAttributesData>, List<ImportColumnMeta>)>
  loadFromFirestoreAsImportedFeatures({
    required String collectionPath,
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
      return (<GeoAttributesData>[], <ImportColumnMeta>[]);
    }

    final keys = <String>{};
    final inferredTypes = <String, TypeFieldGeoJson>{};

    for (final d in docs) {
      final data = d.data();
      final props = _resolveFirestoreProperties(data);

      for (final entry in props.entries) {
        keys.add(entry.key);
        inferredTypes[entry.key] = _mergeInferredType(
          inferredTypes[entry.key],
          _inferFieldType(entry.value),
        );
      }
    }

    final sortedKeys = keys.toList()..sort();

    final columns = sortedKeys
        .map(
          (name) => ImportColumnMeta(
        name: name,
        selected: true,
        type: inferredTypes[name] ?? TypeFieldGeoJson.string,
      ),
    )
        .toList(growable: false);

    final features = docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      final props = _resolveFirestoreProperties(data);

      final storedGeometry = Map<String, dynamic>.from(
        (data['geometry'] as Map?) ?? const <String, dynamic>{},
      );

      final geometry = _decodeGeometryFromFirestore(storedGeometry);
      final geometryType =
      (geometry['type'] ?? data['geometryType'] ?? '').toString();

      final preview = _buildGeometryPreview(geometry);

      final edited = <String, dynamic>{
        for (final k in sortedKeys) k: props[k],
      };

      final colTypes = {
        for (final c in columns) c.name: c.type,
      };

      return GeoAttributesData(
        docId: d.id,
        originalProperties: props,
        editedProperties: edited,
        columnTypes: colTypes,
        selected: false,
        geometry: geometry,
        geometryType: geometryType,
        geometryPoints: preview.geometryPoints,
        geometryParts: preview.geometryParts,
      );
    }).toList(growable: false);

    return (features, columns);
  }

  Future<void> saveToCollection({
    required String collectionPath,
    required List<GeoAttributesData> features,
    required void Function(double progress) onProgress,
  }) async {
    if (features.isEmpty) return;

    final uid = _auth.currentUser?.uid ?? '';
    final col = _firestore.collection(collectionPath);

    const chunkSize = 20;
    int written = 0;

    onProgress(0.01);

    for (int i = 0; i < features.length; i += chunkSize) {
      final end = (i + chunkSize < features.length) ? i + chunkSize : features.length;
      final chunk = features.sublist(i, end);

      final batch = _firestore.batch();

      for (final feat in chunk) {
        final isUpdate = feat.docId != null && feat.docId!.trim().isNotEmpty;
        final docRef = isUpdate ? col.doc(feat.docId) : col.doc();

        final props = Map<String, dynamic>.from(feat.editedProperties);
        final geometry = _encodeGeometryForFirestore(feat.geometry);
        final searchTitle = _resolveSearchTitle(props, docRef.id);

        final data = <String, dynamic>{
          'id': docRef.id,
          'editor': props,
          'geometryType': feat.geometryType,
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

  Future<void> deleteDocs({
    required String collectionPath,
    required List<String> docIds,
    required void Function(double progress) onProgress,
  }) async {
    if (docIds.isEmpty) return;

    final col = _firestore.collection(collectionPath);

    const chunkSize = 20;
    int deleted = 0;

    onProgress(0.01);

    for (int i = 0; i < docIds.length; i += chunkSize) {
      final end = (i + chunkSize < docIds.length) ? i + chunkSize : docIds.length;
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
          final k = d.getAttribute('name') ?? '';
          final v = d.getElement('value')?.innerText ?? '';
          if (k.trim().isNotEmpty) {
            props[k.trim()] = v;
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

    return feats;
  }

  Map<String, dynamic> _resolveFeatureProperties(Map<String, dynamic> feature) {
    final editor = feature['editor'];
    if (editor is Map) {
      return Map<String, dynamic>.from(editor);
    }

    final properties = feature['properties'];
    if (properties is Map) {
      return Map<String, dynamic>.from(properties);
    }

    final attributes = feature['attributes'];
    if (attributes is Map) {
      return Map<String, dynamic>.from(attributes);
    }

    return const <String, dynamic>{};
  }

  Map<String, dynamic> _resolveFirestoreProperties(Map<String, dynamic> data) {
    final editor = data['editor'];
    if (editor is Map && editor.isNotEmpty) {
      return Map<String, dynamic>.from(editor);
    }

    final properties = data['properties'];
    if (properties is Map && properties.isNotEmpty) {
      return Map<String, dynamic>.from(properties);
    }

    final attributes = data['attributes'];
    if (attributes is Map && attributes.isNotEmpty) {
      return Map<String, dynamic>.from(attributes);
    }

    final ignoredKeys = <String>{
      'id',
      'docId',
      'geometry',
      'geometryType',
      'searchTitle',
      'createdAt',
      'createdBy',
      'updatedAt',
      'updatedBy',
      'editor',
      'properties',
      'attributes',
    };

    final fallback = <String, dynamic>{};
    for (final entry in data.entries) {
      if (ignoredKeys.contains(entry.key)) continue;
      fallback[entry.key] = entry.value;
    }

    return fallback;
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
        if (lat != null && lon != null) {
          coords.add([lon, lat]);
        }
      }
    }
    return coords;
  }

  _GeometryPreview _buildGeometryPreview(Map<String, dynamic> geometry) {
    final type = (geometry['type'] ?? '').toString();
    final coords = geometry['coordinates'];

    switch (type) {
      case 'Point':
        final p = _geoPointFromCoordinate(coords);
        return _GeometryPreview(
          geometryPoints: p == null ? const [] : [p],
          geometryParts: p == null ? const [] : [
            [p]
          ],
        );

      case 'MultiPoint':
        final points = <GeoPoint>[];
        if (coords is List) {
          for (final item in coords) {
            final p = _geoPointFromCoordinate(item);
            if (p != null) points.add(p);
          }
        }
        return _GeometryPreview(
          geometryPoints: points,
          geometryParts: points.map((e) => [e]).toList(growable: false),
        );

      case 'LineString':
        final line = _geoPointListFromCoordinates(coords);
        return _GeometryPreview(
          geometryPoints: line,
          geometryParts: line.isEmpty ? const [] : [line],
        );

      case 'MultiLineString':
        final parts = <List<GeoPoint>>[];
        if (coords is List) {
          for (final segment in coords) {
            final seg = _geoPointListFromCoordinates(segment);
            if (seg.isNotEmpty) parts.add(seg);
          }
        }
        return _GeometryPreview(
          geometryPoints: parts.expand((e) => e).toList(growable: false),
          geometryParts: parts,
        );

      case 'Polygon':
        final rings = <List<GeoPoint>>[];
        if (coords is List) {
          for (final ring in coords) {
            final r = _geoPointListFromCoordinates(ring);
            if (r.isNotEmpty) rings.add(r);
          }
        }
        return _GeometryPreview(
          geometryPoints: rings.expand((e) => e).toList(growable: false),
          geometryParts: rings,
        );

      case 'MultiPolygon':
        final rings = <List<GeoPoint>>[];
        if (coords is List) {
          for (final polygon in coords) {
            if (polygon is List) {
              for (final ring in polygon) {
                final r = _geoPointListFromCoordinates(ring);
                if (r.isNotEmpty) rings.add(r);
              }
            }
          }
        }
        return _GeometryPreview(
          geometryPoints: rings.expand((e) => e).toList(growable: false),
          geometryParts: rings,
        );

      default:
        return const _GeometryPreview();
    }
  }

  GeoPoint? _geoPointFromCoordinate(dynamic raw) {
    if (raw is! List || raw.length < 2) return null;

    final lon = _toDouble(raw[0]);
    final lat = _toDouble(raw[1]);

    if (lat == null || lon == null) return null;
    return GeoPoint(lat, lon);
  }

  List<GeoPoint> _geoPointListFromCoordinates(dynamic raw) {
    if (raw is! List) return const [];

    final out = <GeoPoint>[];
    for (final item in raw) {
      final p = _geoPointFromCoordinate(item);
      if (p != null) out.add(p);
    }
    return out;
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

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
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

  TypeFieldGeoJson _inferFieldType(dynamic value) {
    if (value == null) return TypeFieldGeoJson.string;
    if (value is bool) return TypeFieldGeoJson.boolean;
    if (value is int) return TypeFieldGeoJson.integer;
    if (value is double || value is num) return TypeFieldGeoJson.double_;
    if (value is DateTime || value is Timestamp) return TypeFieldGeoJson.datetime;

    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) return TypeFieldGeoJson.string;

      final lower = v.toLowerCase();
      if (lower == 'true' ||
          lower == 'false' ||
          lower == 'sim' ||
          lower == 'não' ||
          lower == 'nao') {
        return TypeFieldGeoJson.boolean;
      }

      if (int.tryParse(v) != null) return TypeFieldGeoJson.integer;
      if (double.tryParse(v.replaceAll(',', '.')) != null) {
        return TypeFieldGeoJson.double_;
      }
      if (DateTime.tryParse(v) != null) return TypeFieldGeoJson.datetime;
    }

    return TypeFieldGeoJson.string;
  }

  TypeFieldGeoJson _mergeInferredType(
      TypeFieldGeoJson? current,
      TypeFieldGeoJson next,
      ) {
    if (current == null) return next;
    if (current == next) return current;

    if ((current == TypeFieldGeoJson.integer &&
        next == TypeFieldGeoJson.double_) ||
        (current == TypeFieldGeoJson.double_ &&
            next == TypeFieldGeoJson.integer)) {
      return TypeFieldGeoJson.double_;
    }

    return TypeFieldGeoJson.string;
  }

  Map<String, dynamic> _encodeGeometryForFirestore(Map<String, dynamic> geometry) {
    final type = (geometry['type'] ?? '').toString();
    final coords = geometry['coordinates'];

    switch (type) {
      case 'Point':
        return {
          'type': 'Point',
          'coordinates': _encodePoint(coords),
        };

      case 'MultiPoint':
        return {
          'type': 'MultiPoint',
          'coordinates': _encodePointList(coords),
        };

      case 'LineString':
        return {
          'type': 'LineString',
          'coordinates': _encodePointList(coords),
        };

      case 'MultiLineString':
        return {
          'type': 'MultiLineString',
          'coordinates': _encodeLineList(coords),
        };

      case 'Polygon':
        return {
          'type': 'Polygon',
          'coordinates': _encodeRingList(coords),
        };

      case 'MultiPolygon':
        return {
          'type': 'MultiPolygon',
          'coordinates': _encodePolygonList(coords),
        };

      default:
        return geometry;
    }
  }

  Map<String, dynamic> _decodeGeometryFromFirestore(Map<String, dynamic> geometry) {
    final type = (geometry['type'] ?? '').toString();
    final coords = geometry['coordinates'];

    switch (type) {
      case 'Point':
        return {
          'type': 'Point',
          'coordinates': _decodePoint(coords),
        };

      case 'MultiPoint':
        return {
          'type': 'MultiPoint',
          'coordinates': _decodePointList(coords),
        };

      case 'LineString':
        return {
          'type': 'LineString',
          'coordinates': _decodePointList(coords),
        };

      case 'MultiLineString':
        return {
          'type': 'MultiLineString',
          'coordinates': _decodeLineList(coords),
        };

      case 'Polygon':
        return {
          'type': 'Polygon',
          'coordinates': _decodeRingList(coords),
        };

      case 'MultiPolygon':
        return {
          'type': 'MultiPolygon',
          'coordinates': _decodePolygonList(coords),
        };

      default:
        return geometry;
    }
  }

  Map<String, dynamic>? _encodePoint(dynamic raw) {
    if (raw is! List || raw.length < 2) return null;

    final lng = _toDouble(raw[0]);
    final lat = _toDouble(raw[1]);
    if (lat == null || lng == null) return null;

    return {'lng': lng, 'lat': lat};
  }

  List<Map<String, dynamic>> _encodePointList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      final p = _encodePoint(item);
      if (p != null) out.add(p);
    }
    return out;
  }

  List<Map<String, dynamic>> _encodeLineList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final line in raw) {
      out.add({'points': _encodePointList(line)});
    }
    return out;
  }

  List<Map<String, dynamic>> _encodeRingList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final ring in raw) {
      out.add({'ring': _encodePointList(ring)});
    }
    return out;
  }

  List<Map<String, dynamic>> _encodePolygonList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <Map<String, dynamic>>[];
    for (final polygon in raw) {
      out.add({'rings': _encodeRingList(polygon)});
    }
    return out;
  }

  List<dynamic> _decodePoint(dynamic raw) {
    if (raw is Map) {
      final lng = _toDouble(raw['lng']);
      final lat = _toDouble(raw['lat']);
      if (lat != null && lng != null) {
        return [lng, lat];
      }
    }
    if (raw is List) return raw;
    return const [];
  }

  List<List<dynamic>> _decodePointList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <List<dynamic>>[];
    for (final item in raw) {
      final point = _decodePoint(item);
      if (point.length >= 2) out.add(point);
    }
    return out;
  }

  List<List<List<dynamic>>> _decodeLineList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <List<List<dynamic>>>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(_decodePointList(item['points']));
      } else if (item is List) {
        out.add(_decodePointList(item));
      }
    }
    return out;
  }

  List<List<List<dynamic>>> _decodeRingList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <List<List<dynamic>>>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(_decodePointList(item['ring']));
      } else if (item is List) {
        out.add(_decodePointList(item));
      }
    }
    return out;
  }

  List<List<List<List<dynamic>>>> _decodePolygonList(dynamic raw) {
    if (raw is! List) return const [];

    final out = <List<List<List<dynamic>>>>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(_decodeRingList(item['rings']));
      } else if (item is List) {
        out.add(_decodeRingList(item));
      }
    }
    return out;
  }
}

class _GeometryPreview {
  final List<GeoPoint> geometryPoints;
  final List<List<GeoPoint>> geometryParts;

  const _GeometryPreview({
    this.geometryPoints = const [],
    this.geometryParts = const [],
  });
}