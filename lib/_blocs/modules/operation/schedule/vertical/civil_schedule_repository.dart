// lib/_blocs/modules/operation/operation/civil/civil_schedule_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';

class CivilScheduleRepository {
  CivilScheduleRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required String tenantId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _tenantId = _validateTenantId(tenantId);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _tenantId;

  String get tenantId => _tenantId;

  static String _validateTenantId(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para CivilScheduleRepository.',
      );
    }

    return clean;
  }

  String _cleanContractId(String contractId) {
    final clean = contractId.trim();

    if (clean.isEmpty) {
      throw ArgumentError('contractId é obrigatório.');
    }

    return clean;
  }

  String _cleanPolygonId(String polygonId) {
    final clean = polygonId.trim();

    if (clean.isEmpty) {
      throw ArgumentError('polygonId é obrigatório.');
    }

    return clean;
  }

  String _sanitizeName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _contractRef(String contractId) {
    return _contractsCol().doc(_cleanContractId(contractId));
  }

  CollectionReference<Map<String, dynamic>> _colPolygons(String contractId) {
    return _contractRef(contractId).collection('civil_polygons');
  }

  DocumentReference<Map<String, dynamic>> _docMetaBoard(String contractId) {
    return _contractRef(contractId).collection('civil_meta').doc('board');
  }

  DocumentReference<Map<String, dynamic>> _docAssets(String contractId) {
    return _contractRef(contractId).collection('civil_assets').doc('files');
  }

  Reference _assetFolder(String contractId) {
    final cleanContractId = _cleanContractId(contractId);

    return _storage.ref(
      'tenants/$tenantId/contracts/$cleanContractId/civil/assets',
    );
  }

  Reference _polygonFolder(String contractId, String polygonId) {
    final cleanContractId = _cleanContractId(contractId);
    final cleanPolygonId = _cleanPolygonId(polygonId);

    return _storage.ref(
      'tenants/$tenantId/contracts/$cleanContractId/civil/polygons/$cleanPolygonId',
    );
  }

  String _guessContentType(
      String name, [
        String fallback = 'application/octet-stream',
      ]) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.dxf')) return 'image/vnd.dxf';

    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';

    return fallback;
  }

  Map<String, dynamic> _deleteableTakenAtMap(int? takenAtMs) {
    return <String, dynamic>{
      if (takenAtMs != null) 'takenAtMs': takenAtMs,
      if (takenAtMs == null) 'takenAtMs': FieldValue.delete(),
    };
  }

  Map<String, dynamic> _photoMetaMap({
    required PhotoData photo,
    required String url,
    required String storedName,
    int? fallbackTakenAtMs,
    int? fallbackUploadedAtMs,
    String? fallbackUploadedBy,
  }) {
    final takenAtMs =
        photo.takenAt?.millisecondsSinceEpoch ?? fallbackTakenAtMs;

    final uploadedAtMs = photo.uploadedAtMs ?? fallbackUploadedAtMs;
    final uploadedBy = photo.uploadedBy ?? fallbackUploadedBy;

    return <String, dynamic>{
      'id': photo.id,
      'url': url,
      'name': photo.name.trim().isNotEmpty ? photo.name.trim() : storedName,
      if (takenAtMs != null) 'takenAtMs': takenAtMs,
      if (takenAtMs != null) 'takenAt': takenAtMs,
      if (photo.lat != null) 'lat': photo.lat,
      if (photo.lng != null) 'lng': photo.lng,
      if (photo.make != null) 'make': photo.make,
      if (photo.model != null) 'model': photo.model,
      if (photo.orientation != null) 'orientation': photo.orientation,
      if (uploadedAtMs != null) 'uploadedAtMs': uploadedAtMs,
      if (uploadedBy != null && uploadedBy.trim().isNotEmpty)
        'uploadedBy': uploadedBy,
    };
  }

  Future<String> uploadAsset({
    required String contractId,
    required Uint8List bytes,
    required String filename,
    required String currentUserId,
  }) async {
    final cleanContractId = _cleanContractId(contractId);
    final safeFilename = _sanitizeName(filename);

    if (safeFilename.isEmpty) {
      throw ArgumentError('filename é obrigatório para upload de asset.');
    }

    final ref = _assetFolder(cleanContractId).child(safeFilename);

    final task = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: _guessContentType(safeFilename),
        customMetadata: <String, String>{
          'tenantId': tenantId,
          'contractId': cleanContractId,
          'uploadedBy': currentUserId,
        },
      ),
    );

    final url = await task.ref.getDownloadURL();

    await _docAssets(cleanContractId).set({
      'tenantId': tenantId,
      'contractId': cleanContractId,
      if (safeFilename.toLowerCase().endsWith('.pdf')) 'pdf_url': url,
      if (safeFilename.toLowerCase().endsWith('.dxf')) 'dxf_url': url,
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
    final cleanContractId = _cleanContractId(contractId);

    await _docMetaBoard(cleanContractId).set({
      'tenantId': tenantId,
      'contractId': cleanContractId,
      if (pageCount != null) 'page_count': pageCount,
      if (pageCount == null) 'page_count': FieldValue.delete(),
      if (dxfBounds != null) 'dxf_bounds': dxfBounds,
      if (dxfBounds == null) 'dxf_bounds': FieldValue.delete(),
      if (pdfInfo != null) 'pdf_info': pdfInfo,
      if (pdfInfo == null) 'pdf_info': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> loadBoardMeta(String contractId) async {
    final cleanContractId = _cleanContractId(contractId);

    final snap = await _docMetaBoard(cleanContractId).get();

    return snap.data() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loadAssets(String contractId) async {
    final cleanContractId = _cleanContractId(contractId);

    final snap = await _docAssets(cleanContractId).get();

    return snap.data() ?? <String, dynamic>{};
  }

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
    final cleanContractId = _cleanContractId(contractId);
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('Nome do polígono é obrigatório.');
    }

    if (points.isEmpty) {
      throw ArgumentError('O polígono precisa ter pontos.');
    }

    final cleanComment = comentario?.trim();

    final base = <String, dynamic>{
      'tenantId': tenantId,
      'contractId': cleanContractId,
      'page': page,
      'name': cleanName,
      if (tipo != null && tipo.trim().isNotEmpty) 'tipo': tipo.trim(),
      if (tipo == null || tipo.trim().isEmpty) 'tipo': FieldValue.delete(),
      'status': _canonStatus(status),
      if (cleanComment != null && cleanComment.isNotEmpty)
        'comentario': cleanComment,
      if (cleanComment == null || cleanComment.isEmpty)
        'comentario': FieldValue.delete(),
      if (areaM2 != null) 'area_m2': areaM2,
      if (areaM2 == null) 'area_m2': FieldValue.delete(),
      if (perimeterM != null) 'perimeter_m': perimeterM,
      if (perimeterM == null) 'perimeter_m': FieldValue.delete(),
      'points': points.map((point) {
        return <String, double?>{
          'x': point['x'],
          'y': point['y'],
        };
      }).toList(growable: false),
      ..._deleteableTakenAtMap(takenAtMs),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    };

    if (polygonId == null || polygonId.trim().isEmpty) {
      final doc = await _colPolygons(cleanContractId).add({
        ...base,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
      });

      return doc.id;
    }

    final cleanPolygonId = _cleanPolygonId(polygonId);

    await _colPolygons(cleanContractId)
        .doc(cleanPolygonId)
        .set(base, SetOptions(merge: true));

    return cleanPolygonId;
  }

  Future<void> deletePolygon({
    required String contractId,
    required String polygonId,
  }) async {
    final cleanContractId = _cleanContractId(contractId);
    final cleanPolygonId = _cleanPolygonId(polygonId);

    final doc = _colPolygons(cleanContractId).doc(cleanPolygonId);

    try {
      final snap = await doc.get();
      final data = snap.data() ?? const <String, dynamic>{};

      final urls = data['fotos'] is List
          ? List<String>.from(data['fotos'] as List)
          : const <String>[];

      for (final url in urls) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }
    } catch (_) {}

    await doc.delete();
  }

  Future<List<Map<String, dynamic>>> fetchPolygons({
    required String contractId,
    int? page,
  }) async {
    final cleanContractId = _cleanContractId(contractId);
    final col = _colPolygons(cleanContractId);

    Query<Map<String, dynamic>> withPage(Query<Map<String, dynamic>> query) {
      if (page == null) return query;

      return query.where('page', isEqualTo: page);
    }

    Future<QuerySnapshot<Map<String, dynamic>>?> tryQuery(
        Query<Map<String, dynamic>> Function() builder,
        ) async {
      try {
        return await builder().get();
      } catch (_) {
        return null;
      }
    }

    final attempts = <Future<QuerySnapshot<Map<String, dynamic>>?> Function()>[
          () => tryQuery(() => withPage(col).orderBy('createdAt').orderBy('name')),
          () => tryQuery(() => withPage(col).orderBy('createdAt')),
          () => tryQuery(() => withPage(col).orderBy('updatedAt').orderBy('name')),
          () => tryQuery(() => withPage(col).orderBy('updatedAt')),
          () => tryQuery(() => withPage(col).orderBy('name')),
          () => tryQuery(() => withPage(col)),
          () => tryQuery(() => col),
    ];

    QuerySnapshot<Map<String, dynamic>>? snap;

    for (final attempt in attempts) {
      snap = await attempt();

      if (snap != null) {
        break;
      }
    }

    if (snap == null) {
      return const <Map<String, dynamic>>[];
    }

    final list = snap.docs.map((doc) {
      return <String, dynamic>{
        'id': doc.id,
        ...doc.data(),
      };
    }).toList(growable: false);

    final hasCreatedAt = list.any((item) => item['createdAt'] != null);
    final hasUpdatedAt = list.any((item) => item['updatedAt'] != null);

    int tsMillis(dynamic value) {
      if (value is Timestamp) {
        return value.millisecondsSinceEpoch;
      }

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      return -1;
    }

    list.sort((a, b) {
      if (hasCreatedAt) {
        final createdCompare =
        tsMillis(a['createdAt']).compareTo(tsMillis(b['createdAt']));

        if (createdCompare != 0) {
          return createdCompare;
        }
      }

      if (hasUpdatedAt) {
        final updatedCompare =
        tsMillis(a['updatedAt']).compareTo(tsMillis(b['updatedAt']));

        if (updatedCompare != 0) {
          return updatedCompare;
        }
      }

      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();

      return nameA.compareTo(nameB);
    });

    return list;
  }

  Future<List<String>> applyPolygonChanges({
    required String contractId,
    required String polygonId,
    required String status,
    String? comentario,
    int? takenAtMs,
    required List<String> finalPhotoUrls,
    required List<PhotoData> newPhotos,
    required String currentUserId,
  }) async {
    final cleanContractId = _cleanContractId(contractId);
    final cleanPolygonId = _cleanPolygonId(polygonId);

    final doc = _colPolygons(cleanContractId).doc(cleanPolygonId);
    final cleanStatus = _canonStatus(status);

    if (cleanStatus == 'a_iniciar') {
      try {
        final snap = await doc.get();
        final data = snap.data() ?? const <String, dynamic>{};

        final urls = data['fotos'] is List
            ? List<String>.from(data['fotos'] as List)
            : const <String>[];

        for (final url in urls) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (_) {}
        }
      } catch (_) {}

      await doc.delete();

      return const <String>[];
    }

    final cleanComment = comentario?.trim();

    await doc.set({
      'tenantId': tenantId,
      'contractId': cleanContractId,
      'status': cleanStatus,
      if (cleanComment != null && cleanComment.isNotEmpty)
        'comentario': cleanComment,
      if (cleanComment == null || cleanComment.isEmpty)
        'comentario': FieldValue.delete(),
      ..._deleteableTakenAtMap(takenAtMs),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    }, SetOptions(merge: true));

    final uploadedUrls = <String>[];
    final uploadedMetas = <Map<String, dynamic>>[];

    final directUrlPhotos = <PhotoData>[];
    final uploadPhotos = <PhotoData>[];

    for (final photo in newPhotos) {
      final hasBytes = photo.bytes != null;
      final hasUrl = photo.url != null && photo.url!.trim().isNotEmpty;

      if (hasBytes) {
        uploadPhotos.add(photo);
      } else if (hasUrl) {
        directUrlPhotos.add(photo);
      }
    }

    if (uploadPhotos.isNotEmpty) {
      final folder = _polygonFolder(cleanContractId, cleanPolygonId);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < uploadPhotos.length; i++) {
        final photo = uploadPhotos[i];

        final suggested = photo.name.trim().isNotEmpty
            ? _sanitizeName(photo.name.trim())
            : 'img_${nowMs}_$i.jpg';

        final safeName = suggested.isEmpty ? 'img_${nowMs}_$i.jpg' : suggested;
        final unique = '${DateTime.now().microsecondsSinceEpoch}_$safeName';

        final task = await folder.child(unique).putData(
          photo.bytes!,
          SettableMetadata(
            contentType: _guessContentType(safeName, 'image/jpeg'),
            customMetadata: <String, String>{
              'tenantId': tenantId,
              'contractId': cleanContractId,
              'polygonId': cleanPolygonId,
              'photoId': photo.id,
              'uploadedBy': photo.uploadedBy ?? currentUserId,
            },
          ),
        );

        final url = await task.ref.getDownloadURL();

        uploadedUrls.add(url);

        uploadedMetas.add(
          _photoMetaMap(
            photo: photo,
            url: url,
            storedName: unique,
            fallbackTakenAtMs: takenAtMs,
            fallbackUploadedAtMs: nowMs,
            fallbackUploadedBy: currentUserId,
          ),
        );
      }
    }

    final directUrls = directUrlPhotos
        .map((photo) => photo.url?.trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    final directMetas = directUrlPhotos
        .where((photo) => photo.url != null && photo.url!.trim().isNotEmpty)
        .map((photo) {
      final url = photo.url!.trim();

      return _photoMetaMap(
        photo: photo,
        url: url,
        storedName: photo.name.trim().isEmpty ? url.split('/').last : photo.name,
        fallbackTakenAtMs: takenAtMs,
        fallbackUploadedAtMs: photo.uploadedAtMs,
        fallbackUploadedBy: photo.uploadedBy ?? currentUserId,
      );
    }).toList(growable: false);

    final snap = await doc.get();
    final data = snap.data() ?? const <String, dynamic>{};

    final currentUrls = data['fotos'] is List
        ? List<String>.from(data['fotos'] as List)
        : const <String>[];

    final orderedUrls = <String>[
      ...finalPhotoUrls.where((url) => url.trim().isNotEmpty),
      ...directUrls,
      ...uploadedUrls,
    ];

    final removed = currentUrls
        .where((url) => !orderedUrls.contains(url))
        .toList(growable: false);

    for (final url in removed) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {}
    }

    final rawMetaList = data['fotos_meta'] is List
        ? data['fotos_meta'] as List
        : data['fotosMeta'] is List
        ? data['fotosMeta'] as List
        : const [];

    final oldMetas = rawMetaList
        .whereType<Object>()
        .map((item) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      return <String, dynamic>{};
    })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final byUrl = <String, Map<String, dynamic>>{};

    for (final meta in oldMetas) {
      final url = meta['url']?.toString().trim() ?? '';

      if (url.isNotEmpty && !removed.contains(url)) {
        byUrl[url] = meta;
      }
    }

    for (final meta in directMetas) {
      final url = meta['url']?.toString().trim() ?? '';

      if (url.isNotEmpty) {
        byUrl[url] = meta;
      }
    }

    for (final meta in uploadedMetas) {
      final url = meta['url']?.toString().trim() ?? '';

      if (url.isNotEmpty) {
        byUrl[url] = meta;
      }
    }

    final orderedMetas = orderedUrls.map((url) {
      final meta = byUrl[url];

      if (meta != null) {
        return Map<String, dynamic>.from(meta);
      }

      return <String, dynamic>{
        'url': url,
        'name': url.split('/').last,
      };
    }).toList(growable: false);

    await doc.set({
      if (orderedUrls.isEmpty) 'fotos': FieldValue.delete(),
      if (orderedUrls.isNotEmpty) 'fotos': orderedUrls,
      if (orderedMetas.isEmpty) 'fotos_meta': FieldValue.delete(),
      if (orderedMetas.isNotEmpty) 'fotos_meta': orderedMetas,

      // Remove eventual campo antigo/camelCase para manter padrão único.
      'fotosMeta': FieldValue.delete(),

      ..._deleteableTakenAtMap(takenAtMs),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
    }, SetOptions(merge: true));

    return uploadedUrls;
  }

  String _canonStatus(String raw) {
    final value = raw.toLowerCase().trim().replaceAll(
      RegExp(r'[\s\-_]+'),
      '_',
    );

    if (value.contains('conclu')) {
      return 'concluido';
    }

    if (value.contains('andament') || value.contains('progress')) {
      return 'em_andamento';
    }

    return 'a_iniciar';
  }
}