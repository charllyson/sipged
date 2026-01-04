import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_data.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_style.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class ScheduleRoadRepository {
  ScheduleRoadRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // ---------------- Cache in-memory ----------------
  final Map<String, List<ScheduleRoadData>> _execCache = {};

  void clearContractCache(String contractId) {
    _execCache.removeWhere((k, _) => k.startsWith('$contractId|'));
  }

  String _slug(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  String _collectionForService(String key) => 'schedules_${_slug(key)}';

  CollectionReference<Map<String, dynamic>> _contractCol(
      String contractId,
      String collection,
      ) =>
      _firestore
          .collection('contracts')
          .doc(contractId)
          .collection(collection);

  Reference _photosFolderRef({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) =>
      _storage.ref(
        'contracts/$contractId/schedules/${_slug(serviceKey)}/${estaca}_$faixaIndex',
      );

  String _sanitizeName(String name) =>
      name.replaceAll(RegExp(r'[^a-zA-Z0-9\\._-]'), '_');

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

  // ---------------- Helpers orçamento ----------------

  DocumentReference<Map<String, dynamic>> _budgetMetaRef(String contractId) =>
      _firestore
          .collection('contracts')
          .doc(contractId)
          .collection('budget')
          .doc('meta');

  Future<({List<String> headers, String activeId})> _readHeadersAndActiveId(
      String contractId,
      ) async {
    final metaSnap = await _budgetMetaRef(contractId).get();
    if (!metaSnap.exists) {
      return (headers: const <String>[], activeId: '');
    }
    final data = metaSnap.data() ?? <String, dynamic>{};
    final headers = (data['headers'] as List? ?? const [])
        .map((e) => (e ?? '').toString())
        .toList();
    final activeId = (data['activeWriteId'] as String?) ?? '';
    return (headers: headers, activeId: activeId);
  }

  int _findTotalColumnIndex(List<String> headers) {
    int ix = headers.indexWhere((h) {
      final t = h.toLowerCase();
      return t.contains('total') && !t.contains('parcial');
    });
    if (ix < 0) ix = headers.isEmpty ? 0 : headers.length - 1;
    return ix;
  }

  double _parseBRL(String raw) {
    final s = raw.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (s.contains(',') && s.contains('.')) {
      final t = s.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(t) ?? 0.0;
    }
    if (s.contains(',')) {
      return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
    }
    return double.tryParse(s) ?? 0.0;
  }

  // ---------------- Serviços (meta) ----------------
  Future<List<ScheduleRoadData>> loadAvailableServicesFromBudget(
      String contractId,
      ) async {
    final List<ScheduleRoadData> services = <ScheduleRoadData>[
      const ScheduleRoadData(
        numero: 0,
        faixaIndex: 0,
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: Colors.grey,
      ),
    ];

    try {
      final metaRef = _budgetMetaRef(contractId);
      final metaSnap = await metaRef.get();
      if (!metaSnap.exists) return services;

      final data = metaSnap.data()!;
      final activeId = (data['activeWriteId'] as String?) ?? '';

      QuerySnapshot<Map<String, dynamic>> groupsSnap;

      if (activeId.isNotEmpty) {
        groupsSnap = await metaRef
            .collection('rows_v')
            .doc(activeId)
            .collection('groups')
            .orderBy('order')
            .get();
      } else {
        groupsSnap = await metaRef.collection('rows').orderBy('order').get();
      }

      for (final g in groupsSnap.docs) {
        final rawTitle = (g.data()['title'] ?? '').toString().trim();
        if (rawTitle.isEmpty) continue;

        final key = _slug(rawTitle);
        if (services.any((o) => o.key == key)) continue;

        services.add(
          ScheduleRoadData(
            numero: 0,
            faixaIndex: 0,
            key: key,
            label: rawTitle.toUpperCase(),
            icon: ScheduleRoadStyle.pickIconForTitle(rawTitle),
            color: ScheduleRoadStyle.colorForService(rawTitle),
          ),
        );
      }
    } catch (_) {
      // mantém GERAL
    }
    return services;
  }

  /// Soma o valor TOTAL (coluna de total) de todos os itens dentro de cada grupo.
  /// Retorna um map: serviceKey -> soma em double.
  Future<Map<String, double>> fetchBudgetServiceTotals(
      String contractId,
      ) async {
    final metaRef = _budgetMetaRef(contractId);
    final metaSnap = await metaRef.get();
    if (!metaSnap.exists) return const {};

    final meta = metaSnap.data()!;
    final headers = (meta['headers'] as List? ?? const [])
        .map((e) => (e ?? '').toString())
        .toList();
    final totalCol = _findTotalColumnIndex(headers);
    final activeId = (meta['activeWriteId'] as String?) ?? '';

    final out = <String, double>{};

    Future<void> _sumForGroups(
        QuerySnapshot<Map<String, dynamic>> groups,
        ) async {
      for (final g in groups.docs) {
        final gData = g.data();
        final title = (gData['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;

        final key = _slug(title);
        double sum = 0.0;

        final itemsSnap = await g.reference.collection('items').get();
        for (final it in itemsSnap.docs) {
          final data = it.data();
          final values = (data['values'] as List? ?? const []);
          if (values.isEmpty || totalCol >= values.length) continue;
          final totalStr = (values[totalCol] ?? '').toString();
          sum += _parseBRL(totalStr);
        }
        out[key] = sum;
      }
    }

    if (activeId.isNotEmpty) {
      final groups = await metaRef
          .collection('rows_v')
          .doc(activeId)
          .collection('groups')
          .orderBy('order')
          .get();
      await _sumForGroups(groups);
    } else {
      final groups = await metaRef.collection('rows').orderBy('order').get();
      await _sumForGroups(groups);
    }

    return out;
  }

  // ---------------- Faixas ----------------
  Future<void> saveFaixas(
      String contractId,
      List<ScheduleLaneClass> rows,
      ) async {
    final positions = rows.map((r) => r.pos).toList();
    final names = rows.map((r) => r.nome).toList();
    final alturas = rows.map((r) => r.altura).toList();
    final allowed = rows.map((r) => r.allowedByService).toList();

    await _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('schedule_meta')
        .doc('lanes')
        .set({
      'lane_positions': positions,
      'lane_names': names,
      'lane_alturas': alturas,
      'lane_allowed_by_service': allowed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    clearContractCache(contractId);
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

    final positions = (data['lane_positions'] as List?)
        ?.map((e) => e?.toString() ?? '')
        .toList() ??
        <String>[];
    final names =
        (data['lane_names'] as List?)?.map((e) => e?.toString() ?? '').toList() ??
            <String>[];
    final alturas = (data['lane_alturas'] as List?)
        ?.map((e) => (e is num) ? e.toDouble() : 20.0)
        .toList() ??
        <double>[];
    final rawAllowed =
        (data['lane_allowed_by_service'] as List?) ?? const <dynamic>[];

    if (positions.isEmpty ||
        names.isEmpty ||
        positions.length != names.length) {
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
      'lane_allowed_by_service': [<String, bool>{}],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    clearContractCache(contractId);
  }

  // ---------------- Execuções (fetch + cache) ----------------
  Future<List<ScheduleRoadData>> fetchExecucoes({
    required String contractId,
    required String selectedServiceKey,
    required List<String> serviceKeysForGeral,
    required ScheduleRoadData metaForSelected,
  }) async {
    final cacheKey = '$contractId|${selectedServiceKey.toLowerCase()}';
    final cached = _execCache[cacheKey];
    if (cached != null) return cached;

    final results = <ScheduleRoadData>[];

    ScheduleRoadData _fromDoc(
        Map<String, dynamic> m, {
          ScheduleRoadData? meta,
        }) {
      final rawCreated = m['createdAt'];
      final rawUpdated = m['updatedAt'];
      final createdAt =
      (rawCreated is Timestamp) ? rawCreated.toDate() : rawCreated;
      final updatedAt =
      (rawUpdated is Timestamp) ? rawUpdated.toDate() : rawUpdated;

      final fotos = List<String>.from(m['fotos'] ?? const []);
      final statusRaw = (m['status'] as String?);
      final status = (statusRaw == null || statusRaw.trim().isEmpty)
          ? (fotos.isNotEmpty ? 'em_andamento' : 'a_iniciar')
          : _canonStatus(statusRaw);

      final normalized = {
        ...m,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'status': status,
      };
      return ScheduleRoadData.fromMap(normalized, meta: meta);
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
      final snap = await _contractCol(contractId, _collectionForService(selectedServiceKey))
          .get();
      for (final d in snap.docs) {
        results.add(_fromDoc(d.data(), meta: metaForSelected));
      }
    }

    final map = <String, ScheduleRoadData>{};
    for (final e in results) {
      final key = '${e.numero}_${e.faixaIndex}';
      final cur = map[key];
      final timeE = e.updatedAt ?? e.createdAt;
      final timeCur = cur?.updatedAt ?? cur?.createdAt;
      if (cur == null ||
          (timeE != null && (timeCur == null || timeE.isAfter(timeCur)))) {
        map[key] = e;
      }
    }
    final list = map.values.toList(growable: false);
    _execCache[cacheKey] = list;
    return list;
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

  // ---------------- APPLY ----------------

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

  Future<List<String>> applySquareChanges({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required String tipoLabel,
    required String status,
    String? comentario,
    DateTime? takenAtForNew,
    required List<String> finalPhotoUrls,
    required List<Uint8List> newFilesBytes,
    List<String>? newFileNames,
    List<pm.CarouselMetadata> newPhotoMetas = const [],
    required String currentUserId,
  }) async {
    if (serviceKey == 'geral') return const <String>[];

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

    final col = _contractCol(contractId, _collectionForService(serviceKey));
    final q = await col
        .where('numero', isEqualTo: estaca)
        .where('faixa_index', isEqualTo: faixaIndex)
        .limit(1)
        .get();

    final hasComment = (comentario?.trim().isNotEmpty ?? false);
    final hasPhotos =
        finalPhotoUrls.isNotEmpty || newFilesBytes.isNotEmpty;

    var norm = _normalizeStatus(status);
    final takenMs = takenAtForNew?.millisecondsSinceEpoch;

    // 🔴 Regra de conteúdo: se status veio a_iniciar mas tem comentário/foto,
    // forçamos em_andamento (mínimo > 0% de avanço).
    if (norm == 'a_iniciar' && (hasComment || hasPhotos)) {
      norm = 'em_andamento';
    }

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

    // Se realmente é "a_iniciar" e não há conteúdo, limpa a célula
    if (norm == 'a_iniciar') {
      if (q.docs.isNotEmpty) {
        try {
          final data = q.docs.first.data();
          final urls = (data['fotos'] is List)
              ? List<String>.from(data['fotos'] as List)
              : const <String>[];
          for (final u in urls) {
            try {
              await _storage.refFromURL(u).delete();
            } catch (_) {}
          }
        } catch (_) {}
        await q.docs.first.reference.delete();
      }
      clearContractCache(contractId);
      return const <String>[];
    }

    if (q.docs.isNotEmpty) {
      docRef = q.docs.first.reference;
      final updates = Map<String, dynamic>.from(base)
        ..['comentario'] =
        hasComment ? comentario!.trim() : FieldValue.delete();
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
        final suggested =
        (newFileNames != null && i < newFileNames.length && newFileNames[i].trim().isNotEmpty)
            ? _sanitizeName(newFileNames[i])
            : 'img_${nowMs}_$i.jpg';

        final unique = '$suggested.${DateTime.now().microsecondsSinceEpoch}';
        final contentType = _guessContentType(suggested);
        final ref = folder.child(unique);

        final task = await ref.putData(
          newFilesBytes[i],
          SettableMetadata(contentType: contentType),
        );
        final url = await task.ref.getDownloadURL();
        uploadedUrls.add(url);

        final m = (i < newPhotoMetas.length)
            ? newPhotoMetas[i]
            : const pm.CarouselMetadata();
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

    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    final currentUrls = (data['fotos'] is List)
        ? List<String>.from(data['fotos'] as List)
        : const <String>[];
    final removed = currentUrls
        .where((u) => !finalPhotoUrls.contains(u) && !uploadedUrls.contains(u))
        .toList();

    for (final url in removed) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {}
    }

    if (removed.isNotEmpty) {
      final rawMetaList =
      (data['fotos_meta'] is List) ? (data['fotos_meta'] as List) : const [];
      final metaList = rawMetaList
          .whereType<Object>()
          .map((e) =>
      (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();

      final metasToRemove = metaList
          .where((m) => removed.contains(m['url'] as String?))
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      final updates = <String, dynamic>{
        if (removed.isNotEmpty) 'fotos': FieldValue.arrayRemove(removed),
        if (metasToRemove.isNotEmpty)
          'fotos_meta': FieldValue.arrayRemove(metasToRemove),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
        if (takenMs != null) 'takenAtMs': takenMs,
      };
      await docRef.update(updates);
    }

    final newOrdered = <String>[...finalPhotoUrls, ...uploadedUrls];
    if (newOrdered.isEmpty) {
      await docRef.update({
        'fotos': FieldValue.delete(),
        'fotos_meta': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
        if (takenMs != null) 'takenAtMs': takenMs,
      });
      clearContractCache(contractId);
      return uploadedUrls;
    }

    final metasAll = <Map<String, dynamic>>[];
    try {
      final snap2 = await docRef.get();
      final d2 = snap2.data() ?? <String, dynamic>{};
      final rawMetaList2 =
      (d2['fotos_meta'] is List) ? (d2['fotos_meta'] as List) : const [];
      final metaList2 = rawMetaList2
          .whereType<Object>()
          .map((e) =>
      (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();

      final byUrl = <String, Map<String, dynamic>>{};
      for (final m in metaList2) {
        final url = (m['url'] as String?) ?? '';
        if (url.isNotEmpty) byUrl[url] = m;
      }

      for (final u in newOrdered) {
        final m = byUrl[u];
        metasAll.add(
          m != null ? Map<String, dynamic>.from(m) : {'url': u, 'name': u.split('/').last},
        );
      }
    } catch (_) {
      metasAll.addAll(
        newOrdered.map(
              (u) => {'url': u, 'name': u.split('/').last},
        ),
      );
    }

    await docRef.update({
      'fotos': newOrdered,
      'fotos_meta': metasAll,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
      if (takenMs != null) 'takenAtMs': takenMs,
    });

    clearContractCache(contractId);

    return uploadedUrls;
  }

  // ===================== PHYS/FIN (períodos + percentuais) =====================

  /// Doc: contracts/{cid}/schedule_meta/physfin_grid
  DocumentReference<Map<String, dynamic>> _physFinDoc(String contractId) =>
      _firestore
          .collection('contracts')
          .doc(contractId)
          .collection('schedule_meta')
          .doc('physfin_grid');

  /// Lê períodos e grade de percentuais por serviço (aceita qualquer chave).
  Future<({List<int> periods, Map<String, List<double>> grid})> loadPhysFinGrid(
      String contractId,
      ) async {
    final doc = await _physFinDoc(contractId).get();

    if (!doc.exists) {
      return (periods: const <int>[], grid: const <String, List<double>>{});
    }

    final data = doc.data() ?? const <String, dynamic>{};

    // periods -> List<int>
    final periods = ((data['periods'] as List?) ?? const [])
        .whereType<Object>()
        .map(
          (e) => (e is int)
          ? e
          : (e is num)
          ? e.toInt()
          : int.tryParse(e.toString()) ?? 0,
    )
        .toList(growable: false);

    // grid -> Map<String, List<double>>
    final rawGrid = (data['grid'] as Map?) ?? const <String, dynamic>{};
    final grid = <String, List<double>>{};
    for (final entry in rawGrid.entries) {
      final key = entry.key.toString(); // pode ser índice "001" (preferido) ou legado
      final lst = (entry.value as List?) ?? const [];
      final values = lst
          .whereType<Object>()
          .map(
            (v) => (v is double)
            ? v
            : (v is num)
            ? v.toDouble()
            : double.tryParse(v.toString()) ?? 0.0,
      )
          .toList(growable: false);
      grid[key] = values;
    }

    return (periods: periods, grid: grid);
  }

  /// Salva períodos (dias) e grade **por índice** (ITEM).
  Future<void> savePhysFinGrid({
    required String contractId,
    required List<int> periods,
    required Map<String, List<double>> grid,
    String? updatedBy,
  }) async {
    final nCols = periods.length;
    final normGrid = <String, List<double>>{};
    grid.forEach((k, row) {
      // 👇 mantém a chave exatamente como veio (índice "001", "002"...)
      final kk = k;
      final r =
      List<double>.from(row.map((e) => (e is num) ? e.toDouble() : 0.0));
      if (r.length > nCols) {
        normGrid[kk] = r.sublist(0, nCols);
      } else if (r.length < nCols) {
        normGrid[kk] = [...r, ...List<double>.filled(nCols - r.length, 0.0)];
      } else {
        normGrid[kk] = r;
      }
    });

    await _physFinDoc(contractId).set({
      'periods': periods,
      'grid': normGrid,
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedBy != null && updatedBy.isNotEmpty) 'updatedBy': updatedBy,
      'version': 1,
    }, SetOptions(merge: true));
  }

  // ==================== GEOMETRIA =======================
  CollectionReference<Map<String, dynamic>> get _planningProjects =>
      _firestore.collection('planning_projects');

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
            if (lat != null && lon != null) {
              line.add(LatLng(lat.toDouble(), lon.toDouble()));
            }
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
        if (lat != null && lon != null) {
          out.add(LatLng(lat.toDouble(), lon.toDouble()));
        }
      }
    }
    return out;
  }

  List<List<dynamic>>? _toMultiList(List<List<LatLng>>? ml) {
    if (ml == null) return null;
    return ml
        .map((seg) => seg.map((p) => [p.longitude, p.latitude]).toList())
        .toList();
  }

  List<dynamic>? _toPoints(List<LatLng>? pts) {
    if (pts == null) return null;
    return pts
        .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
        .toList();
  }

  Future<ScheduleRoadData?> fetchProjectGeometry(String contractId) async {
    final snap = await _planningProjects.doc(contractId).get();
    if (!snap.exists) return null;
    final d = snap.data() ?? <String, dynamic>{};

    final geometryType = (d['geometryType'] ?? '').toString().trim().isEmpty
        ? null
        : d['geometryType'].toString();

    final multiLine = _parseMulti(d['multiLine']);
    final points = _parsePoints(d['points']);

    return ScheduleRoadData(
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

  Future<ScheduleRoadData> upsertProjectGeometry({
    required String contractId,
    required ScheduleRoadData data,
    String? summarySubjectContract,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = _planningProjects.doc(contractId);

    final base = <String, dynamic>{
      'contractId': contractId,
      if (summarySubjectContract != null)
        'summarySubjectContract': summarySubjectContract,
      if (data.geometryType != null) 'geometryType': data.geometryType,
      if (data.multiLine != null) 'multiLine': _toMultiList(data.multiLine),
      if (data.points != null) 'points': _toPoints(data.points),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    final snap = await docRef.get();
    if (!snap.exists) {
      base['createdAt'] = FieldValue.serverTimestamp();
      base['createdBy'] = uid;
    }

    await docRef.set(base, SetOptions(merge: true));
    final after = await docRef.get();
    final saved = after.data() ?? <String, dynamic>{};

    return ScheduleRoadData(
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

  Future<ScheduleRoadData> importGeoJson({
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
    } else if (geojson['type'] == 'LineString' ||
        geojson['type'] == 'MultiLineString') {
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

    final meta = ScheduleRoadData(
      numero: 0,
      faixaIndex: 0,
      key: 'geral',
      label: 'GERAL',
      icon: Icons.route,
      color: Colors.grey,
      geometryType: geometryType,
      multiLine: multi,
      points: pts,
      createdBy: contractId,
    );

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = _planningProjects.doc(contractId);
    final base = <String, dynamic>{
      'contractId': contractId,
      if (summarySubjectContract != null)
        'summarySubjectContract': summarySubjectContract,
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

    return meta.copyWith();
  }

  String docIdFromBoardData(ScheduleRoadData d) {
    if ((d.createdBy ?? '').trim().isNotEmpty) return d.createdBy!.trim();
    return 'contract_unknown';
  }
}
