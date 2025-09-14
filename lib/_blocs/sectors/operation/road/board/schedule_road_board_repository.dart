// lib/_blocs/sectors/operation/road/board/schedule_road_board_repository.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_data.dart';
import 'package:siged/_blocs/sectors/operation/road/board/schedule_road_board_style.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

class ScheduleRoadBoardRepository {
  ScheduleRoadBoardRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // ---------------- Helpers ----------------
  String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  String _collectionForService(String key) => 'schedules_${_slug(key)}';

  CollectionReference<Map<String, dynamic>> _contractCol(
      String contractId,
      String collection,
      ) =>
      _firestore.collection('contracts').doc(contractId).collection(collection);

  Reference _photosFolderRef({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) =>
      _storage.ref('contracts/$contractId/schedules/${_slug(serviceKey)}/${estaca}_$faixaIndex');

  String _sanitizeName(String name) => name.replaceAll(RegExp(r'[^a-zA-Z0-9\\._-]'), '_');

  String _guessContentType(String name, [String fallback = 'image/jpeg']) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return fallback;
  }

  // ---------------- Serviços (meta) ----------------
  Future<List<ScheduleRoadBoardData>> loadAvailableServicesFromBudget(String contractId) async {
    final List<ScheduleRoadBoardData> services = <ScheduleRoadBoardData>[
      const ScheduleRoadBoardData(
        numero: 0,
        faixaIndex: 0,
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: Colors.grey,
      ),
    ];
    try {
      final rowsCol = _firestore
          .collection('contracts')
          .doc(contractId)
          .collection('budget')
          .doc('meta')
          .collection('rows');

      final groups = await rowsCol.orderBy('order').get();
      for (final g in groups.docs) {
        final data = g.data();
        final rawTitle = (data['title'] ?? '').toString().trim();
        if (rawTitle.isEmpty) continue;

        final key = _slug(rawTitle);
        if (services.any((o) => o.key == key)) continue;

        services.add(
          ScheduleRoadBoardData(
            numero: 0,
            faixaIndex: 0,
            key: key,
            label: rawTitle.toUpperCase(),
            icon: ScheduleRoadBoardStyle.pickIconForTitle(rawTitle),
            color: ScheduleRoadBoardStyle.colorForService(rawTitle),
          ),
        );
      }
    } catch (_) {
      // mantém GERAL
    }
    return services;
  }

  // ---------------- Faixas ----------------
  Future<void> saveFaixas(String contractId, List<ScheduleLaneClass> rows) async {
    final positions = rows.map((r) => r.pos).toList();
    final names = rows.map((r) => r.nome).toList();
    final alturas = rows.map((r) => r.altura).toList();
    final allowed = rows.map((r) => r.allowedByService).toList(); // NOVO

    await _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('schedule_meta')
        .doc('lanes')
        .set({
      'lane_positions': positions,
      'lane_names': names,
      'lane_alturas': alturas,
      'lane_allowed_by_service': allowed, // NOVO
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<ScheduleLaneClass>> loadFaixas(String contractId) async {
    final doc = await _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('schedule_meta')
        .doc('lanes')
        .get();

    if (!doc.exists) return <ScheduleLaneClass>[];

    final data = doc.data() ?? <String, dynamic>{};
    if (data.isEmpty) return <ScheduleLaneClass>[];

    final positions =
        (data['lane_positions'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? <String>[];
    final names =
        (data['lane_names'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? <String>[];
    final alturas =
        (data['lane_alturas'] as List?)
            ?.map((e) => (e is num) ? e.toDouble() : 20.0)
            .toList() ??
            <double>[];

    // NOVO (pode não existir ainda)
    final rawAllowed = (data['lane_allowed_by_service'] as List?) ?? const <dynamic>[];

    if (positions.isEmpty || names.isEmpty || positions.length != names.length) {
      return <ScheduleLaneClass>[];
    }

    final rows = <ScheduleLaneClass>[];
    for (var i = 0; i < names.length; i++) {
      final alt = i < alturas.length ? alturas[i] : 20.0;

      Map<String, bool> allowedByService = const {};
      if (i < rawAllowed.length && rawAllowed[i] is Map) {
        final m = Map<String, dynamic>.from(rawAllowed[i] as Map);
        allowedByService = {
          for (final k in m.keys) k.toString().toLowerCase(): (m[k] == true),
        };
      }

      rows.add(ScheduleLaneClass(
        pos: positions[i],
        nome: names[i],
        altura: alt,
        allowedByService: allowedByService,
      ));
    }
    return rows;
  }

  Future<void> ensureDefaultLaneIfMissing(String contractId) async {
    final lanes = await loadFaixas(contractId);
    if (lanes.isNotEmpty) return;

    await _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('schedule_meta')
        .doc('lanes')
        .set({
      'lane_positions': ['EIXO'],
      'lane_names': ['FAIXA ÚNICA'],
      'lane_alturas': [20.0],
      'lane_allowed_by_service': [
        <String, bool>{} // default: vazio => tudo permitido
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------- Execuções (fetch) ----------------
  Future<List<ScheduleRoadBoardData>> fetchExecucoes({
    required String contractId,
    required String selectedServiceKey,
    required List<String> serviceKeysForGeral,
    required ScheduleRoadBoardData metaForSelected,
  }) async {
    final results = <ScheduleRoadBoardData>[];

    ScheduleRoadBoardData _fromDoc(Map<String, dynamic> m, {ScheduleRoadBoardData? meta}) {
      final rawCreated = m['createdAt'];
      final rawUpdated = m['updatedAt'];
      final createdAt = (rawCreated is Timestamp) ? rawCreated.toDate() : rawCreated;
      final updatedAt = (rawUpdated is Timestamp) ? rawUpdated.toDate() : rawUpdated;

      final fotos = List<String>.from(m['fotos'] ?? const []);
      final statusRaw = (m['status'] as String?);
      final status = (statusRaw == null || statusRaw.trim().isEmpty)
          ? (fotos.isNotEmpty ? 'em_andamento' : 'a_iniciar')
          : _canonStatus(statusRaw);

      final normalized = {
        ...m,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'status': status, // canônico para UI
      };
      return ScheduleRoadBoardData.fromMap(normalized, meta: meta);
    }

    if (selectedServiceKey == 'geral') {
      if (serviceKeysForGeral.isNotEmpty) {
        final snaps = await Future.wait([
          for (final k in serviceKeysForGeral)
            _contractCol(contractId, _collectionForService(k)).get(),
        ]);
        for (final snap in snaps) {
          for (final d in snap.docs) {
            results.add(_fromDoc(d.data(), meta: metaForSelected));
          }
        }
      }
    } else {
      final snap = await _contractCol(contractId, _collectionForService(selectedServiceKey)).get();
      for (final d in snap.docs) {
        results.add(_fromDoc(d.data(), meta: metaForSelected));
      }
    }

    // Deduplicar por (estaca, faixa) pegando o mais recente
    final map = <String, ScheduleRoadBoardData>{};
    for (final e in results) {
      final key = '${e.numero}_${e.faixaIndex}';
      final cur = map[key];
      final timeE = e.updatedAt ?? e.createdAt;
      final timeCur = cur?.updatedAt ?? cur?.createdAt;
      if (cur == null || (timeE != null && (timeCur == null || timeE.isAfter(timeCur)))) {
        map[key] = e;
      }
    }
    return map.values.toList();
  }

  String _canonStatus(String? raw) {
    var s = (raw ?? '').toLowerCase().trim();
    s = s
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[\s\-_]+'), ' ');
    if (s.contains('conclu')) return 'concluido';
    if (s.contains('andament') || s.contains('progress')) return 'em_andamento';
    if (s.contains('iniciar') || s.contains('todo')) return 'a_iniciar';
    return s.isEmpty ? 'a_iniciar' : 'a_iniciar';
  }

  // ---------------- APPLY (idêntico ao seu) ----------------
  Future<List<String>> applySquareChanges({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required String tipoLabel,
    required String status, // 'concluido' | 'em andamento' | 'a iniciar'
    String? comentario,
    DateTime? takenAtForNew,
    required List<String> finalPhotoUrls,
    required List<Uint8List> newFilesBytes,
    List<String>? newFileNames,
    List<pm.CarouselMetadata> newPhotoMetas = const [],
    required String currentUserId,
  }) async {
    if (serviceKey == 'geral') return const <String>[];

    // (Opcional, seguro) — bloqueia escrita se a faixa não permitir o serviço
    try {
      final lanes = await loadFaixas(contractId);
      if (faixaIndex < 0 || faixaIndex >= lanes.length) {
        throw 'Faixa inválida.';
      }
      if (!lanes[faixaIndex].isAllowed(serviceKey)) {
        throw 'Serviço "$serviceKey" não é aplicável na faixa ${lanes[faixaIndex].label}.';
      }
    } catch (_) {
      rethrow;
    }

    // 1) Upsert básico (status/comentário + takenAtMs)
    final col = _contractCol(contractId, _collectionForService(serviceKey));
    final q = await col
        .where('numero', isEqualTo: estaca)
        .where('faixa_index', isEqualTo: faixaIndex)
        .limit(1)
        .get();

    String _normalizeStatus(String status) {
      switch (status.toLowerCase()) {
        case 'concluido':
          return 'concluido';
        case 'em_andamento':
        case 'em andamento':
          return 'em_andamento';
        case 'a_iniciar':
        case 'a iniciar':
          return 'a_iniciar';
        default:
          return 'a_iniciar';
      }
    }

    final norm = _normalizeStatus(status);
    final hasComment = (comentario?.trim().isNotEmpty ?? false);
    final takenMs = takenAtForNew?.millisecondsSinceEpoch;

    final base = <String, dynamic>{
      'numero': estaca,
      'faixa_index': faixaIndex,
      'tipo': tipoLabel,
      'status': norm,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
      if (takenMs != null) 'takenAtMs': takenMs,
    };

    DocumentReference<Map<String, dynamic>>? docRef;

    if (norm == 'a_iniciar') {
      if (q.docs.isNotEmpty) {
        try {
          final data = q.docs.first.data();
          final urls =
          (data['fotos'] is List) ? List<String>.from(data['fotos'] as List) : const <String>[];
          for (final u in urls) {
            try {
              await _storage.refFromURL(u).delete();
            } catch (_) {}
          }
        } catch (_) {}
        await q.docs.first.reference.delete();
      }
      return const <String>[];
    }

    if (q.docs.isNotEmpty) {
      docRef = q.docs.first.reference;
      final updates = Map<String, dynamic>.from(base)
        ..['comentario'] = hasComment ? comentario!.trim() : FieldValue.delete();
      await docRef.update(updates);
    } else {
      final create = <String, dynamic>{
        ...base,
        if (hasComment) 'comentario': comentario!.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
      };
      docRef = await col.add(create);
    }

    // 2) Upload de novas fotos
    final uploadedUrls = <String>[];
    final uploadedMetas = <Map<String, dynamic>>[];

    if (newFilesBytes.isNotEmpty) {
      final folder = _photosFolderRef(
        contractId: contractId,
        serviceKey: serviceKey,
        estaca: estaca,
        faixaIndex: faixaIndex,
      );
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      for (int i = 0; i < newFilesBytes.length; i++) {
        final suggested = (newFileNames != null &&
            i < newFileNames.length &&
            newFileNames[i].trim().isNotEmpty)
            ? _sanitizeName(newFileNames[i])
            : 'img_${nowMs}_$i.jpg';

        final unique = '$suggested.${DateTime.now().microsecondsSinceEpoch}';
        final contentType = _guessContentType(suggested);
        final ref = folder.child(unique);

        if (kDebugMode) {
          debugPrint('[UPLOAD] $unique ($contentType)');
        }

        final task = await ref.putData(
          newFilesBytes[i],
          SettableMetadata(contentType: contentType),
        );
        final url = await task.ref.getDownloadURL();
        uploadedUrls.add(url);

        final m = (i < newPhotoMetas.length) ? newPhotoMetas[i] : const pm.CarouselMetadata();
        final taken = m.takenAt ?? takenAtForNew;

        uploadedMetas.add({
          'url': url,
          'name': m.name ?? unique,
          'takenAt': taken?.millisecondsSinceEpoch,
          'takenAtMs': taken?.millisecondsSinceEpoch,
          'lat': m.lat,
          'lng': m.lng,
          'make': m.make,
          'model': m.model,
          'orientation': m.orientation,
          'uploadedAtMs': m.uploadedAtMs ?? nowMs,
          'uploadedBy': m.uploadedBy ?? currentUserId,
        });
      }

      if (uploadedUrls.isNotEmpty) {
        await docRef.update({
          'fotos': FieldValue.arrayUnion(uploadedUrls),
          'fotos_meta': FieldValue.arrayUnion(uploadedMetas),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': currentUserId,
          if (takenMs != null) 'takenAtMs': takenMs,
        });
      }
    }

    // 3) Sincronizar exclusões (X) e ler estado atual
    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};

    final currentUrls =
    (data['fotos'] is List) ? List<String>.from(data['fotos'] as List) : const <String>[];

    final removed =
    currentUrls.where((u) => !finalPhotoUrls.contains(u) && !uploadedUrls.contains(u)).toList();

    for (final url in removed) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {}
    }

    if (removed.isNotEmpty) {
      final rawMetaList = (data['fotos_meta'] is List) ? (data['fotos_meta'] as List) : const [];
      final metaList = rawMetaList
          .whereType<Object>()
          .map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();

      final metasToRemove = metaList
          .where((m) => removed.contains(m['url'] as String?))
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      final updates = <String, dynamic>{
        if (removed.isNotEmpty) 'fotos': FieldValue.arrayRemove(removed),
        if (metasToRemove.isNotEmpty) 'fotos_meta': FieldValue.arrayRemove(metasToRemove),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
        if (takenMs != null) 'takenAtMs': takenMs,
      };
      await docRef.update(updates);
    }

    // 4) Setar ORDEM FINAL
    final newOrdered = <String>[...finalPhotoUrls, ...uploadedUrls];

    if (newOrdered.isEmpty) {
      await docRef.update({
        'fotos': FieldValue.delete(),
        'fotos_meta': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
        if (takenMs != null) 'takenAtMs': takenMs,
      });
      return uploadedUrls;
    }

    final metasAll = <Map<String, dynamic>>[];
    try {
      final snap2 = await docRef.get();
      final d2 = snap2.data() ?? <String, dynamic>{};
      final rawMetaList2 = (d2['fotos_meta'] is List) ? (d2['fotos_meta'] as List) : const [];
      final metaList2 = rawMetaList2
          .whereType<Object>()
          .map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();

      final byUrl = <String, Map<String, dynamic>>{};
      for (final m in metaList2) {
        final url = (m['url'] as String?) ?? '';
        if (url.isNotEmpty) byUrl[url] = m;
      }

      for (final u in newOrdered) {
        final m = byUrl[u];
        metasAll.add(m != null ? Map<String, dynamic>.from(m) : {'url': u, 'name': u.split('/').last});
      }
    } catch (_) {
      metasAll.addAll(newOrdered.map((u) => {'url': u, 'name': u.split('/').last}));
    }

    await docRef.update({
      'fotos': newOrdered,
      'fotos_meta': metasAll,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
      if (takenMs != null) 'takenAtMs': takenMs,
    });

    return uploadedUrls;
  }

  // =========================================================================
  // ==================== GEOMETRIA (usando BoardData) =======================
  // =========================================================================

  /// Coleção onde persistimos o traçado do contrato
  CollectionReference<Map<String, dynamic>> get _planningProjects =>
      _firestore.collection('planning_projects');

  // -------- Serialização/parse de geometria --------

  List<List<LatLng>> _parseMulti(dynamic g) {
    if (g is! List) return const <List<LatLng>>[];
    final out = <List<LatLng>>[];
    for (final seg in g) {
      if (seg is List) {
        final line = <LatLng>[];
        for (final p in seg) {
          if (p is List && p.length >= 2) {
            final lon = (p[0] as num?)?.toDouble();
            final lat = (p[1] as num?)?.toDouble();
            if (lat != null && lon != null) line.add(LatLng(lat, lon));
          } else if (p is Map) {
            final lat = (p['lat'] ?? p['latitude']) as num?;
            final lon = (p['lng'] ?? p['longitude']) as num?;
            if (lat != null && lon != null) line.add(LatLng(lat.toDouble(), lon.toDouble()));
          } else if (p is GeoPoint) {
            line.add(LatLng(p.latitude, p.longitude));
          }
        }
        if (line.isNotEmpty) out.add(line);
      }
    }
    return out;
  }

  List<LatLng> _parsePoints(dynamic v) {
    if (v is! List) return const <LatLng>[];
    final out = <LatLng>[];
    for (final p in v) {
      if (p is GeoPoint) {
        out.add(LatLng(p.latitude, p.longitude));
      } else if (p is List && p.length >= 2) {
        final lon = (p[0] as num?)?.toDouble();
        final lat = (p[1] as num?)?.toDouble();
        if (lat != null && lon != null) out.add(LatLng(lat, lon));
      } else if (p is Map) {
        final lat = (p['lat'] ?? p['latitude']) as num?;
        final lon = (p['lng'] ?? p['longitude']) as num?;
        if (lat != null && lon != null) out.add(LatLng(lat.toDouble(), lon.toDouble()));
      }
    }
    return out;
  }

  List<List<dynamic>>? _toMultiList(List<List<LatLng>>? ml) {
    if (ml == null) return null;
    return ml.map((seg) => seg.map((p) => [p.longitude, p.latitude]).toList()).toList();
  }

  List<dynamic>? _toPoints(List<LatLng>? pts) {
    if (pts == null) return null;
    return pts.map((p) => {'latitude': p.latitude, 'longitude': p.longitude}).toList();
  }

  // -------- CRUD de geometria --------

  /// Lê a geometria do contrato e devolve um BoardData “meta” com os 3 campos de geometria.
  Future<ScheduleRoadBoardData?> fetchProjectGeometry(String contractId) async {
    final snap = await _planningProjects.doc(contractId).get();
    if (!snap.exists) return null;
    final d = snap.data() ?? <String, dynamic>{};

    final geometryType = (d['geometryType'] ?? '').toString().trim().isEmpty
        ? null
        : d['geometryType'].toString();

    final multiLine = _parseMulti(d['multiLine']);
    final points = _parsePoints(d['points']);

    return ScheduleRoadBoardData(
      numero: 0,
      faixaIndex: 0,
      key: 'geral',
      label: 'GERAL',
      icon: Icons.route,
      color: Colors.grey,
      geometryType: geometryType,
      multiLine: multiLine.isEmpty ? null : multiLine,
      points: points.isEmpty ? null : points,
    );
  }

  Future<void> deleteProjectGeometry(String contractId) async {
    await _planningProjects.doc(contractId).delete();
  }

  /// Grava (upsert) a geometria — usa somente os campos geometryType/multiLine/points do BoardData.
  Future<ScheduleRoadBoardData> upsertProjectGeometry(ScheduleRoadBoardData data,
      {String? summarySubjectContract}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = _planningProjects.doc(
      // usamos contractId dentro do repositório de geometria como docId
      // quando usado a partir do BLoC, ele já sabe qual é o contrato atual
      (data.createdBy ?? '').isNotEmpty ? data.createdBy! : docIdFromBoardData(data),
    );

    // fallback: se não der pra inferir pelo createdBy, assuma que o nome do doc
    // deve ser passado externamente — então preferimos usar o campo 'contractId'
    // se existir no payload (ou então falhamos graciosamente).
    // Para simplificar, criaremos sempre pelo docId explícito passado no método
    // (ver importGeoJson / bloc chama com o contractId correto).
    // Mantendo compatibilidade:
    final base = <String, dynamic>{
      if (summarySubjectContract != null) 'summarySubjectContract': summarySubjectContract,
      if (data.geometryType != null) 'geometryType': data.geometryType,
      if (data.multiLine != null) 'multiLine': _toMultiList(data.multiLine),
      if (data.points != null) 'points': _toPoints(data.points),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    // createdAt/By se for primeira vez
    final snap = await docRef.get();
    if (!snap.exists) {
      base['createdAt'] = FieldValue.serverTimestamp();
      base['createdBy'] = uid;
    }

    await docRef.set(base, SetOptions(merge: true));
    final after = await docRef.get();
    final saved = after.data() ?? <String, dynamic>{};

    return ScheduleRoadBoardData(
      numero: 0,
      faixaIndex: 0,
      key: 'geral',
      label: 'GERAL',
      icon: Icons.route,
      color: Colors.grey,
      geometryType: saved['geometryType']?.toString(),
      multiLine: _parseMulti(saved['multiLine']),
      points: _parsePoints(saved['points']),
    );
  }

  /// Importa GeoJSON (Feature | FeatureCollection | LineString | MultiLineString) e faz upsert.
  Future<ScheduleRoadBoardData> importGeoJson({
    required String contractId,
    required Map<String, dynamic> geojson,
    String? summarySubjectContract,
  }) async {
    Map<String, dynamic>? geometry;

    if (geojson['type'] == 'Feature') {
      geometry = (geojson['geometry'] as Map?)?.cast<String, dynamic>();
    } else if (geojson['type'] == 'FeatureCollection') {
      final feats = (geojson['features'] as List?) ?? const [];
      if (feats.isNotEmpty) {
        geometry = (feats.first['geometry'] as Map?)?.cast<String, dynamic>();
      }
    } else if (geojson['type'] == 'LineString' || geojson['type'] == 'MultiLineString') {
      geometry = geojson.cast<String, dynamic>();
    }

    if (geometry == null) {
      throw Exception('GeoJSON inválido: geometry ausente.');
    }

    final type = geometry['type']?.toString();
    final coords = geometry['coordinates'];

    String? geometryType;
    List<List<LatLng>>? multi;
    List<LatLng>? pts;

    if (type == 'LineString') {
      final tmp = <LatLng>[];
      for (final p in (coords as List)) {
        if (p is List && p.length >= 2) {
          // GeoJSON: [lon, lat]
          final lon = (p[0] as num).toDouble();
          final lat = (p[1] as num).toDouble();
          tmp.add(LatLng(lat, lon));
        }
      }
      geometryType = 'LineString';
      pts = tmp;
      multi = null;
    } else if (type == 'MultiLineString') {
      final ml = <List<LatLng>>[];
      for (final seg in (coords as List)) {
        final line = <LatLng>[];
        for (final p in (seg as List)) {
          if (p is List && p.length >= 2) {
            final lon = (p[0] as num).toDouble();
            final lat = (p[1] as num).toDouble();
            line.add(LatLng(lat, lon));
          }
        }
        if (line.isNotEmpty) ml.add(line);
      }
      geometryType = 'MultiLineString';
      pts = null;
      multi = ml;
    } else {
      throw Exception('Geometry não suportada: $type');
    }

    final meta = ScheduleRoadBoardData(
      numero: 0,
      faixaIndex: 0,
      key: 'geral',
      label: 'GERAL',
      icon: Icons.route,
      color: Colors.grey,
      geometryType: geometryType,
      multiLine: multi,
      points: pts,
      // podemos guardar o contractId em createdBy somente para docId fallback (ver upsert)
      createdBy: contractId,
    );

    // upsert com docId explícito = contractId
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = _planningProjects.doc(contractId);
    final base = <String, dynamic>{
      'contractId': contractId,
      if (summarySubjectContract != null) 'summarySubjectContract': summarySubjectContract,
      if (meta.geometryType != null) 'geometryType': meta.geometryType,
      if (meta.multiLine != null) 'multiLine': _toMultiList(meta.multiLine),
      if (meta.points != null) 'points': _toPoints(meta.points),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };
    final snap = await docRef.get();
    if (!snap.exists) {
      base['createdAt'] = FieldValue.serverTimestamp();
      base['createdBy'] = uid;
    }
    await docRef.set(base, SetOptions(merge: true));

    // retorna como BoardData “meta”
    return meta.copyWith();
  }

  // Pequeno helper para tentar derivar um docId quando não for passado diretamente
  String docIdFromBoardData(ScheduleRoadBoardData d) {
    // tenta pelo createdBy (onde colocamos contractId no import)
    if ((d.createdBy ?? '').trim().isNotEmpty) return d.createdBy!.trim();
    // último recurso: uma tag previsível
    return 'contract_unknown';
  }
}
