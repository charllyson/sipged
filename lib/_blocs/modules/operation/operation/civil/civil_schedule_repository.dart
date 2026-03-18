import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class CivilScheduleRepository {
  CivilScheduleRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  // ---------- Paths ----------
  CollectionReference<Map<String, dynamic>> _colPolygons(String contractId) =>
      _firestore.collection('contracts').doc(contractId).collection('civil_polygons');

  DocumentReference<Map<String, dynamic>> _docMetaBoard(String contractId) =>
      _firestore.collection('contracts').doc(contractId).collection('civil_meta').doc('board');

  DocumentReference<Map<String, dynamic>> _docAssets(String contractId) =>
      _firestore.collection('contracts').doc(contractId).collection('civil_assets').doc('files');

  Reference _assetFolder(String contractId) =>
      _storage.ref('contracts/$contractId/civil/assets');

  Reference _polygonFolder(String contractId, String polygonId) =>
      _storage.ref('contracts/$contractId/civil/polygons/$polygonId');

  String _guessContentType(String name, [String def = 'application/octet-stream']) {
    final s = name.toLowerCase();
    if (s.endsWith('.pdf')) return 'application/pdf';
    if (s.endsWith('.dxf')) return 'image/vnd.dxf';
    if (s.endsWith('.png')) return 'image/png';
    if (s.endsWith('.jpg') || s.endsWith('.jpeg')) return 'image/jpeg';
    if (s.endsWith('.webp')) return 'image/webp';
    return def;
  }

  // ---------- Assets (PDF/DXF) ----------
  Future<String> uploadAsset({
    required String contractId,
    required Uint8List bytes,
    required String filename,
    required String currentUserId,
  }) async {
    final ref = _assetFolder(contractId).child(filename);
    final task = await ref.putData(bytes, SettableMetadata(contentType: _guessContentType(filename)));
    final url = await task.ref.getDownloadURL();

    await _docAssets(contractId).set({
      if (filename.toLowerCase().endsWith('.pdf')) 'pdf_url': url,
      if (filename.toLowerCase().endsWith('.dxf')) 'dxf_url': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    }, SetOptions(merge: true));

    return url;
  }

  Future<void> saveBoardMeta({
    required String contractId,
    int? pageCount,
    Map<String, dynamic>? dxfBounds,
    Map<String, dynamic>? pdfInfo,
    required String currentUserId,
  }) async {
    await _docMetaBoard(contractId).set({
      'page_count': ?pageCount,
      'dxf_bounds': ?dxfBounds,
      'pdf_info': ?pdfInfo,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> loadBoardMeta(String contractId) async {
    final s = await _docMetaBoard(contractId).get();
    return s.data() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loadAssets(String contractId) async {
    final s = await _docAssets(contractId).get();
    return s.data() ?? <String, dynamic>{};
  }

  // ---------- Polígonos ----------
  Future<String> upsertPolygon({
    required String contractId,
    String? polygonId,
    required int page,
    required String name,
    String? tipo,
    String status = 'a_iniciar',
    String? comentario,
    double? areaM2,
    double? perimeterM,
    required List<Map<String, double>> points,
    int? takenAtMs,
    required String currentUserId,
  }) async {
    final base = <String, dynamic>{
      'page': page,
      'name': name,
      'tipo': tipo,
      'status': _canonStatus(status),
      'comentario': (comentario?.trim().isEmpty ?? true) ? null : comentario!.trim(),
      'area_m2': areaM2,
      'perimeter_m': perimeterM,
      'points': points.map((p) => {'x': p['x'], 'y': p['y']}).toList(),
      'takenAtMs': ?takenAtMs,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    };

    if (polygonId == null) {
      final doc = await _colPolygons(contractId).add({
        ...base,
        // ⚠️ createdAt criado sempre que inserir (garante ordenação determinística)
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
      });
      return doc.id;
    } else {
      await _colPolygons(contractId).doc(polygonId).set(base, SetOptions(merge: true));
      return polygonId;
    }
  }

  Future<void> deletePolygon({
    required String contractId,
    required String polygonId,
  }) async {
    try {
      final snap = await _colPolygons(contractId).doc(polygonId).get();
      final data = snap.data() ?? {};
      final urls = (data['fotos'] is List) ? List<String>.from(data['fotos']) : const <String>[];
      for (final u in urls) {
        try { await _storage.refFromURL(u).delete(); } catch (_) {}
      }
    } catch (_) {}
    await _colPolygons(contractId).doc(polygonId).delete();
  }

  /// ====== FETCH DETERMINÍSTICO COM FALLBACK ======
  /// Ordem estável preferida:
  /// 1) createdAt asc
  /// 2) updatedAt asc
  /// 3) name asc
  ///
  /// Se faltar índice/field: tenta combinações mais fracas e, no limite,
  /// aplica ordenação em memória para garantir estabilidade.
  Future<List<Map<String, dynamic>>> fetchPolygons({
    required String contractId,
    int? page,
  }) async {
    final col = _colPolygons(contractId);

    Query<Map<String, dynamic>> withPage(Query<Map<String, dynamic>> q) {
      return (page != null) ? q.where('page', isEqualTo: page) : q;
    }

    Future<QuerySnapshot<Map<String, dynamic>>?> test(
        Query<Map<String, dynamic>> Function() builder,
        ) async {
      try {
        final q = builder();
        return await q.get();
      } catch (_) {
        return null;
      }
    }

    final attempts = <Future<QuerySnapshot<Map<String, dynamic>>?> Function()>[
      // page + createdAt + name
          () => test(() => withPage(col).orderBy('createdAt').orderBy('name')),
      // page + createdAt
          () => test(() => withPage(col).orderBy('createdAt')),
      // page + updatedAt + name
          () => test(() => withPage(col).orderBy('updatedAt').orderBy('name')),
      // page + updatedAt
          () => test(() => withPage(col).orderBy('updatedAt')),
      // page + name
          () => test(() => withPage(col).orderBy('name')),
      // só page (sem order)
          () => test(() => withPage(col)),
      // sem filtros (último recurso)
          () => test(() => col),
    ];

    QuerySnapshot<Map<String, dynamic>>? snap;
    for (final f in attempts) {
      snap = await f();
      if (snap != null) break;
    }

    if (snap == null) return const <Map<String, dynamic>>[];

    final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

    // Ordenação em memória para estabilidade
    bool hasCreatedAt = list.any((e) => e['createdAt'] != null);
    bool hasUpdatedAt = list.any((e) => e['updatedAt'] != null);

    int tsMillis(dynamic v) {
      final ts = (v is Timestamp) ? v : null;
      return ts?.millisecondsSinceEpoch ?? -1; // nulos primeiro
    }

    list.sort((a, b) {
      if (hasCreatedAt) {
        final c = tsMillis(a['createdAt']).compareTo(tsMillis(b['createdAt']));
        if (c != 0) return c;
      }
      if (hasUpdatedAt) {
        final u = tsMillis(a['updatedAt']).compareTo(tsMillis(b['updatedAt']));
        if (u != 0) return u;
      }
      final an = (a['name'] ?? '').toString().toLowerCase();
      final bn = (b['name'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });

    return list;
  }

  // ---------- Apply (status/comentário/fotos/ordem) ----------
  Future<List<String>> applyPolygonChanges({
    required String contractId,
    required String polygonId,
    required String status,
    String? comentario,
    int? takenAtMs,
    required List<String> finalPhotoUrls,
    required List<Uint8List> newFilesBytes,
    List<String>? newFileNames,
    List<pm.CarouselMetadata> newPhotoMetas = const [],
    required String currentUserId,
  }) async {
    final doc = _colPolygons(contractId).doc(polygonId);

    if (_canonStatus(status) == 'a_iniciar') {
      try {
        final s = await doc.get();
        final data = s.data() ?? {};
        final urls = (data['fotos'] is List) ? List<String>.from(data['fotos']) : const <String>[];
        for (final u in urls) { try { await _storage.refFromURL(u).delete(); } catch (_) {} }
      } catch (_) {}
      await doc.delete();
      return const <String>[];
    }

    await doc.set({
      'status': _canonStatus(status),
      'comentario': (comentario?.trim().isNotEmpty ?? false) ? comentario!.trim() : FieldValue.delete(),
      'takenAtMs': ?takenAtMs,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    }, SetOptions(merge: true));

    final uploadedUrls = <String>[];
    final uploadedMetas = <Map<String, dynamic>>[];

    if (newFilesBytes.isNotEmpty) {
      final folder = _polygonFolder(contractId, polygonId);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < newFilesBytes.length; i++) {
        final name = (newFileNames != null && i < newFileNames.length && (newFileNames[i].trim().isNotEmpty))
            ? newFileNames[i].trim()
            : 'img_${nowMs}_$i.jpg';
        final unique = '$name.${DateTime.now().microsecondsSinceEpoch}';
        final task = await folder.child(unique).putData(
          newFilesBytes[i],
          SettableMetadata(contentType: _guessContentType(name, 'image/jpeg')),
        );
        final url = await task.ref.getDownloadURL();
        uploadedUrls.add(url);

        final meta = (i < newPhotoMetas.length) ? newPhotoMetas[i] : const pm.CarouselMetadata();
        uploadedMetas.add({
          'url': url,
          'name': meta.name ?? unique,
          'takenAtMs': (meta.takenAt)?.millisecondsSinceEpoch ?? takenAtMs,
          'lat': meta.lat,
          'lng': meta.lng,
          'make': meta.make,
          'model': meta.model,
          'orientation': meta.orientation,
          'uploadedAtMs': meta.uploadedAtMs ?? nowMs,
          'uploadedBy': meta.uploadedBy ?? currentUserId,
        });
      }

      await doc.update({
        if (uploadedUrls.isNotEmpty) 'fotos': FieldValue.arrayUnion(uploadedUrls),
        if (uploadedMetas.isNotEmpty) 'fotos_meta': FieldValue.arrayUnion(uploadedMetas),
        'takenAtMs': ?takenAtMs,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
      });
    }

    final snap = await doc.get();
    final data = snap.data() ?? {};
    final currentUrls = (data['fotos'] is List) ? List<String>.from(data['fotos']) : const <String>[];
    final removed = currentUrls.where((u) => !finalPhotoUrls.contains(u) && !uploadedUrls.contains(u)).toList();

    if (removed.isNotEmpty) {
      for (final u in removed) { try { await _storage.refFromURL(u).delete(); } catch (_) {} }
      final rawMeta = (data['fotos_meta'] is List) ? (data['fotos_meta'] as List) : const [];
      final metas = rawMeta.whereType<Object>()
          .map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty).toList();
      final metasToRemove = metas.where((m) => removed.contains(m['url'] as String?)).toList();

      await doc.update({
        'fotos': FieldValue.arrayRemove(removed),
        if (metasToRemove.isNotEmpty) 'fotos_meta': FieldValue.arrayRemove(metasToRemove),
        'takenAtMs': ?takenAtMs,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
      });
    }

    final ordered = <String>[...finalPhotoUrls, ...uploadedUrls];
    if (ordered.isEmpty) {
      await doc.update({
        'fotos': FieldValue.delete(),
        'fotos_meta': FieldValue.delete(),
        'takenAtMs': ?takenAtMs,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId,
      });
      return uploadedUrls;
    }

    final snap2 = await doc.get();
    final d2 = snap2.data() ?? {};
    final rawMeta2 = (d2['fotos_meta'] is List) ? (d2['fotos_meta'] as List) : const [];
    final metaList2 = rawMeta2.whereType<Object>()
        .map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .where((m) => m.isNotEmpty).toList();
    final byUrl = <String, Map<String, dynamic>>{
      for (final m in metaList2) if ((m['url'] as String?)?.isNotEmpty ?? false) m['url'] as String: m,
    };

    final metasAll = <Map<String, dynamic>>[
      for (final u in ordered) (byUrl[u] != null) ? Map<String, dynamic>.from(byUrl[u]!) : {'url': u, 'name': u.split('/').last}
    ];

    await doc.update({
      'fotos': ordered,
      'fotos_meta': metasAll,
      'takenAtMs': ?takenAtMs,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    });

    return uploadedUrls;
  }

  String _canonStatus(String raw) {
    final s = raw.toLowerCase().trim().replaceAll(RegExp(r'[\s\-_]+'), '_');
    if (s.contains('conclu')) return 'concluido';
    if (s.contains('andament') || s.contains('progress')) return 'em_andamento';
    return 'a_iniciar';
  }
}
