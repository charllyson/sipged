// lib/_blocs/modules/operation/schedule/horizontal/schedule_linear_repository.dart

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';

import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/services/photo_utils.dart';

class ScheduleLinearBulkCellTarget {
  const ScheduleLinearBulkCellTarget({
    required this.estaca,
    required this.faixaIndex,
  });

  final int estaca;
  final int faixaIndex;
}

class ScheduleLinearRepository {
  ScheduleLinearRepository({
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

  final Map<String, List<ScheduleLinearCellData>> _execCache = {};
  final Map<String, List<ScheduleLinearServicesData>> _servicesCache = {};
  final Map<String, Map<String, double>> _totalsCache = {};
  final Map<String, List<ScheduleLinearLaneData>> _lanesCache = {};
  final Map<String, ({List<int> periods, Map<String, List<double>> grid})>
  _physfinCache = {};
  final Map<String, ScheduleLinearData?> _geometryCache = {};

  static String _validateTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para ScheduleLinearRepository.',
      );
    }

    return cleanTenantId;
  }

  void clearContractCache(String contractId) {
    final cleanContractId = contractId.trim();

    _execCache.removeWhere((key, _) => key.startsWith('$cleanContractId|'));
    _servicesCache.remove(cleanContractId);
    _totalsCache.remove(cleanContractId);
    _lanesCache.remove(cleanContractId);
    _physfinCache.remove(cleanContractId);
    _geometryCache.remove(cleanContractId);
  }

  void clearExecCache(String contractId) {
    final cleanContractId = contractId.trim();

    _execCache.removeWhere((key, _) => key.startsWith('$cleanContractId|'));
  }

  void clearAllCache() {
    _execCache.clear();
    _servicesCache.clear();
    _totalsCache.clear();
    _lanesCache.clear();
    _physfinCache.clear();
    _geometryCache.clear();
  }

  String _cleanServiceKey(String value) {
    return value.trim();
  }

  String _safeStorageKey(String value) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError('serviceKey é obrigatório.');
    }

    final safe = clean
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (safe.isEmpty) {
      throw ArgumentError('serviceKey inválido.');
    }

    return safe;
  }

  DocumentReference<Map<String, dynamic>> _contractRef(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório.');
    }

    return _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('contracts')
        .doc(cleanContractId);
  }

  DocumentReference<Map<String, dynamic>> _scheduleConfigDoc(
      String contractId,
      ) {
    return _contractRef(contractId).collection('schedule').doc('config');
  }

  DocumentReference<Map<String, dynamic>> _scheduleCellsDoc(
      String contractId,
      ) {
    return _contractRef(contractId).collection('schedule').doc('cells');
  }

  CollectionReference<Map<String, dynamic>> _scheduleCellsItemsCol(
      String contractId,
      ) {
    return _scheduleCellsDoc(contractId).collection('items');
  }

  DocumentReference<Map<String, dynamic>> _physFinDoc(String contractId) {
    return _contractRef(contractId).collection('schedule').doc('physfin_grid');
  }

  DocumentReference<Map<String, dynamic>> _projectMainRef(String contractId) {
    return _contractRef(contractId)
        .collection('hiring')
        .doc('main')
        .collection('project')
        .doc('main');
  }

  Reference _photosFolderRef({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) {
    return _storage.ref(
      'tenants/$tenantId/contracts/$contractId/schedule/cells/${_safeStorageKey(serviceKey)}/${estaca}_$faixaIndex',
    );
  }

  String _sanitizeName(String name) {
    final clean = name.trim();

    if (clean.isEmpty) {
      return 'foto.jpg';
    }

    return clean.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _guessContentType(String name, [String fallback = 'image/jpeg']) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    return fallback;
  }

  String _guessContentTypeFromBytes(
      Uint8List bytes,
      String name, [
        String fallback = 'image/jpeg',
      ]) {
    final fmt = PhotoUtils.sniffFormat(bytes);

    switch (fmt) {
      case ImgFmt.jpeg:
        return 'image/jpeg';
      case ImgFmt.png:
        return 'image/png';
      case ImgFmt.webp:
        return 'image/webp';
      case ImgFmt.gif:
        return 'image/gif';
      case ImgFmt.bmp:
        return 'image/bmp';
      case ImgFmt.heic:
        return 'image/heic';
      case ImgFmt.unknown:
        return _guessContentType(name, fallback);
    }
  }

  String _cellDocId({
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) {
    return '${_safeStorageKey(serviceKey)}_${faixaIndex}_$estaca';
  }

  Map<String, dynamic> _photoMetaMap({
    required PhotoData photo,
    required String url,
    required String storedName,
    String? thumbUrl,
    int? width,
    int? height,
    int? sizeBytes,
    int? thumbSizeBytes,
    DateTime? fallbackTakenAt,
    int? fallbackUploadedAtMs,
    String? fallbackUploadedBy,
  }) {
    final taken = photo.takenAt ?? fallbackTakenAt;
    final uploadedAtMs = photo.uploadedAtMs ?? fallbackUploadedAtMs;
    final uploadedBy = photo.uploadedBy ?? fallbackUploadedBy;

    return <String, dynamic>{
      'id': photo.id,
      'url': url,
      if (thumbUrl != null && thumbUrl.trim().isNotEmpty)
        'thumbUrl': thumbUrl.trim(),
      'name': photo.name.trim().isNotEmpty ? photo.name.trim() : storedName,
      if (taken != null) 'takenAt': taken.millisecondsSinceEpoch,
      if (taken != null) 'takenAtMs': taken.millisecondsSinceEpoch,
      if (photo.lat != null) 'lat': photo.lat,
      if (photo.lng != null) 'lng': photo.lng,
      if (photo.address != null && photo.address!.trim().isNotEmpty)
        'address': photo.address!.trim(),
      if (photo.city != null && photo.city!.trim().isNotEmpty)
        'city': photo.city!.trim(),
      if (photo.state != null && photo.state!.trim().isNotEmpty)
        'state': photo.state!.trim(),
      if (photo.make != null && photo.make!.trim().isNotEmpty)
        'make': photo.make!.trim(),
      if (photo.model != null && photo.model!.trim().isNotEmpty)
        'model': photo.model!.trim(),
      if (photo.orientation != null) 'orientation': photo.orientation,
      'width': ?width,
      'height': ?height,
      'sizeBytes': ?sizeBytes,
      'thumbSizeBytes': ?thumbSizeBytes,
      'stamped': photo.stamped,
      'uploadedAtMs': ?uploadedAtMs,
      if (uploadedBy != null && uploadedBy.trim().isNotEmpty)
        'uploadedBy': uploadedBy.trim(),
    };
  }

  List<Map<String, dynamic>> _readPhotoMetasFromData(
      Map<String, dynamic> data,
      ) {
    final rawMetaList = data['fotosMeta'] is List
        ? data['fotosMeta'] as List
        : const <dynamic>[];

    return rawMetaList
        .whereType<Object>()
        .map((item) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      return <String, dynamic>{};
    })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _readPhotoUrlsFromData(Map<String, dynamic> data) {
    final raw = data['fotos'];

    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _deleteStorageUrlQuietly(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) return;

    try {
      await _storage.refFromURL(cleanUrl).delete();
    } catch (_) {}
  }

  Future<void> _deletePhotoUrlsAndThumbsFromData(
      Map<String, dynamic> data,
      ) async {
    final urls = _readPhotoUrlsFromData(data);
    final metas = _readPhotoMetasFromData(data);

    final thumbUrls = metas
        .map((meta) => meta['thumbUrl']?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    await Future.wait(
      <String>{...urls, ...thumbUrls}.map(_deleteStorageUrlQuietly),
    );
  }

  Future<void> saveScheduleConfiguration({
    required String contractId,
    required List<ScheduleLinearLaneData> lanes,
    required List<ScheduleLinearServicesData> services,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório para salvar configuração.');
    }

    final cleanServices = _prepareServices(services);

    final cleanLanes = _prepareLanes(
      lanes: lanes,
      services: cleanServices,
    );

    await _scheduleConfigDoc(cleanContractId).set({
      'tenantId': tenantId,
      'contractId': cleanContractId,
      'services': cleanServices
          .map((service) => service.toMap())
          .toList(growable: false),
      'lanes': cleanLanes.map((lane) => lane.toMap()).toList(growable: false),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      'version': 7,
    }, SetOptions(merge: true));

    clearContractCache(cleanContractId);
  }

  List<ScheduleLinearServicesData> _prepareServices(
      List<ScheduleLinearServicesData> services,
      ) {
    final seen = <String>{};
    final out = <ScheduleLinearServicesData>[];

    for (final service in services) {
      final key = _cleanServiceKey(service.key);

      if (key.isEmpty || seen.contains(key)) continue;

      seen.add(key);

      final isGeral = key == ScheduleLinearServicesData.geralKey;
      final label = service.label.trim().isEmpty ? key : service.label.trim();

      out.add(
        ScheduleLinearServicesData.create(
          key: key,
          label: isGeral ? 'GERAL' : label,
          iconKey: isGeral
              ? ScheduleLinearServicesData.geralIconKey
              : service.iconKey,
          icon: isGeral ? Icons.clear_all : service.icon,
          color: isGeral ? Colors.grey : service.color,
          layerOrder: isGeral
              ? ScheduleLinearServicesData.geralLayerOrder
              : service.layerOrder,
        ),
      );
    }

    if (!seen.contains(ScheduleLinearServicesData.geralKey)) {
      out.insert(0, ScheduleLinearServicesData.emptyGeral);
    }

    out.sort((a, b) {
      if (a.key == ScheduleLinearServicesData.geralKey) return -1;
      if (b.key == ScheduleLinearServicesData.geralKey) return 1;

      final byLayer = a.layerOrder.compareTo(b.layerOrder);
      if (byLayer != 0) return byLayer;

      return a.label.compareTo(b.label);
    });

    return List<ScheduleLinearServicesData>.unmodifiable(out);
  }

  List<ScheduleLinearLaneData> _prepareLanes({
    required List<ScheduleLinearLaneData> lanes,
    required List<ScheduleLinearServicesData> services,
  }) {
    if (lanes.isEmpty) {
      return const <ScheduleLinearLaneData>[];
    }

    final specificServiceKeys = services
        .where((service) => !service.isGeral)
        .map((service) => service.key)
        .toSet();

    return List<ScheduleLinearLaneData>.generate(
      lanes.length,
          (index) {
        final lane = lanes[index];

        final allowedByService = <String, bool>{
          for (final key in specificServiceKeys)
            key: lane.allowedByService[key] ?? true,
        };

        return ScheduleLinearLaneData.create(
          faixaIndex: index,
          pos: lane.resolvedPos,
          nome: lane.resolvedNome,
          altura: lane.resolvedAltura,
          anchor: lane.anchor,
          allowedByService: allowedByService,
          color: lane.color,
          iconKey: lane.iconKey,
          icon: lane.icon,
        );
      },
      growable: false,
    );
  }

  Future<void> saveFaixas(
      String contractId,
      List<ScheduleLinearLaneData> rows,
      ) async {
    final services = await loadAvailableServicesFromBudget(contractId);

    await saveScheduleConfiguration(
      contractId: contractId,
      lanes: rows,
      services: services,
    );
  }

  Future<void> ensureDefaultLaneIfMissing(String contractId) async {
    return;
  }

  Future<List<ScheduleLinearServicesData>> loadAvailableServicesFromBudget(
      String contractId,
      ) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return const <ScheduleLinearServicesData>[
        ScheduleLinearServicesData.emptyGeral,
      ];
    }

    final cached = _servicesCache[cleanContractId];
    if (cached != null) return cached;

    final doc = await _scheduleConfigDoc(cleanContractId).get();

    if (!doc.exists) {
      final defaults = List<ScheduleLinearServicesData>.unmodifiable(
        const <ScheduleLinearServicesData>[
          ScheduleLinearServicesData.emptyGeral,
        ],
      );

      _servicesCache[cleanContractId] = defaults;
      return defaults;
    }

    final data = doc.data() ?? const <String, dynamic>{};
    final rawServices = data['services'];

    final services = <ScheduleLinearServicesData>[];

    if (rawServices is List) {
      for (final item in rawServices) {
        if (item is! Map) continue;

        services.add(
          ScheduleLinearServicesData.fromMap(
            Map<String, dynamic>.from(item),
          ),
        );
      }
    }

    final prepared = _prepareServices(services);
    final frozen = List<ScheduleLinearServicesData>.unmodifiable(prepared);

    _servicesCache[cleanContractId] = frozen;

    return frozen;
  }

  Future<List<ScheduleLinearLaneData>> loadFaixas(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return const <ScheduleLinearLaneData>[];
    }

    final cached = _lanesCache[cleanContractId];
    if (cached != null) return cached;

    final doc = await _scheduleConfigDoc(cleanContractId).get();

    if (!doc.exists) {
      return const <ScheduleLinearLaneData>[];
    }

    final data = doc.data() ?? const <String, dynamic>{};
    final rawLanes = data['lanes'];

    if (rawLanes is! List || rawLanes.isEmpty) {
      return const <ScheduleLinearLaneData>[];
    }

    final rows = <ScheduleLinearLaneData>[];

    for (int i = 0; i < rawLanes.length; i++) {
      final item = rawLanes[i];

      if (item is! Map) continue;

      final lane = ScheduleLinearLaneData.fromMap(
        Map<String, dynamic>.from(item),
      );

      rows.add(
        lane.copyWith(
          faixaIndex: lane.faixaIndex < 0 ? i : lane.faixaIndex,
        ),
      );
    }

    rows.sort((a, b) => a.faixaIndex.compareTo(b.faixaIndex));

    final prepared = List<ScheduleLinearLaneData>.generate(
      rows.length,
          (index) {
        final row = rows[index];
        return row.copyWith(faixaIndex: index);
      },
      growable: false,
    );

    final frozen = List<ScheduleLinearLaneData>.unmodifiable(prepared);
    _lanesCache[cleanContractId] = frozen;

    return frozen;
  }

  Future<Map<String, double>> fetchBudgetServiceTotals(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return const <String, double>{};
    }

    final cached = _totalsCache[cleanContractId];
    if (cached != null) return cached;

    final services = await loadAvailableServicesFromBudget(cleanContractId);
    final orderedServices =
    ScheduleLinearServicesData.specificSortedByLayer(services);

    final totals = <String, double>{
      for (final service in orderedServices) service.key: 0.0,
    };

    final frozen = Map<String, double>.unmodifiable(totals);
    _totalsCache[cleanContractId] = frozen;

    return frozen;
  }

  Future<List<ScheduleLinearCellData>> fetchExecucoes({
    required String contractId,
    required String selectedServiceKey,
    required List<String> serviceKeysForGeral,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanSelectedKey = _cleanServiceKey(selectedServiceKey);

    if (cleanContractId.isEmpty) {
      return const <ScheduleLinearCellData>[];
    }

    final cleanGeralKeys = serviceKeysForGeral
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);

    final cacheKey = cleanSelectedKey == ScheduleLinearServicesData.geralKey
        ? '$cleanContractId|$cleanSelectedKey|${cleanGeralKeys.join(",")}'
        : '$cleanContractId|$cleanSelectedKey';

    final cached = _execCache[cacheKey];
    if (cached != null) return cached;

    Query<Map<String, dynamic>> query = _scheduleCellsItemsCol(cleanContractId);

    if (cleanSelectedKey != ScheduleLinearServicesData.geralKey) {
      query = query.where('serviceKey', isEqualTo: cleanSelectedKey);
    }

    final snap = await query.get();

    final map = <String, ScheduleLinearCellData>{};

    for (final doc in snap.docs) {
      final cell = ScheduleLinearCellData.fromMap(doc.data());

      final serviceKey = cell.serviceKey.trim();

      if (serviceKey.isEmpty) continue;

      if (cleanSelectedKey == ScheduleLinearServicesData.geralKey) {
        if (serviceKey == ScheduleLinearServicesData.geralKey) continue;

        if (cleanGeralKeys.isNotEmpty && !cleanGeralKeys.contains(serviceKey)) {
          continue;
        }
      }

      final key = cell.cellKey;
      final current = map[key];

      final itemTime = cell.updatedAt ?? cell.createdAt;
      final currentTime = current?.updatedAt ?? current?.createdAt;

      if (current == null ||
          (itemTime != null &&
              (currentTime == null || itemTime.isAfter(currentTime)))) {
        map[key] = cell;
      }
    }

    final list = List<ScheduleLinearCellData>.unmodifiable(map.values);
    _execCache[cacheKey] = list;

    return list;
  }

  Future<List<String>> applySquareChanges({
    required String contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required ScheduleLinearCellStatus status,
    String? comentario,
    DateTime? takenAtForNew,
    required List<String> finalPhotoUrls,
    required List<PhotoData> newPhotos,
    required String currentUserId,
    bool clearCacheAfter = true,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanServiceKey = _cleanServiceKey(serviceKey);

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório.');
    }

    if (cleanServiceKey.isEmpty) {
      throw ArgumentError('serviceKey é obrigatório.');
    }

    if (cleanServiceKey == ScheduleLinearServicesData.geralKey) {
      throw Exception(
        'A visão GERAL é apenas consolidada. Selecione um serviço específico para editar.',
      );
    }

    final services = await loadAvailableServicesFromBudget(cleanContractId);
    final serviceExists = services.any((service) {
      return service.key == cleanServiceKey;
    });

    if (!serviceExists) {
      throw Exception(
        'Serviço "$cleanServiceKey" não foi configurado para este cronograma.',
      );
    }

    final lanes = await loadFaixas(cleanContractId);

    if (lanes.isEmpty) {
      throw Exception(
        'Nenhuma faixa configurada. Configure as faixas antes de lançar execuções.',
      );
    }

    if (faixaIndex < 0 || faixaIndex >= lanes.length) {
      throw Exception('Faixa inválida.');
    }

    if (!lanes[faixaIndex].isAllowed(cleanServiceKey)) {
      throw Exception(
        'Serviço "$cleanServiceKey" não é aplicável na faixa ${lanes[faixaIndex].laneLabel}.',
      );
    }

    final cellId = _cellDocId(
      serviceKey: cleanServiceKey,
      estaca: estaca,
      faixaIndex: faixaIndex,
    );

    final docRef = _scheduleCellsItemsCol(cleanContractId).doc(cellId);
    final snap = await docRef.get();

    final directUrlPhotos = <PhotoData>[];
    final uploadPhotos = <PhotoData>[];

    for (final photo in newPhotos) {
      final hasBytes = photo.bytes != null && photo.bytes!.isNotEmpty;
      final hasUrl = photo.url != null && photo.url!.trim().isNotEmpty;

      if (hasBytes) {
        uploadPhotos.add(photo);
        continue;
      }

      if (hasUrl) {
        directUrlPhotos.add(photo);
        continue;
      }

      debugPrint(
        '[ScheduleLinearRepository] Foto ignorada: sem bytes e sem URL. '
            'id=${photo.id}, name=${photo.name}',
      );
    }

    final hasComment = comentario?.trim().isNotEmpty ?? false;

    final hasPhotos = finalPhotoUrls.any((url) => url.trim().isNotEmpty) ||
        uploadPhotos.isNotEmpty ||
        directUrlPhotos.isNotEmpty;

    final takenMs = takenAtForNew?.millisecondsSinceEpoch;

    final effectiveStatus =
    status == ScheduleLinearCellStatus.aIniciar && (hasComment || hasPhotos)
        ? ScheduleLinearCellStatus.emAndamento
        : status;

    if (effectiveStatus == ScheduleLinearCellStatus.aIniciar) {
      if (snap.exists) {
        final data = snap.data() ?? const <String, dynamic>{};

        await _deletePhotoUrlsAndThumbsFromData(data);
        await docRef.delete();
      }

      if (clearCacheAfter) {
        clearExecCache(cleanContractId);
      }

      return const <String>[];
    }

    final base = <String, dynamic>{
      'tenantId': tenantId,
      'contractId': cleanContractId,
      'serviceKey': cleanServiceKey,
      'numero': estaca,
      'faixaIndex': faixaIndex,
      'status': effectiveStatus.key,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
      'takenAtMs': ?takenMs,
      if (takenMs == null) 'takenAtMs': FieldValue.delete(),
      if (hasComment) 'comentario': comentario!.trim(),
      if (!hasComment) 'comentario': FieldValue.delete(),
    };

    if (snap.exists) {
      await docRef.set(base, SetOptions(merge: true));
    } else {
      await docRef.set({
        ...base,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
      }, SetOptions(merge: true));
    }

    final uploadedUrls = <String>[];
    final uploadedMetas = <Map<String, dynamic>>[];

    if (uploadPhotos.isNotEmpty) {
      final folder = _photosFolderRef(
        contractId: cleanContractId,
        serviceKey: cleanServiceKey,
        estaca: estaca,
        faixaIndex: faixaIndex,
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < uploadPhotos.length; i++) {
        final photo = uploadPhotos[i];

        final photoBytes = photo.bytes;

        if (photoBytes == null || photoBytes.isEmpty) {
          debugPrint(
            '[ScheduleLinearRepository] Upload ignorado: bytes vazios. '
                'id=${photo.id}, name=${photo.name}',
          );
          continue;
        }

        final suggested = photo.name.trim().isNotEmpty
            ? _sanitizeName(photo.name.trim())
            : 'img_${nowMs}_$i.jpg';

        final safeSuggested = PhotoUtils.ensureJpgExtension(suggested);
        final unique = '${DateTime.now().microsecondsSinceEpoch}_$safeSuggested';

        final mainBytes = await PhotoUtils.resizeForUpload(
          photoBytes,
          maxSide: 1600,
          quality: 82,
        );

        final thumbBytes = await PhotoUtils.buildThumbnail(
          mainBytes,
          maxSide: 360,
          quality: 68,
        );

        final mainSize = await PhotoUtils.readImageSize(mainBytes);

        final contentType = _guessContentTypeFromBytes(mainBytes, safeSuggested);
        final thumbContentType =
        _guessContentTypeFromBytes(thumbBytes, safeSuggested);

        final ref = folder.child(unique);
        final thumbRef = folder.child('thumbs/thumb_$unique');

        final task = await ref.putData(
          mainBytes,
          SettableMetadata(
            contentType: contentType,
            customMetadata: {
              'tenantId': tenantId,
              'contractId': cleanContractId,
              'serviceKey': cleanServiceKey,
              'estaca': estaca.toString(),
              'faixaIndex': faixaIndex.toString(),
              'photoId': photo.id,
              'kind': 'main',
              'stamped': photo.stamped.toString(),
              'uploadedBy': photo.uploadedBy ?? currentUserId,
            },
          ),
        );

        final thumbTask = await thumbRef.putData(
          thumbBytes,
          SettableMetadata(
            contentType: thumbContentType,
            customMetadata: {
              'tenantId': tenantId,
              'contractId': cleanContractId,
              'serviceKey': cleanServiceKey,
              'estaca': estaca.toString(),
              'faixaIndex': faixaIndex.toString(),
              'photoId': photo.id,
              'kind': 'thumb',
              'stamped': photo.stamped.toString(),
              'uploadedBy': photo.uploadedBy ?? currentUserId,
            },
          ),
        );

        final url = await task.ref.getDownloadURL();
        final thumbUrl = await thumbTask.ref.getDownloadURL();

        uploadedUrls.add(url);

        uploadedMetas.add(
          _photoMetaMap(
            photo: photo,
            url: url,
            thumbUrl: thumbUrl,
            storedName: unique,
            width: photo.width ?? mainSize?.width,
            height: photo.height ?? mainSize?.height,
            sizeBytes: mainBytes.length,
            thumbSizeBytes: thumbBytes.length,
            fallbackTakenAt: takenAtForNew,
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
      return _photoMetaMap(
        photo: photo,
        url: photo.url!.trim(),
        thumbUrl: photo.thumbUrl,
        storedName: photo.name,
        width: photo.width,
        height: photo.height,
        sizeBytes: photo.sizeBytes,
        thumbSizeBytes: photo.thumbSizeBytes,
        fallbackTakenAt: takenAtForNew,
        fallbackUploadedAtMs: photo.uploadedAtMs,
        fallbackUploadedBy: photo.uploadedBy ?? currentUserId,
      );
    }).toList(growable: false);

    final currentSnap = await docRef.get();
    final currentData = currentSnap.data() ?? const <String, dynamic>{};

    final currentUrls = _readPhotoUrlsFromData(currentData);
    final oldMetas = _readPhotoMetasFromData(currentData);

    final orderedUrls = <String>[
      ...finalPhotoUrls.where((url) => url.trim().isNotEmpty),
      ...directUrls,
      ...uploadedUrls,
    ];

    final normalizedOrderedUrls = orderedUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final removed = currentUrls
        .where((url) => !normalizedOrderedUrls.contains(url))
        .toList(growable: false);

    final thumbUrlsToRemove = <String>[];

    for (final meta in oldMetas) {
      final url = meta['url']?.toString().trim() ?? '';
      final thumbUrl = meta['thumbUrl']?.toString().trim() ?? '';

      if (url.isNotEmpty && removed.contains(url) && thumbUrl.isNotEmpty) {
        thumbUrlsToRemove.add(thumbUrl);
      }
    }

    await Future.wait(
      <String>{...removed, ...thumbUrlsToRemove}.map(_deleteStorageUrlQuietly),
    );

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

    final orderedMetas = normalizedOrderedUrls.map((url) {
      final meta = byUrl[url];

      if (meta != null) {
        return Map<String, dynamic>.from(meta);
      }

      return <String, dynamic>{
        'url': url,
        'name': url.split('/').last,
      };
    }).toList(growable: false);

    debugPrint(
      '[ScheduleLinearRepository] Salvando fotos da célula: '
          'contractId=$cleanContractId, '
          'serviceKey=$cleanServiceKey, '
          'estaca=$estaca, '
          'faixaIndex=$faixaIndex, '
          'uploaded=${uploadedUrls.length}, '
          'direct=${directUrls.length}, '
          'final=${normalizedOrderedUrls.length}',
    );

    await docRef.set({
      if (normalizedOrderedUrls.isEmpty) 'fotos': FieldValue.delete(),
      if (normalizedOrderedUrls.isNotEmpty) 'fotos': normalizedOrderedUrls,
      if (orderedMetas.isEmpty) 'fotosMeta': FieldValue.delete(),
      if (orderedMetas.isNotEmpty) 'fotosMeta': orderedMetas,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
      'takenAtMs': ?takenMs,
      if (takenMs == null) 'takenAtMs': FieldValue.delete(),
    }, SetOptions(merge: true));

    if (clearCacheAfter) {
      clearExecCache(cleanContractId);
    }

    return uploadedUrls;
  }

  Future<void> applySquareChangesBatchFast({
    required String contractId,
    required String serviceKey,
    required List<ScheduleLinearBulkCellTarget> targets,
    required ScheduleLinearCellStatus status,
    String? comentario,
    DateTime? takenAtForNew,
    required String currentUserId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanServiceKey = _cleanServiceKey(serviceKey);

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório.');
    }

    if (cleanServiceKey.isEmpty) {
      throw ArgumentError('serviceKey é obrigatório.');
    }

    if (cleanServiceKey == ScheduleLinearServicesData.geralKey) {
      throw Exception(
        'A visão GERAL é apenas consolidada. Selecione um serviço específico para editar.',
      );
    }

    if (targets.isEmpty) {
      throw Exception('Nenhuma célula selecionada para salvar.');
    }

    final services = await loadAvailableServicesFromBudget(cleanContractId);
    final serviceExists = services.any((service) {
      return service.key == cleanServiceKey;
    });

    if (!serviceExists) {
      throw Exception(
        'Serviço "$cleanServiceKey" não foi configurado para este cronograma.',
      );
    }

    final lanes = await loadFaixas(cleanContractId);

    if (lanes.isEmpty) {
      throw Exception(
        'Nenhuma faixa configurada. Configure as faixas antes de lançar execuções.',
      );
    }

    final uniqueTargets = <String, ScheduleLinearBulkCellTarget>{};

    for (final target in targets) {
      if (target.estaca <= 0) {
        throw Exception('Estaca inválida: ${target.estaca}.');
      }

      if (target.faixaIndex < 0 || target.faixaIndex >= lanes.length) {
        throw Exception('Faixa inválida.');
      }

      final lane = lanes[target.faixaIndex];

      if (!lane.isAllowed(cleanServiceKey)) {
        throw Exception(
          'Serviço "$cleanServiceKey" não é aplicável na faixa ${lane.laneLabel}.',
        );
      }

      final key = '${target.estaca}_${target.faixaIndex}';
      uniqueTargets[key] = target;
    }

    final normalizedTargets = uniqueTargets.values.toList(growable: false);

    final hasComment = comentario?.trim().isNotEmpty ?? false;
    final cleanComment = hasComment ? comentario!.trim() : null;
    final takenMs = takenAtForNew?.millisecondsSinceEpoch;

    final effectiveStatus =
    status == ScheduleLinearCellStatus.aIniciar && hasComment
        ? ScheduleLinearCellStatus.emAndamento
        : status;

    const int chunkSize = 450;

    for (int start = 0; start < normalizedTargets.length; start += chunkSize) {
      final end = math.min(start + chunkSize, normalizedTargets.length);
      final chunk = normalizedTargets.sublist(start, end);

      final refs = chunk.map((target) {
        final cellId = _cellDocId(
          serviceKey: cleanServiceKey,
          estaca: target.estaca,
          faixaIndex: target.faixaIndex,
        );

        return _scheduleCellsItemsCol(cleanContractId).doc(cellId);
      }).toList(growable: false);

      final snaps = await Future.wait(
        refs.map((ref) => ref.get()),
      );

      final batch = _firestore.batch();
      final urlsToDelete = <String>{};

      for (int i = 0; i < chunk.length; i++) {
        final target = chunk[i];
        final ref = refs[i];
        final snap = snaps[i];

        if (effectiveStatus == ScheduleLinearCellStatus.aIniciar) {
          if (snap.exists) {
            final data = snap.data() ?? const <String, dynamic>{};

            final urls = _readPhotoUrlsFromData(data);
            final metas = _readPhotoMetasFromData(data);

            urlsToDelete.addAll(urls);

            for (final meta in metas) {
              final thumbUrl = meta['thumbUrl']?.toString().trim() ?? '';

              if (thumbUrl.isNotEmpty) {
                urlsToDelete.add(thumbUrl);
              }
            }

            batch.delete(ref);
          }

          continue;
        }

        final data = <String, dynamic>{
          'tenantId': tenantId,
          'contractId': cleanContractId,
          'serviceKey': cleanServiceKey,
          'numero': target.estaca,
          'faixaIndex': target.faixaIndex,
          'status': effectiveStatus.key,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': currentUserId,
          'takenAtMs': ?takenMs,
          if (takenMs == null) 'takenAtMs': FieldValue.delete(),
          'comentario': ?cleanComment,
          if (cleanComment == null) 'comentario': FieldValue.delete(),
        };

        if (!snap.exists) {
          data['createdAt'] = FieldValue.serverTimestamp();
          data['createdBy'] = currentUserId;
        }

        batch.set(
          ref,
          data,
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (urlsToDelete.isNotEmpty) {
        await Future.wait(urlsToDelete.map(_deleteStorageUrlQuietly));
      }
    }

    clearExecCache(cleanContractId);
  }

  Future<({List<int> periods, Map<String, List<double>> grid})> loadPhysFinGrid(
      String contractId,
      ) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return (periods: const <int>[], grid: const <String, List<double>>{});
    }

    final cached = _physfinCache[cleanContractId];
    if (cached != null) return cached;

    final doc = await _physFinDoc(cleanContractId).get();

    if (!doc.exists) {
      const empty = (periods: <int>[], grid: <String, List<double>>{});
      _physfinCache[cleanContractId] = empty;

      return empty;
    }

    final data = doc.data() ?? const <String, dynamic>{};

    final periods = ((data['periods'] as List?) ?? const [])
        .whereType<Object>()
        .map((item) {
      if (item is int) return item;
      if (item is num) return item.toInt();

      return int.tryParse(item.toString()) ?? 0;
    }).toList(growable: false);

    final rawGrid = (data['grid'] as Map?) ?? const <String, dynamic>{};
    final grid = <String, List<double>>{};

    for (final entry in rawGrid.entries) {
      final key = entry.key.toString().trim();

      if (key.isEmpty || key == ScheduleLinearServicesData.geralKey) continue;

      final list = (entry.value as List?) ?? const [];

      final values = list.whereType<Object>().map((value) {
        if (value is double) return value;
        if (value is num) return value.toDouble();

        return double.tryParse(value.toString()) ?? 0.0;
      }).toList(growable: false);

      grid[key] = values;
    }

    final frozen = (
    periods: List<int>.unmodifiable(periods),
    grid: Map<String, List<double>>.unmodifiable({
      for (final entry in grid.entries)
        entry.key: List<double>.unmodifiable(entry.value),
    }),
    );

    _physfinCache[cleanContractId] = frozen;

    return frozen;
  }

  Future<void> savePhysFinGrid({
    required String contractId,
    required List<int> periods,
    required Map<String, List<double>> grid,
    String? updatedBy,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError(
        'contractId é obrigatório para salvar físico-financeiro.',
      );
    }

    final nCols = periods.length;
    final normGrid = <String, List<double>>{};

    grid.forEach((key, row) {
      final cleanKey = key.trim();

      if (cleanKey.isEmpty || cleanKey == ScheduleLinearServicesData.geralKey) {
        return;
      }

      final values = List<double>.from(
        row.map((value) => value.toDouble()),
        growable: false,
      );

      if (values.length > nCols) {
        normGrid[cleanKey] = values.sublist(0, nCols);
      } else if (values.length < nCols) {
        normGrid[cleanKey] = <double>[
          ...values,
          ...List<double>.filled(nCols - values.length, 0.0),
        ];
      } else {
        normGrid[cleanKey] = values;
      }
    });

    await _physFinDoc(cleanContractId).set({
      'tenantId': tenantId,
      'contractId': cleanContractId,
      'periods': periods,
      'grid': normGrid,
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedBy != null && updatedBy.isNotEmpty) 'updatedBy': updatedBy,
      'version': 2,
    }, SetOptions(merge: true));

    _physfinCache.remove(cleanContractId);
  }

  Future<ScheduleLinearData?> fetchProjectGeometry(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return null;
    }

    if (_geometryCache.containsKey(cleanContractId)) {
      return _geometryCache[cleanContractId];
    }

    final docRef = _projectMainRef(cleanContractId);
    final snap = await docRef.get();

    if (!snap.exists) {
      _geometryCache[cleanContractId] = null;
      return null;
    }

    final data = snap.data() ?? const <String, dynamic>{};

    final geometryType = (data['geometryType'] ?? '').toString().trim().isEmpty
        ? null
        : data['geometryType'].toString();

    final multiLine = _parseMulti(data['multiLine']);
    final points = _parsePoints(data['points']);

    List<List<LatLng>> lines = const <List<LatLng>>[];

    if (multiLine.isNotEmpty) {
      lines = multiLine;
    } else if (points.length >= 2) {
      lines = <List<LatLng>>[points];
    }

    if (lines.isEmpty) {
      _geometryCache[cleanContractId] = null;
      return null;
    }

    final resolvedGeometryType =
        geometryType ?? (lines.length == 1 ? 'LineString' : 'MultiLineString');

    final result = ScheduleLinearData(
      contractId: cleanContractId,
      tenantId: tenantId,
      geometryType: resolvedGeometryType,
      multiLine: lines.length == 1 ? null : lines,
      points: lines.length == 1 ? lines.first : null,
    );

    _geometryCache[cleanContractId] = result;

    return result;
  }

  Future<void> deleteProjectGeometry(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório para excluir geometria.');
    }

    await _projectMainRef(cleanContractId).set({
      'geometryType': FieldValue.delete(),
      'storageMode': FieldValue.delete(),
      'totalSegments': FieldValue.delete(),
      'totalPoints': FieldValue.delete(),
      'bounds': FieldValue.delete(),
      'points': FieldValue.delete(),
      'multiLine': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
    }, SetOptions(merge: true));

    _geometryCache.remove(cleanContractId);
  }

  Future<ScheduleLinearData> upsertProjectGeometry({
    required String contractId,
    required ScheduleLinearData data,
    String? summarySubjectContract,
  }) async {
    final lines = data.getSegments();

    return _saveGeometryLines(
      contractId: contractId,
      rawLines: lines,
      summarySubjectContract: summarySubjectContract,
    );
  }

  Future<ScheduleLinearData> importGeoJson({
    required String contractId,
    required Map<String, dynamic> geojson,
    String? summarySubjectContract,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório para importar GeoJSON.');
    }

    final lines = _extractLinesFromGeoJson(geojson);

    if (lines.isEmpty) {
      throw Exception(
        'GeoJSON inválido: nenhum LineString/MultiLineString encontrado.',
      );
    }

    return _saveGeometryLines(
      contractId: cleanContractId,
      rawLines: lines,
      summarySubjectContract: summarySubjectContract,
    );
  }

  Future<ScheduleLinearData> _saveGeometryLines({
    required String contractId,
    required List<List<LatLng>> rawLines,
    String? summarySubjectContract,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório para salvar geometria.');
    }

    final lines = _prepareGeometryLines(rawLines);

    if (lines.isEmpty) {
      throw Exception(
        'Geometria inválida: nenhum segmento com pelo menos 2 pontos foi encontrado.',
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = _projectMainRef(cleanContractId);

    final totalPoints = lines.fold<int>(
      0,
          (soma, line) => soma + line.length,
    );

    final geometryType = lines.length == 1 ? 'LineString' : 'MultiLineString';
    final bounds = _boundsForLines(lines);

    final snap = await docRef.get();

    final mainData = <String, dynamic>{
      'tenantId': tenantId,
      'contractId': cleanContractId,
      if (summarySubjectContract != null &&
          summarySubjectContract.trim().isNotEmpty)
        'summarySubjectContract': summarySubjectContract.trim(),
      'geometryType': geometryType,
      'storageMode': 'inline_v1',
      'totalSegments': lines.length,
      'totalPoints': totalPoints,
      'bounds': ?bounds,
      if (bounds == null) 'bounds': FieldValue.delete(),
      if (lines.length == 1) 'points': _toPoints(lines.first),
      if (lines.length == 1) 'multiLine': FieldValue.delete(),
      if (lines.length > 1) 'multiLine': _toMultiFirestore(lines),
      if (lines.length > 1) 'points': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    if (!snap.exists) {
      mainData['createdAt'] = FieldValue.serverTimestamp();
      mainData['createdBy'] = uid;
    }

    await docRef.set(mainData, SetOptions(merge: true));

    final result = ScheduleLinearData(
      contractId: cleanContractId,
      tenantId: tenantId,
      geometryType: geometryType,
      multiLine: lines.length == 1 ? null : lines,
      points: lines.length == 1 ? lines.first : null,
    );

    _geometryCache[cleanContractId] = result;

    return result;
  }

  List<List<LatLng>> _prepareGeometryLines(List<List<LatLng>> lines) {
    final prepared = <List<LatLng>>[];

    for (final line in lines) {
      if (line.length < 2) continue;

      prepared.add(
        List<LatLng>.unmodifiable(
          List<LatLng>.from(line, growable: false),
        ),
      );
    }

    return List<List<LatLng>>.unmodifiable(prepared);
  }

  Map<String, double>? _boundsForLines(List<List<LatLng>> lines) {
    if (lines.isEmpty) return null;

    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;

    for (final line in lines) {
      for (final point in line) {
        minLat =
        minLat == null ? point.latitude : math.min(minLat, point.latitude);
        maxLat =
        maxLat == null ? point.latitude : math.max(maxLat, point.latitude);
        minLng = minLng == null
            ? point.longitude
            : math.min(minLng, point.longitude);
        maxLng = maxLng == null
            ? point.longitude
            : math.max(maxLng, point.longitude);
      }
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return null;
    }

    return <String, double>{
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  List<LatLng> _parsePoints(dynamic value) {
    if (value is! List) return const <LatLng>[];

    final out = <LatLng>[];

    for (final point in value) {
      if (point is GeoPoint) {
        out.add(LatLng(point.latitude, point.longitude));
      } else if (point is List && point.length >= 2) {
        final lon = _asDouble(point[0]);
        final lat = _asDouble(point[1]);

        if (lat != null && lon != null) {
          out.add(LatLng(lat, lon));
        }
      } else if (point is Map) {
        final rawLat = point['lat'] ?? point['latitude'];
        final rawLon = point['lng'] ?? point['longitude'] ?? point['lon'];

        final lat = _asDouble(rawLat);
        final lon = _asDouble(rawLon);

        if (lat != null && lon != null) {
          out.add(LatLng(lat, lon));
        }
      }
    }

    return out;
  }

  List<List<LatLng>> _parseMulti(dynamic geometry) {
    if (geometry is! List) return const <List<LatLng>>[];

    final out = <List<LatLng>>[];

    for (final segment in geometry) {
      if (segment is Map) {
        final points = segment['points'];
        final line = _parsePoints(points);

        if (line.length >= 2) {
          out.add(line);
        }

        continue;
      }

      if (segment is List) {
        final line = <LatLng>[];

        for (final point in segment) {
          if (point is GeoPoint) {
            line.add(LatLng(point.latitude, point.longitude));
          } else if (point is List && point.length >= 2) {
            final lon = _asDouble(point[0]);
            final lat = _asDouble(point[1]);

            if (lat != null && lon != null) {
              line.add(LatLng(lat, lon));
            }
          } else if (point is Map) {
            final rawLat = point['lat'] ?? point['latitude'];
            final rawLon = point['lng'] ?? point['longitude'] ?? point['lon'];

            final lat = _asDouble(rawLat);
            final lon = _asDouble(rawLon);

            if (lat != null && lon != null) {
              line.add(LatLng(lat, lon));
            }
          }
        }

        if (line.length >= 2) {
          out.add(line);
        }
      }
    }

    return out;
  }

  List<Map<String, dynamic>>? _toMultiFirestore(
      List<List<LatLng>>? multiLine,
      ) {
    if (multiLine == null) return null;

    final valid = multiLine.where((segment) => segment.length >= 2).toList();

    if (valid.isEmpty) return null;

    return valid
        .map(
          (segment) => <String, dynamic>{
        'points': segment
            .map(
              (point) => <String, double>{
            'latitude': point.latitude,
            'longitude': point.longitude,
          },
        )
            .toList(growable: false),
      },
    )
        .toList(growable: false);
  }

  List<Map<String, double>>? _toPoints(List<LatLng>? points) {
    if (points == null || points.length < 2) return null;

    return points
        .map(
          (point) => <String, double>{
        'latitude': point.latitude,
        'longitude': point.longitude,
      },
    )
        .toList(growable: false);
  }

  List<LatLng> _coordsToLine(dynamic coords) {
    if (coords is! List) return const <LatLng>[];

    final line = <LatLng>[];

    for (final point in coords) {
      if (point is List && point.length >= 2) {
        final lon = _asDouble(point[0]);
        final lat = _asDouble(point[1]);

        if (lat != null && lon != null) {
          line.add(LatLng(lat, lon));
        }
      }
    }

    return line;
  }

  List<List<LatLng>> _coordsToMultiLine(dynamic coords) {
    if (coords is! List) return const <List<LatLng>>[];

    final out = <List<LatLng>>[];

    for (final segment in coords) {
      final line = _coordsToLine(segment);

      if (line.length >= 2) {
        out.add(line);
      }
    }

    return out;
  }

  void _collectLinesFromGeometry(
      Map<String, dynamic>? geometry,
      List<List<LatLng>> out,
      ) {
    if (geometry == null) return;

    final type = geometry['type']?.toString();
    final coords = geometry['coordinates'];

    switch (type) {
      case 'LineString':
        final line = _coordsToLine(coords);

        if (line.length >= 2) out.add(line);
        break;

      case 'MultiLineString':
        out.addAll(_coordsToMultiLine(coords));
        break;

      case 'GeometryCollection':
        final geometries = geometry['geometries'];

        if (geometries is List) {
          for (final item in geometries) {
            if (item is Map) {
              _collectLinesFromGeometry(
                Map<String, dynamic>.from(item),
                out,
              );
            }
          }
        }
        break;
    }
  }

  List<List<LatLng>> _extractLinesFromGeoJson(Map<String, dynamic> geojson) {
    final out = <List<LatLng>>[];
    final type = geojson['type']?.toString();

    switch (type) {
      case 'LineString':
      case 'MultiLineString':
      case 'GeometryCollection':
        _collectLinesFromGeometry(geojson, out);
        break;

      case 'Feature':
        final geometry = geojson['geometry'];

        if (geometry is Map) {
          _collectLinesFromGeometry(
            Map<String, dynamic>.from(geometry),
            out,
          );
        }
        break;

      case 'FeatureCollection':
        final features = geojson['features'];

        if (features is List) {
          for (final feature in features) {
            if (feature is Map) {
              final geometry = feature['geometry'];

              if (geometry is Map) {
                _collectLinesFromGeometry(
                  Map<String, dynamic>.from(geometry),
                  out,
                );
              }
            }
          }
        }
        break;
    }

    return out.where((line) => line.length >= 2).toList(growable: false);
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.');

      if (cleaned.isEmpty) return null;

      return double.tryParse(cleaned);
    }

    return null;
  }

  String docIdFromCellData(ScheduleLinearCellData data) {
    return _cellDocId(
      serviceKey: data.serviceKey,
      estaca: data.numero,
      faixaIndex: data.faixaIndex,
    );
  }
}