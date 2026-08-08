import 'dart:convert';

import 'package:archive/archive.dart' as archive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_image/extended_image.dart'
as vector_import_file_reader;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_import.dart';
import 'package:xml/xml.dart' as xml;

import 'feature_data.dart';
import 'feature_shapefile_reader.dart';

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

  static const List<String> _importAllowedExtensions = [
    'geojson',
    'json',
    'kml',
    'kmz',
    'zip',
    'shp',
    'dbf',
    'shx',
    'prj',
  ];

  Future<List<Map<String, dynamic>>> pickAndParseRawFeatures() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _importAllowedExtensions,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('Importação cancelada pelo usuário.');
    }

    final files = result.files;

    // Shapefile: usuário pode selecionar .shp + .dbf (+ .shx/.prj) juntos.
    final hasShp = files.any(
      (f) => (f.extension ?? '').toLowerCase() == 'shp',
    );

    if (hasShp) {
      final features = await _featuresFromShapefileParts(files);
      _logImportResult('SHP', features.length);
      _validateCoordinateSanity(features);
      return features;
    }

    final file = files.first;
    final ext = (file.extension ?? '').toLowerCase();

    final bytes = await _readFileBytes(file);

    switch (ext) {
      case 'geojson':
      case 'json':
        final features = _featuresFromGeoJsonBytes(bytes);
        _logImportResult('GeoJSON', features.length);
        _validateCoordinateSanity(features);
        return features;

      case 'kml':
      case 'kmz':
        final features = _featuresFromKmlOrKmzBytes(bytes, file.name);
        _logImportResult('KML/KMZ', features.length);
        _validateCoordinateSanity(features);
        return features;

      case 'zip':
        final features = await _featuresFromZipBundle(bytes);
        _logImportResult('ZIP (shapefile)', features.length);
        _validateCoordinateSanity(features);
        return features;

      default:
        throw Exception('Formato não suportado: .$ext');
    }
  }

  Future<List<int>> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;

    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      throw Exception(
        'Não foi possível ler os bytes do arquivo "${file.name}".',
      );
    }

    return vector_import_file_reader.readBytes(Uri.file(path));
  }

  void _logImportResult(String format, int count) {
    debugPrint(
      '[GEO import] $format: $count feição(ões) reconhecida(s) no arquivo.',
    );
  }

  /// Reúne bytes de .shp/.dbf/.prj a partir dos arquivos selecionados
  /// diretamente pelo usuário (sem zip).
  Future<List<Map<String, dynamic>>> _featuresFromShapefileParts(
    List<PlatformFile> files,
  ) async {
    PlatformFile? shp;
    PlatformFile? dbf;
    PlatformFile? prj;

    for (final f in files) {
      final ext = (f.extension ?? '').toLowerCase();
      if (ext == 'shp') shp ??= f;
      if (ext == 'dbf') dbf ??= f;
      if (ext == 'prj') prj ??= f;
    }

    if (shp == null) {
      throw Exception('Nenhum arquivo .shp selecionado.');
    }

    final shpBytes = await _readFileBytes(shp);
    final dbfBytes = dbf == null ? null : await _readFileBytes(dbf);
    final prjBytes = prj == null ? null : await _readFileBytes(prj);

    if (dbf == null) {
      debugPrint(
        '[GEO import] SHP: nenhum .dbf selecionado junto — as feições '
        'serão importadas sem atributos.',
      );
    }

    try {
      return ShapefileReader.readFeatures(
        shpBytes: shpBytes,
        dbfBytes: dbfBytes,
        prjBytes: prjBytes,
      );
    } catch (e) {
      throw Exception('Erro lendo Shapefile: $e');
    }
  }

  /// Trata um .zip genérico: procura um shapefile (.shp/.dbf/.prj) dentro
  /// dele. Também é o formato recomendado para importar Shapefile na web,
  /// já que evita depender de seleção múltipla de arquivos companheiros.
  Future<List<Map<String, dynamic>>> _featuresFromZipBundle(
    List<int> bytes,
  ) async {
    late final archive.Archive zip;
    try {
      zip = archive.ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw Exception('Erro lendo arquivo .zip: $e');
    }

    archive.ArchiveFile? shpEntry;
    archive.ArchiveFile? dbfEntry;
    archive.ArchiveFile? prjEntry;

    for (final entry in zip) {
      final lower = entry.name.toLowerCase();
      if (lower.endsWith('.shp')) shpEntry ??= entry;
      if (lower.endsWith('.dbf')) dbfEntry ??= entry;
      if (lower.endsWith('.prj')) prjEntry ??= entry;
    }

    if (shpEntry == null) {
      throw Exception('O arquivo .zip não contém um shapefile (.shp/.dbf).');
    }

    try {
      return ShapefileReader.readFeatures(
        shpBytes: shpEntry.content as List<int>,
        dbfBytes: dbfEntry?.content as List<int>?,
        prjBytes: prjEntry?.content as List<int>?,
      );
    } catch (e) {
      throw Exception('Erro lendo Shapefile: $e');
    }
  }

  /// Verificação leve de sanidade: se a maioria das coordenadas amostradas
  /// estiver fora do intervalo geográfico válido (lat [-90,90] / lng
  /// [-180,180]), o arquivo provavelmente está em uma projeção métrica
  /// (ex.: UTM) em vez de WGS84 — o que faria a geometria "desaparecer" do
  /// mapa silenciosamente. Lançamos um erro explicativo em vez disso.
  void _validateCoordinateSanity(List<Map<String, dynamic>> features) {
    var checked = 0;
    var outOfRange = 0;
    const sampleLimit = 300;

    void scan(dynamic node) {
      if (checked >= sampleLimit) return;

      if (node is List) {
        final isCoordPair = node.length >= 2 &&
            node.length <= 4 &&
            node.every((e) => e is num);

        if (isCoordPair) {
          checked++;
          final lng = (node[0] as num).toDouble();
          final lat = (node[1] as num).toDouble();
          if (lng < -180 || lng > 180 || lat < -90 || lat > 90) {
            outOfRange++;
          }
          return;
        }

        for (final child in node) {
          scan(child);
          if (checked >= sampleLimit) return;
        }
      }
    }

    for (final feature in features) {
      final geometry = feature['geometry'];
      if (geometry is Map) scan(geometry['coordinates']);
      if (checked >= sampleLimit) break;
    }

    if (checked > 0 && (outOfRange / checked) > 0.5) {
      throw Exception(
        'As coordenadas do arquivo não parecem estar em WGS84 '
        '(latitude/longitude). O arquivo provavelmente está em uma '
        'projeção métrica (ex.: UTM/SIRGAS 2000). Reprojete para '
        'EPSG:4326 antes de importar.',
      );
    }
  }

  (List<FeatureData>, List<FeatureImport>, int) buildImportedFeatures(
      List<Map<String, dynamic>> rawFeatures,
      ) {
    if (rawFeatures.isEmpty) {
      return (const <FeatureData>[], const <FeatureImport>[], 0);
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

    var skippedEmptyGeometry = 0;

    final features = <FeatureData>[];

    for (final raw in rawFeatures) {
      final feature = FeatureData.fromImportedRawFeature(raw);

      // Feições sem geometria válida (ex.: GeoJSON com geometria
      // desconhecida/mal formada) não são incluídas na pré-visualização.
      // Antes, elas seguiam até o Firestore com geometria vazia e só
      // "desapareciam" silenciosamente ao carregar a camada no mapa.
      if (!feature.hasGeometry) {
        skippedEmptyGeometry++;
        continue;
      }

      final edited = <String, dynamic>{
        for (final key in sortedKeys) key: feature.editedProperties[key],
      };

      final colTypes = <String, TypeFieldGeoJson>{
        for (final c in columns) c.name: c.type,
      };

      features.add(
        feature.copyWith(
          editedProperties: edited,
          columnTypes: colTypes,
          selected: true,
        ),
      );
    }

    if (skippedEmptyGeometry > 0) {
      debugPrint(
        '[GEO import] $skippedEmptyGeometry feição(ões) ignorada(s) por não '
        'terem geometria válida.',
      );
    }

    return (
    List<FeatureData>.unmodifiable(features),
    List<FeatureImport>.unmodifiable(columns),
    skippedEmptyGeometry,
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
    try {
      // `allowMalformed: true` evita que um BOM UTF-8 (comum em exportações
      // do Windows/QGIS/Excel) ou bytes fora do padrão estritamente UTF-8
      // derrubem a importação com um FormatException genérico.
      var text = utf8.decode(bytes, allowMalformed: true);

      // Remove um eventual BOM (Byte Order Mark) residual no início do texto.
      if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
        text = text.substring(1);
      }

      final decoded = json.decode(text);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('GeoJSON inválido: raiz não é um objeto.');
      }

      final type = decoded['type'];
      final features = <Map<String, dynamic>>[];

      if (type == 'FeatureCollection') {
        final feats = (decoded['features'] as List?) ?? const [];
        for (final raw in feats.whereType<Map>()) {
          features.addAll(
            _expandFeatureGeometryCollection(Map<String, dynamic>.from(raw)),
          );
        }
      } else if (type == 'Feature') {
        features.addAll(
          _expandFeatureGeometryCollection(Map<String, dynamic>.from(decoded)),
        );
      } else if (type == 'GeometryCollection') {
        features.addAll(
          _expandGeometryCollection(
            geometry: decoded,
            properties: const <String, dynamic>{},
          ),
        );
      } else if (_isStandaloneGeometryType(type?.toString() ?? '')) {
        features.add({
          'type': 'Feature',
          'properties': const <String, dynamic>{},
          'geometry': decoded,
        });
      }

      return List<Map<String, dynamic>>.unmodifiable(features);
    } on FormatException catch (e) {
      throw Exception(
        'Erro lendo GeoJSON: o arquivo não é um JSON válido ou está em uma '
        'codificação não suportada (esperado UTF-8). Detalhe: ${e.message}',
      );
    } catch (e) {
      throw Exception('Erro lendo GeoJSON: $e');
    }
  }

  /// Um `Feature` cuja `geometry` é um `GeometryCollection` não é
  /// representável pelo modelo interno de geometria única — em vez de
  /// silenciosamente virar geometria vazia (e desaparecer do mapa depois
  /// de salvo), expandimos em múltiplas `Feature`s (uma por sub-geometria),
  /// todas com as mesmas propriedades.
  List<Map<String, dynamic>> _expandFeatureGeometryCollection(
    Map<String, dynamic> feature,
  ) {
    final geometry = feature['geometry'];

    if (geometry is Map && geometry['type'] == 'GeometryCollection') {
      final properties = (feature['properties'] as Map?) ?? const {};
      return _expandGeometryCollection(
        geometry: Map<String, dynamic>.from(geometry),
        properties: Map<String, dynamic>.from(properties),
      );
    }

    return [feature];
  }

  List<Map<String, dynamic>> _expandGeometryCollection({
    required Map<String, dynamic> geometry,
    required Map<String, dynamic> properties,
  }) {
    final geometries = (geometry['geometries'] as List?) ?? const [];

    return geometries
        .whereType<Map>()
        .where((g) => _isStandaloneGeometryType((g['type'] ?? '').toString()))
        .map(
          (g) => {
            'type': 'Feature',
            'properties': properties,
            'geometry': Map<String, dynamic>.from(g),
          },
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _featuresFromKmlOrKmzBytes(
      List<int> bytes,
      String filename,
      ) {
    try {
      if (filename.toLowerCase().endsWith('.kmz')) {
        final zip = archive.ZipDecoder().decodeBytes(bytes);

        final kmlEntries = zip
            .where((e) => e.name.toLowerCase().endsWith('.kml'))
            .toList(growable: false);

        if (kmlEntries.isEmpty) {
          throw Exception('KMZ sem arquivo .kml interno.');
        }

        // Alguns pacotes KMZ trazem múltiplos .kml (doc.kml + overlays por
        // pasta). Para não perder feições, concatenamos os Placemarks de
        // todos os arquivos .kml encontrados, não apenas o primeiro.
        final feats = <Map<String, dynamic>>[];
        for (final entry in kmlEntries) {
          final data = entry.content as List<int>;
          final kmlText = utf8.decode(data, allowMalformed: true);
          try {
            feats.addAll(_featuresFromKmlText(kmlText));
          } catch (e) {
            debugPrint(
              '[GEO import] Falha lendo "${entry.name}" dentro do KMZ: $e',
            );
          }
        }

        return List<Map<String, dynamic>>.unmodifiable(feats);
      }

      final kmlText = utf8.decode(bytes, allowMalformed: true);
      return _featuresFromKmlText(kmlText);
    } catch (e) {
      throw Exception('Erro lendo KML/KMZ: $e');
    }
  }

  List<Map<String, dynamic>> _featuresFromKmlText(String kmlText) {
    final kmlDoc = xml.XmlDocument.parse(kmlText);

    // `namespace: '*'` faz o pacote `xml` casar pelo nome local do elemento
    // independentemente de prefixo/URI de namespace — necessário porque
    // alguns exportadores (ex.: ArcGIS, extensões `gx:`) geram KML com
    // elementos prefixados (`<kml:Placemark>`), que `findAllElements('Placemark')`
    // sem esse argumento simplesmente não encontra.
    final placemarks = kmlDoc.findAllElements('Placemark', namespace: '*');
    final feats = <Map<String, dynamic>>[];

    for (final pm in placemarks) {
      final name =
          pm.getElement('name', namespace: '*')?.innerText.trim() ?? '';
      final desc =
          pm.getElement('description', namespace: '*')?.innerText.trim() ??
              '';

      final props = <String, dynamic>{
        if (name.isNotEmpty) 'name': name,
        if (desc.isNotEmpty) 'description': desc,
      };

      final ext = pm.findElements('ExtendedData', namespace: '*');
      for (final ed in ext) {
        for (final d in ed.findAllElements('Data', namespace: '*')) {
          final key = d.getAttribute('name') ?? '';
          final value = d.getElement('value', namespace: '*')?.innerText ?? '';
          if (key.trim().isNotEmpty) {
            props[key.trim()] = value;
          }
        }
      }

      final multi = pm.findElements('MultiGeometry', namespace: '*');

      final pointGeometries = <List<double>>[];
      final lineGeometries = <List<List<double>>>[];
      final polygonGeometries = <List<List<List<double>>>>[];

      void collect(xml.XmlElement node) {
        for (final pt in node.findAllElements('Point', namespace: '*')) {
          final raw =
              pt.getElement('coordinates', namespace: '*')?.innerText ?? '';
          final coords = _parseKmlCoordinates(raw);
          if (coords.isNotEmpty) {
            pointGeometries.add(coords.first);
          }
        }

        for (final ls in node.findAllElements('LineString', namespace: '*')) {
          final raw =
              ls.getElement('coordinates', namespace: '*')?.innerText ?? '';
          final coords = _parseKmlCoordinates(raw);
          if (coords.length >= 2) {
            lineGeometries.add(coords);
          }
        }

        // Nota: apenas `outerBoundaryIs` é lido — furos (`innerBoundaryIs`)
        // não são suportados porque o modelo de geometria interno
        // (`FeatureData.polygonRings`) não distingue anel externo de furo
        // em nenhum formato (mesma limitação já existe para GeoJSON/SHP
        // com múltiplos anéis). Suportar furos de verdade exigiria uma
        // revisão maior do modelo de geometria e da renderização no mapa.
        for (final poly in node.findAllElements('Polygon', namespace: '*')) {
          final outer = poly.findAllElements('outerBoundaryIs', namespace: '*');
          for (final o in outer) {
            final raw = o
                .findAllElements('coordinates', namespace: '*')
                .map((e) => e.innerText)
                .join(' ');
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

      // Um Placemark pode legitimamente combinar mais de uma família de
      // geometria dentro de um MultiGeometry (ex.: um polígono + um ponto
      // de referência). Como o modelo interno só guarda um tipo de
      // geometria por feição, em vez de descartar as famílias "perdedoras"
      // (como fazia antes, priorizando Polygon > Line > Point), geramos uma
      // Feature separada por família não-vazia — todas com as mesmas
      // propriedades — para não perder nenhuma geometria.
      final geometriesForPlacemark = <Map<String, dynamic>>[];

      if (polygonGeometries.isNotEmpty) {
        geometriesForPlacemark.add(
          polygonGeometries.length == 1
              ? {'type': 'Polygon', 'coordinates': polygonGeometries.first}
              : {'type': 'MultiPolygon', 'coordinates': polygonGeometries},
        );
      }

      if (lineGeometries.isNotEmpty) {
        geometriesForPlacemark.add(
          lineGeometries.length == 1
              ? {'type': 'LineString', 'coordinates': lineGeometries.first}
              : {'type': 'MultiLineString', 'coordinates': lineGeometries},
        );
      }

      if (pointGeometries.isNotEmpty) {
        geometriesForPlacemark.add(
          pointGeometries.length == 1
              ? {'type': 'Point', 'coordinates': pointGeometries.first}
              : {'type': 'MultiPoint', 'coordinates': pointGeometries},
        );
      }

      for (final geometry in geometriesForPlacemark) {
        feats.add({
          'type': 'Feature',
          'properties': props,
          'geometry': geometry,
        });
      }
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