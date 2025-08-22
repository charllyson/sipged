// lib/_repository/sectors/operation/schedule_repository.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sisged/_datas/sectors/operation/schedule/schedule_data.dart';
import 'package:sisged/_datas/sectors/operation/schedule/schedule_style.dart';
import 'package:sisged/_datas/sectors/operation/schedule/schedule_lane_class.dart';

// Metadados de foto
import 'package:sisged/_datas/widgets/pickedPhoto/carousel_metadata.dart' as pm;

class ScheduleRepository {
  ScheduleRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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
  }) {
    final folder = 'contracts/$contractId/schedules/${_slug(serviceKey)}/${estaca}_$faixaIndex';
    return _storage.ref(folder);
  }

  String _sanitizeName(String name) =>
      name.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');

  // ---------------- Serviços ----------------
  Future<List<ScheduleData>> loadAvailableServicesFromBudget(String contractId) async {
    final List<ScheduleData> services = <ScheduleData>[
      ScheduleData(
        numero: 0,
        faixaIndex: 0,
        key: 'geral',
        label: 'GERAL',
        icon: Icons.clear_all,
        color: ScheduleStyle.buttonColor('GERAL'),
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
          ScheduleData(
            numero: 0,
            faixaIndex: 0,
            key: key,
            label: rawTitle.toUpperCase(),
            icon: ScheduleStyle.pickIconForTitle(rawTitle),
            color: ScheduleStyle.buttonColor(rawTitle),
          ),
        );
      }
    } catch (_) {/* mantém GERAL */}
    return services;
  }

  // ---------------- Faixas ----------------
  Future<void> saveFaixas(String contractId, List<ScheduleLaneClass> rows) async {
    final positions = rows.map((r) => r.pos).toList();
    final names = rows.map((r) => r.nome).toList();
    final alturas = rows.map((r) => r.altura).toList();

    await _firestore
        .collection('contracts')
        .doc(contractId)
        .collection('schedule_meta')
        .doc('lanes')
        .set({
      'lane_positions': positions,
      'lane_names': names,
      'lane_alturas': alturas,
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
    final alturas = (data['lane_alturas'] as List?)
        ?.map((e) => (e is num) ? e.toDouble() : 20.0)
        .toList() ??
        <double>[];

    if (positions.isEmpty || names.isEmpty || positions.length != names.length) {
      return <ScheduleLaneClass>[];
    }

    final rows = <ScheduleLaneClass>[];
    for (var i = 0; i < names.length; i++) {
      final alt = i < alturas.length ? alturas[i] : 20.0;
      rows.add(ScheduleLaneClass(pos: positions[i], nome: names[i], altura: alt));
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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------- Execuções ----------------
  String _normalizeStatus(String? v) {
    var s = (v ?? '').trim().toLowerCase();
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
        .replaceAll('ç', 'c');
    if (s == 'concluido') return s;
    if (s == 'em andamento') return s;
    return 'a iniciar';
  }

  Future<List<ScheduleData>> fetchExecucoes({
    required String contractId,
    required String selectedServiceKey,
    required List<String> serviceKeysForGeral,
    required ScheduleData metaForSelected,
  }) async {
    final results = <ScheduleData>[];

    ScheduleData _fromDoc(Map<String, dynamic> m, {ScheduleData? meta}) {
      final rawCreated = m['createdAt'];
      final rawUpdated = m['updatedAt'];
      final createdAt = (rawCreated is Timestamp) ? rawCreated.toDate() : rawCreated;
      final updatedAt = (rawUpdated is Timestamp) ? rawUpdated.toDate() : rawUpdated;

      final numero =
      (m['numero'] is num) ? (m['numero'] as num).toInt() : int.tryParse('${m['numero']}');
      final faixaIndex = (m['faixa_index'] is num)
          ? (m['faixa_index'] as num).toInt()
          : int.tryParse('${m['faixa_index']}');

      final normalized = {
        ...m,
        'numero': numero ?? 0,
        'faixa_index': faixaIndex ?? 0,
        'status': _normalizeStatus(m['status']?.toString()),
        'fotos': (m['fotos'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
        'fotos_meta': (m['fotos_meta'] as List?)
            ?.map((e) => Map<String, dynamic>.from((e as Map)))
            .toList() ??
            const <Map<String, dynamic>>[],
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

      return ScheduleData.fromMap(normalized, meta: meta);
    }

    if (selectedServiceKey == 'geral') {
      if (serviceKeysForGeral.isNotEmpty) {
        final snaps = await Future.wait([
          for (final k in serviceKeysForGeral)
            _contractCol(contractId, _collectionForService(k)).get(),
        ]);
        for (final snap in snaps) {
          for (final d in snap.docs) {
            final m = d.data();
            results.add(
              _fromDoc({
                ...m,
                'key': 'geral',
                'label': 'GERAL',
                'color': Colors.black54.value,
                'icon': Icons.clear_all.codePoint,
              }),
            );
          }
        }
      }
    } else {
      final snap = await _contractCol(contractId, _collectionForService(selectedServiceKey)).get();
      for (final d in snap.docs) {
        results.add(_fromDoc(d.data(), meta: metaForSelected));
      }
    }

    final map = <String, ScheduleData>{};
    for (final e in results) {
      final k = '${e.numero}_${e.faixaIndex}';
      final cur = map[k];
      if (cur == null ||
          (e.createdAt != null &&
              (cur.createdAt == null || e.createdAt!.isAfter(cur.createdAt!)))) {
        map[k] = e;
      }
    }
    return map.values.toList();
  }

  // ---------------- Upsert/Remove célula ----------------
  Future<void> upsertSquare({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required String tipoLabel,
    required String status,
    String? comentario,
    required String currentUserId,
  }) async {
    if (serviceKey == 'geral') return;

    final col = _contractCol(contractId, _collectionForService(serviceKey));
    final query = await col
        .where('numero', isEqualTo: estaca)
        .where('faixa_index', isEqualTo: faixaIndex)
        .limit(1)
        .get();

    if (_normalizeStatus(status) == 'a iniciar') {
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
      return;
    }

    final hasComment = (comentario?.trim().isNotEmpty ?? false);
    final base = <String, dynamic>{
      'numero': estaca,
      'faixa_index': faixaIndex,
      'tipo': tipoLabel,
      'status': _normalizeStatus(status),
    };

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        ...base,
        if (hasComment) 'comentario': comentario!.trim() else 'comentario': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
      });
    } else {
      await col.add({
        ...base,
        if (hasComment) 'comentario': comentario!.trim(),
        'fotos': <String>[],
        'fotos_meta': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
      });
    }
  }

  // ---------------- Fotos ----------------
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

  Future<void> deleteSquarePhoto({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required String photoUrl,
    required String currentUserId,
  }) async {
    if (serviceKey == 'geral') return;

    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (_) {}

    final col = _contractCol(contractId, _collectionForService(serviceKey));
    final query = await col
        .where('numero', isEqualTo: estaca)
        .where('faixa_index', isEqualTo: faixaIndex)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;

      final updates = <String, dynamic>{
        'fotos': FieldValue.arrayRemove([photoUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
      };

      try {
        final snap = await docRef.get();
        final data = snap.data();
        final metaList = (data?['fotos_meta'] as List?)?.cast<Map>() ?? const [];
        final metasToRemove = metaList
            .where((m) => (m['url'] as String?) == photoUrl)
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        if (metasToRemove.isNotEmpty) {
          updates['fotos_meta'] = FieldValue.arrayRemove(metasToRemove);
        }
      } catch (_) {}

      await docRef.update(updates);
    }
  }

  Future<void> setSquarePhotos({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required List<String> photoUrls,
    required String currentUserId,
    List<pm.CarouselMetadata> metas = const [],
  }) async {
    if (serviceKey == 'geral') return;

    final docRef = await _getOrCreateSquareDocRef(
      contractId: contractId,
      serviceKey: serviceKey,
      estaca: estaca,
      faixaIndex: faixaIndex,
      currentUserId: currentUserId,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    final metasByUrl = { for (final m in metas) if ((m.url ?? '').isNotEmpty) m.url!: m };

    final metasToSave = <Map<String, dynamic>>[];
    for (final u in photoUrls) {
      final m = metasByUrl[u];
      metasToSave.add({
        'url': u,
        'name': (m?.name) ?? u.split('/').last,
        'takenAt': m?.takenAt?.millisecondsSinceEpoch,
        'takenAtMs': m?.takenAt?.millisecondsSinceEpoch,
        'lat': m?.lat,
        'lng': m?.lng,
        'make': m?.make,
        'model': m?.model,
        'orientation': m?.orientation,
        'uploadedAtMs': m?.uploadedAtMs ?? now,
        'uploadedBy': m?.uploadedBy ?? currentUserId,
      });
    }

    await docRef.update({
      'fotos': photoUrls,
      'fotos_meta': metasToSave,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateSquareDocRef({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required String currentUserId,
  }) async {
    final col = _contractCol(contractId, _collectionForService(serviceKey));
    final query = await col
        .where('numero', isEqualTo: estaca)
        .where('faixa_index', isEqualTo: faixaIndex)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first.reference;

    final doc = await col.add({
      'numero': estaca,
      'faixa_index': faixaIndex,
      'fotos': <String>[],
      'fotos_meta': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    });
    return doc;
  }

  Future<List<String>> uploadSquarePhotos({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required List<Uint8List> filesBytes,
    List<String>? fileNames,
    String contentType = 'image/jpeg',
    required String currentUserId,
    List<pm.CarouselMetadata> metasFromUi = const [],
    DateTime? takenAt,
  }) async {
    if (serviceKey == 'geral') return const <String>[];
    if (filesBytes.isEmpty) return const <String>[];

    final docRef = await _getOrCreateSquareDocRef(
      contractId: contractId,
      serviceKey: serviceKey,
      estaca: estaca,
      faixaIndex: faixaIndex,
      currentUserId: currentUserId,
    );

    final folderRef = _photosFolderRef(
      contractId: contractId,
      serviceKey: serviceKey,
      estaca: estaca,
      faixaIndex: faixaIndex,
    );

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final urls = <String>[];
    final metas = <Map<String, dynamic>>[];

    for (int i = 0; i < filesBytes.length; i++) {
      final suggestedName = (fileNames != null &&
          i < fileNames.length &&
          fileNames[i].trim().isNotEmpty)
          ? _sanitizeName(fileNames[i])
          : 'img_${nowMs}_$i.jpg';

      final unique = '$suggestedName.${DateTime.now().microsecondsSinceEpoch}';
      final fileRef = folderRef.child(unique);
      final contentTypeToUse = _guessContentType(suggestedName);

      if (kDebugMode) {
        debugPrint('[UPLOAD] file[$i] name="$unique" ct="$contentTypeToUse"');
      }

      final uploadTask = await fileRef.putData(
        filesBytes[i],
        SettableMetadata(contentType: contentTypeToUse),
      );
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);

      final m = (i < metasFromUi.length) ? metasFromUi[i] : const pm.CarouselMetadata();

      if (kDebugMode) {
        debugPrint('[UPLOAD] metasFromUi[$i] => ${m.toMap()}');
      }

      metas.add({
        'url': url,
        'name': m.name ?? unique,
        'takenAt': (m.takenAt ?? takenAt)?.millisecondsSinceEpoch,
        'takenAtMs': (m.takenAt ?? takenAt)?.millisecondsSinceEpoch,
        'lat': m.lat,
        'lng': m.lng,
        'make': m.make,
        'model': m.model,
        'orientation': m.orientation,
        'uploadedAtMs': m.uploadedAtMs ?? nowMs,
        'uploadedBy': m.uploadedBy ?? currentUserId,
      });
    }

    if (kDebugMode) {
      debugPrint('[UPLOAD] to Firestore -> fotos=${urls.length} metas=${metas.length}');
      for (var i = 0; i < metas.length; i++) {
        debugPrint('[UPLOAD] meta[$i] ${metas[i]}');
      }
    }

    if (urls.isNotEmpty) {
      await docRef.update({
        'fotos': FieldValue.arrayUnion(urls),
        'fotos_meta': FieldValue.arrayUnion(metas),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
      });
    }

    return urls;
  }

  // ---------- Debug helper ----------
  Future<void> debugPrintSquare({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) async {
    final col = _contractCol(contractId, _collectionForService(serviceKey));
    final q = await col
        .where('numero', isEqualTo: estaca)
        .where('faixa_index', isEqualTo: faixaIndex)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      debugPrint('[DEBUG SQUARE] não encontrado.');
      return;
    }
    final data = q.docs.first.data();
    debugPrint('[DEBUG SQUARE] fotos: ${(data['fotos'] as List?)?.length ?? 0}');
    final metas = (data['fotos_meta'] as List?)?.cast<Map>() ?? const [];
    debugPrint('[DEBUG SQUARE] fotos_meta: ${metas.length}');
    for (var i = 0; i < metas.length; i++) {
      debugPrint('  meta[$i] -> ${Map<String, dynamic>.from(metas[i])}');
    }
  }
}
