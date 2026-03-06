import 'dart:convert';

import 'package:archive/archive.dart' as archive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart' as vectorImportFileReader;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

import 'attributes_table_data.dart';

class AttributesTableRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AttributesTableRepository({
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
        await vectorImportFileReader.readBytes(
          Uri.file(file.path!),
        );

    if (ext == 'geojson' || ext == 'json') {
      return _featuresFromGeoJsonBytes(bytes);
    }

    if (ext == 'kml' || ext == 'kmz') {
      return _featuresFromKmlOrKmzBytes(bytes, file.name);
    }

    throw Exception('Formato não suportado: .$ext');
  }

  (List<AttributesTableData>, List<ImportColumnMeta>) buildImportedFeatures(
      List<Map<String, dynamic>> rawFeatures,
      ) {
    if (rawFeatures.isEmpty) return (const [], const []);

    final keys = <String>{};
    final inferredTypes = <String, TypeFieldGeoJson>{};

    for (final feat in rawFeatures) {
      final props = Map<String, dynamic>.from(feat['properties'] ?? {});
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

    final features = <AttributesTableData>[];

    for (final feat in rawFeatures) {
      final props = Map<String, dynamic>.from(feat['properties'] ?? {});
      final geometry = Map<String, dynamic>.from(feat['geometry'] ?? {});
      final geometryType = (geometry['type'] ?? 'LineString').toString();
      final coords = geometry['coordinates'];

      final partsLatLng = _convertToLatLngParts(geometryType, coords);
      final cleanPartsLatLng = partsLatLng.where((s) => s.length >= 2).toList(growable: false);

      final flatLatLng = <LatLng>[];
      for (final seg in cleanPartsLatLng) {
        flatLatLng.addAll(seg);
      }

      final geoPointsFlat = flatLatLng
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(growable: false);

      final geoParts = cleanPartsLatLng
          .map(
            (seg) => seg
            .map((p) => GeoPoint(p.latitude, p.longitude))
            .toList(growable: false),
      )
          .toList(growable: false);

      final colTypes = {
        for (final c in columns) c.name: c.type,
      };

      final edited = <String, dynamic>{};
      for (final k in sortedKeys) {
        edited[k] = props[k];
      }

      features.add(
        AttributesTableData(
          docId: null,
          originalProperties: props,
          editedProperties: edited,
          columnTypes: colTypes,
          selected: true,
          saveGeometry: true,
          geometryFieldName: 'points',
          geometryPoints: geoPointsFlat,
          geometryParts: geoParts,
          geometryType: geometryType,
        ),
      );
    }

    return (features, columns);
  }

  Future<(List<AttributesTableData>, List<ImportColumnMeta>)>
  loadFromFirestoreAsImportedFeatures({
    required String collectionPath,
    int limit = 2000,
    String geometryFieldName = 'points',
    String partsFieldName = 'parts',
    String orderByField = 'createdAt',
    bool orderDescending = true,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection(collectionPath);

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
      return (<AttributesTableData>[], <ImportColumnMeta>[]);
    }

    final keys = <String>{};
    final inferredTypes = <String, TypeFieldGeoJson>{};
    bool hasGeometry = false;

    for (final d in docs) {
      final data = d.data();

      for (final entry in data.entries) {
        final k = entry.key;
        final v = entry.value;

        if (k == geometryFieldName || k == partsFieldName) {
          if (v is List && v.isNotEmpty) {
            hasGeometry = true;
          }
          continue;
        }

        keys.add(k);
        inferredTypes[k] = _mergeInferredType(
          inferredTypes[k],
          _inferFieldType(v),
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

    final features = <AttributesTableData>[];

    for (final d in docs) {
      final data = Map<String, dynamic>.from(d.data());
      final docId = d.id;

      final geoParts = <List<GeoPoint>>[];
      final rawParts = data[partsFieldName];

      if (rawParts is List) {
        for (final item in rawParts) {
          if (item is Map) {
            final ptsRaw = item['pts'];
            if (ptsRaw is List) {
              final pts = <GeoPoint>[];
              for (final p in ptsRaw) {
                if (p is GeoPoint) pts.add(p);
              }
              if (pts.length >= 2) geoParts.add(pts);
            }
            continue;
          }

          if (item is List) {
            final pts = <GeoPoint>[];
            for (final p in item) {
              if (p is GeoPoint) pts.add(p);
            }
            if (pts.length >= 2) geoParts.add(pts);
          }
        }
      }

      final geoPoints = <GeoPoint>[];
      final rawGeom = data[geometryFieldName];
      if (rawGeom is List) {
        for (final v in rawGeom) {
          if (v is GeoPoint) geoPoints.add(v);
        }
      }

      final geoPointsFlat = geoPoints.isNotEmpty
          ? geoPoints
          : <GeoPoint>[
        for (final seg in geoParts) ...seg,
      ];

      final geometryType = (data['geometryType'] ?? '').toString();

      final edited = <String, dynamic>{};
      for (final k in sortedKeys) {
        edited[k] = data[k];
      }

      final colTypes = {
        for (final c in columns) c.name: c.type,
      };

      features.add(
        AttributesTableData(
          docId: docId,
          originalProperties: Map<String, dynamic>.from(edited),
          editedProperties: edited,
          columnTypes: colTypes,
          selected: false,
          saveGeometry: hasGeometry,
          geometryFieldName: geometryFieldName,
          geometryPoints: geoPointsFlat,
          geometryParts: geoParts,
          geometryType: geometryType,
        ),
      );
    }

    return (features, columns);
  }

  Future<void> saveToCollection({
    required String collectionPath,
    required List<AttributesTableData> features,
    required void Function(double progress) onProgress,
    String geometryTypeField = 'geometryType',
    String partsFieldName = 'parts',
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final col = _firestore.collection(collectionPath);

    final selecionadas = features.where((f) => f.selected).toList(growable: false);
    final total = selecionadas.length;
    if (total == 0) return;

    const chunkSize = 20;
    int written = 0;

    onProgress(0.01);

    for (int i = 0; i < selecionadas.length; i += chunkSize) {
      final end = (i + chunkSize < selecionadas.length) ? i + chunkSize : selecionadas.length;
      final chunk = selecionadas.sublist(i, end);

      final batch = _firestore.batch();

      for (final feat in chunk) {
        final docRef = col.doc();
        final data = Map<String, dynamic>.from(feat.editedProperties);

        data['id'] = docRef.id;
        data['createdAt'] = FieldValue.serverTimestamp();
        data['createdBy'] = uid;
        data['updatedAt'] = FieldValue.serverTimestamp();
        data['updatedBy'] = uid;
        data[geometryTypeField] = feat.geometryType;

        if (feat.saveGeometry && feat.geometryPoints.isNotEmpty) {
          data[feat.geometryFieldName] = feat.geometryPoints;
        }

        if (feat.saveGeometry && feat.geometryParts.isNotEmpty) {
          data[partsFieldName] = feat.geometryParts
              .where((seg) => seg.isNotEmpty)
              .map((seg) => <String, dynamic>{'pts': seg})
              .toList(growable: false);
        }

        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();

      written += chunk.length;
      onProgress((written / total).clamp(0.0, 1.0));
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

  List<Map<String, dynamic>> _featuresFromKmlOrKmzBytes(List<int> bytes, String filename) {
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

      void collect(xml.XmlElement node) {
        for (final ls in node.findAllElements('LineString')) {
          final raw = ls.getElement('coordinates')?.innerText ?? '';
          final coords = _parseKmlCoordinates(raw);
          if (coords.isNotEmpty) lineStrings.add(coords);
        }
      }

      if (multi.isNotEmpty) {
        for (final m in multi) {
          collect(m);
        }
      } else {
        collect(pm);
      }

      if (lineStrings.isEmpty) continue;

      final geometry = lineStrings.length == 1
          ? {'type': 'LineString', 'coordinates': lineStrings.first}
          : {'type': 'MultiLineString', 'coordinates': lineStrings};

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

  List<List<LatLng>> _convertToLatLngParts(String type, dynamic coords) {
    final parts = <List<LatLng>>[];

    if (coords is! List || coords.isEmpty) return parts;

    if (type == 'MultiLineString') {
      for (final sub in coords) {
        if (sub is! List) continue;

        final seg = <LatLng>[];
        for (final p in sub) {
          if (p is List && p.length >= 2) {
            seg.add(
              LatLng(
                (p[1] as num).toDouble(),
                (p[0] as num).toDouble(),
              ),
            );
          }
        }

        if (seg.length >= 2) parts.add(seg);
      }
      return parts;
    }

    final seg = <LatLng>[];
    for (final p in coords) {
      if (p is List && p.length >= 2) {
        seg.add(
          LatLng(
            (p[1] as num).toDouble(),
            (p[0] as num).toDouble(),
          ),
        );
      }
    }

    if (seg.length >= 2) parts.add(seg);
    return parts;
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
      if (double.tryParse(v.replaceAll(',', '.')) != null) return TypeFieldGeoJson.double_;
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

    if ((current == TypeFieldGeoJson.integer && next == TypeFieldGeoJson.double_) ||
        (current == TypeFieldGeoJson.double_ && next == TypeFieldGeoJson.integer)) {
      return TypeFieldGeoJson.double_;
    }

    return TypeFieldGeoJson.string;
  }
}