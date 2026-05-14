import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class ScheduleRoadRepository {
  ScheduleRoadRepository({
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

  final Map<String, List<ScheduleRoadData>> _execCache = {};
  final Map<String, List<ScheduleRoadData>> _servicesCache = {};
  final Map<String, Map<String, double>> _totalsCache = {};
  final Map<String, List<ScheduleRoadData>> _lanesCache = {};

  final Map<String, ({List<int> periods, Map<String, List<double>> grid})>
  _physfinCache = {};

  final Map<String, ScheduleRoadData?> _geometryCache = {};

  static String _validateTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para ScheduleRoadRepository.');
    }

    return cleanTenantId;
  }

  void clearContractCache(String contractId) {
    _execCache.removeWhere((key, _) => key.startsWith('$contractId|'));
    _servicesCache.remove(contractId);
    _totalsCache.remove(contractId);
    _lanesCache.remove(contractId);
    _physfinCache.remove(contractId);
    _geometryCache.remove(contractId);
  }

  String _cleanServiceKey(String value) {
    return value.trim();
  }

  String _safeStorageKey(String value) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError('serviceKey é obrigatório.');
    }

    return clean
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _validateStatus(String value) {
    final clean = value.trim();

    if (clean == 'concluido' ||
        clean == 'em_andamento' ||
        clean == 'a_iniciar') {
      return clean;
    }

    throw ArgumentError(
      'Status inválido: "$value". Use: concluido, em_andamento ou a_iniciar.',
    );
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

  DocumentReference<Map<String, dynamic>> _scheduleLanesDoc(String contractId) {
    return _contractRef(contractId).collection('schedule').doc('lanes');
  }

  DocumentReference<Map<String, dynamic>> _scheduleCellsDoc(String contractId) {
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
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _guessContentType(String name, [String fallback = 'image/jpeg']) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.heic')) return 'image/heic';

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    return fallback;
  }

  String _cellDocId({
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) {
    return '${_safeStorageKey(serviceKey)}_${estaca}_$faixaIndex';
  }

  Future<void> saveScheduleConfiguration({
    required String contractId,
    required List<ScheduleRoadData> lanes,
    required List<ScheduleRoadData> services,
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

    await _scheduleLanesDoc(cleanContractId).set({
      'tenantId': tenantId,
      'contractId': cleanContractId,
      'services': cleanServices
          .map((service) => service.toServiceMap())
          .toList(growable: false),
      'lanes': cleanLanes.map((lane) => lane.toLaneMap()).toList(
        growable: false,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      'version': 3,
    }, SetOptions(merge: true));

    _servicesCache.remove(cleanContractId);
    _lanesCache.remove(cleanContractId);
    _totalsCache.remove(cleanContractId);
    _execCache.removeWhere((key, _) => key.startsWith('$cleanContractId|'));
  }

  List<ScheduleRoadData> _prepareServices(List<ScheduleRoadData> services) {
    final source = services.isEmpty
        ? const <ScheduleRoadData>[
      ScheduleRoadData.emptyGeral,
    ]
        : services;

    final seen = <String>{};
    final out = <ScheduleRoadData>[];

    for (final service in source) {
      final key = _cleanServiceKey(service.key);

      if (key.isEmpty || seen.contains(key)) continue;

      seen.add(key);

      final label = service.label.trim().isEmpty ? key : service.label.trim();
      final iconKey = service.iconKey.trim().isEmpty
          ? ScheduleRoadData.pickIconKeyForTitle(label)
          : service.iconKey.trim();

      out.add(
        ScheduleRoadData.service(
          key: key,
          label: key == 'geral' ? 'GERAL' : label,
          iconKey: key == 'geral' ? 'clear_all' : iconKey,
          icon: key == 'geral'
              ? Icons.clear_all
              : ScheduleRoadData.iconForKey(iconKey),
          color: key == 'geral' ? Colors.grey : service.color,
        ),
      );
    }

    if (!seen.contains('geral')) {
      out.insert(0, ScheduleRoadData.emptyGeral);
    }

    out.sort((a, b) {
      if (a.key == 'geral') return -1;
      if (b.key == 'geral') return 1;

      return a.label.compareTo(b.label);
    });

    return List<ScheduleRoadData>.unmodifiable(out);
  }

  List<ScheduleRoadData> _prepareLanes({
    required List<ScheduleRoadData> lanes,
    required List<ScheduleRoadData> services,
  }) {
    final specificServiceKeys = services
        .where((service) => service.key != 'geral')
        .map((service) => service.key)
        .toSet();

    final source = lanes.isEmpty
        ? <ScheduleRoadData>[
      ScheduleRoadData.lane(
        faixaIndex: 0,
        pos: 'EIXO',
        nome: 'FAIXA ÚNICA',
        altura: 20.0,
      ),
    ]
        : lanes;

    return List<ScheduleRoadData>.generate(source.length, (index) {
      final lane = source[index];

      final allowedByService = <String, bool>{
        for (final key in specificServiceKeys)
          key: lane.allowedByService[key] ?? true,
      };

      return ScheduleRoadData.lane(
        faixaIndex: index,
        pos: lane.resolvedPos,
        nome: lane.resolvedNome,
        altura: lane.resolvedAltura,
        anchor: lane.anchor,
        allowedByService: allowedByService,
      );
    }, growable: false);
  }

  Future<void> saveFaixas(
      String contractId,
      List<ScheduleRoadData> rows,
      ) async {
    final services = await loadAvailableServicesFromBudget(contractId);

    await saveScheduleConfiguration(
      contractId: contractId,
      lanes: rows,
      services: services,
    );
  }

  Future<void> ensureDefaultLaneIfMissing(String contractId) async {
    final doc = await _scheduleLanesDoc(contractId).get();

    if (doc.exists) {
      final data = doc.data() ?? const <String, dynamic>{};

      final lanes = data['lanes'];
      final services = data['services'];

      if (lanes is List &&
          lanes.isNotEmpty &&
          services is List &&
          services.isNotEmpty) {
        return;
      }
    }

    await saveScheduleConfiguration(
      contractId: contractId,
      services: const <ScheduleRoadData>[
        ScheduleRoadData.emptyGeral,
        ScheduleRoadData(
          numero: 0,
          faixaIndex: 0,
          key: 'terraplenagem',
          label: 'TERRAPLENAGEM',
          iconKey: 'terrain_outlined',
          icon: Icons.terrain_outlined,
          color: Color(0xFFE76F51),
        ),
        ScheduleRoadData(
          numero: 0,
          faixaIndex: 0,
          key: 'base',
          label: 'BASE',
          iconKey: 'layers_outlined',
          icon: Icons.layers_outlined,
          color: Color(0xFF43A047),
        ),
        ScheduleRoadData(
          numero: 0,
          faixaIndex: 0,
          key: 'asfalto',
          label: 'ASFALTO',
          iconKey: 'alt_route_outlined',
          icon: Icons.alt_route_outlined,
          color: Color(0xFF455A64),
        ),
      ],
      lanes: <ScheduleRoadData>[
        ScheduleRoadData.lane(
          faixaIndex: 0,
          pos: 'LE',
          nome: 'LADO ESQUERDO',
          altura: 20.0,
        ),
        ScheduleRoadData.lane(
          faixaIndex: 1,
          pos: 'CE',
          nome: 'EIXO',
          altura: 20.0,
        ),
        ScheduleRoadData.lane(
          faixaIndex: 2,
          pos: 'LD',
          nome: 'LADO DIREITO',
          altura: 20.0,
        ),
      ],
    );
  }

  /// Mantive o nome para não quebrar Cubit/telas existentes.
  ///
  /// Agora os serviços vêm de:
  /// /tenants/{tenantId}/contracts/{contractId}/schedule/lanes
  Future<List<ScheduleRoadData>> loadAvailableServicesFromBudget(
      String contractId,
      ) async {
    final cached = _servicesCache[contractId];

    if (cached != null) return cached;

    final doc = await _scheduleLanesDoc(contractId).get();

    if (!doc.exists) {
      final defaults = List<ScheduleRoadData>.unmodifiable(
        const <ScheduleRoadData>[
          ScheduleRoadData.emptyGeral,
        ],
      );

      _servicesCache[contractId] = defaults;

      return defaults;
    }

    final data = doc.data() ?? const <String, dynamic>{};
    final rawServices = data['services'];

    final services = <ScheduleRoadData>[];

    if (rawServices is List) {
      for (final item in rawServices) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);

        final key = _cleanServiceKey((map['key'] ?? '').toString());

        if (key.isEmpty) continue;

        final label = (map['label'] ?? key).toString().trim();
        final effectiveLabel = label.isEmpty ? key : label;

        final iconKey = _iconKeyForServiceMap(map, key, effectiveLabel);
        final color = _colorForServiceMap(map, key, effectiveLabel);

        services.add(
          ScheduleRoadData.service(
            key: key,
            label: effectiveLabel,
            iconKey: iconKey,
            icon: ScheduleRoadData.iconForKey(iconKey),
            color: color,
          ),
        );
      }
    }

    final prepared = _prepareServices(services);

    final frozen = List<ScheduleRoadData>.unmodifiable(prepared);
    _servicesCache[contractId] = frozen;

    return frozen;
  }

  String _iconKeyForServiceMap(
      Map<String, dynamic> map,
      String key,
      String label,
      ) {
    final raw = (map['iconKey'] ?? map['icon'] ?? '').toString().trim();

    if (raw.isNotEmpty) return raw;

    if (key == 'geral') return 'clear_all';

    return ScheduleRoadData.pickIconKeyForTitle(label.isEmpty ? key : label);
  }

  Color _colorForServiceMap(
      Map<String, dynamic> map,
      String key,
      String label,
      ) {
    final rawColor = map['color'];

    if (rawColor is int) return Color(rawColor);
    if (rawColor is num) return Color(rawColor.toInt());

    if (rawColor is String) {
      final asInt = int.tryParse(rawColor);

      if (asInt != null) return Color(asInt);
    }

    if (key == 'geral') return Colors.grey;

    return ScheduleRoadData.colorForService(label.isEmpty ? key : label);
  }

  Future<List<ScheduleRoadData>> loadFaixas(String contractId) async {
    final cached = _lanesCache[contractId];

    if (cached != null) return cached;

    final doc = await _scheduleLanesDoc(contractId).get();

    if (!doc.exists) {
      return const <ScheduleRoadData>[];
    }

    final data = doc.data() ?? const <String, dynamic>{};
    final rawLanes = data['lanes'];

    if (rawLanes is! List || rawLanes.isEmpty) {
      return const <ScheduleRoadData>[];
    }

    final rows = <ScheduleRoadData>[];

    for (int i = 0; i < rawLanes.length; i++) {
      final item = rawLanes[i];

      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);

      rows.add(
        ScheduleRoadData.lane(
          faixaIndex: _asInt(map['faixaIndex']) ?? i,
          pos: (map['pos'] ?? '').toString(),
          nome: (map['nome'] ?? '').toString(),
          altura: _asDouble(map['altura']) ?? 20.0,
          anchor: _asInt(map['anchor']),
          allowedByService: _asBoolMap(map['allowedByService']),
        ),
      );
    }

    rows.sort((a, b) => a.faixaIndex.compareTo(b.faixaIndex));

    final prepared = List<ScheduleRoadData>.generate(
      rows.length,
          (index) {
        final row = rows[index];

        return ScheduleRoadData.lane(
          faixaIndex: index,
          pos: row.pos ?? '',
          nome: row.nome ?? '',
          altura: row.altura ?? 20.0,
          anchor: row.anchor,
          allowedByService: row.allowedByService,
        );
      },
      growable: false,
    );

    final frozen = List<ScheduleRoadData>.unmodifiable(prepared);
    _lanesCache[contractId] = frozen;

    return frozen;
  }

  /// Mantive o nome para não quebrar Cubit/telas existentes.
  ///
  /// Como os serviços são configurados manualmente, o total por serviço fica 0.
  Future<Map<String, double>> fetchBudgetServiceTotals(String contractId) async {
    final cached = _totalsCache[contractId];

    if (cached != null) return cached;

    final services = await loadAvailableServicesFromBudget(contractId);

    final totals = <String, double>{
      for (final service in services)
        if (service.key != 'geral') service.key: 0.0,
    };

    final frozen = Map<String, double>.unmodifiable(totals);
    _totalsCache[contractId] = frozen;

    return frozen;
  }

  Future<List<ScheduleRoadData>> fetchExecucoes({
    required String contractId,
    required String selectedServiceKey,
    required List<String> serviceKeysForGeral,
    required ScheduleRoadData metaForSelected,
  }) async {
    final cleanSelectedKey = _cleanServiceKey(selectedServiceKey);

    final cacheKey = '$contractId|$cleanSelectedKey';
    final cached = _execCache[cacheKey];

    if (cached != null) return cached;

    final services = await loadAvailableServicesFromBudget(contractId);

    ScheduleRoadData metaForKey(String key) {
      return services.firstWhere(
            (service) => service.key == key,
        orElse: () => metaForSelected,
      );
    }

    Query<Map<String, dynamic>> query = _scheduleCellsItemsCol(contractId);

    if (cleanSelectedKey != 'geral') {
      query = query.where('serviceKey', isEqualTo: cleanSelectedKey);
    }

    final snap = await query.get();

    final results = <ScheduleRoadData>[];

    for (final doc in snap.docs) {
      final data = doc.data();

      final serviceKey = _cleanServiceKey(
        (data['serviceKey'] ?? '').toString(),
      );

      if (serviceKey.isEmpty) continue;

      if (cleanSelectedKey == 'geral') {
        if (serviceKey == 'geral') continue;

        if (serviceKeysForGeral.isNotEmpty &&
            !serviceKeysForGeral.contains(serviceKey)) {
          continue;
        }
      }

      final meta = metaForKey(serviceKey);

      final mapped = <String, dynamic>{
        ...data,
        'key': serviceKey,
        'label': meta.label,
        'iconKey': meta.iconKey,
        'color': meta.color.toARGB32(),
        'tipo': data['tipo'] ?? meta.label,
      };

      results.add(
        ScheduleRoadData.fromMap(
          mapped,
          meta: meta,
        ),
      );
    }

    final map = <String, ScheduleRoadData>{};

    for (final item in results) {
      final key = '${item.key}_${item.numero}_${item.faixaIndex}';
      final current = map[key];

      final itemTime = item.updatedAt ?? item.createdAt;
      final currentTime = current?.updatedAt ?? current?.createdAt;

      if (current == null ||
          (itemTime != null &&
              (currentTime == null || itemTime.isAfter(currentTime)))) {
        map[key] = item;
      }
    }

    final list = List<ScheduleRoadData>.unmodifiable(map.values);
    _execCache[cacheKey] = list;

    return list;
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
    final cleanServiceKey = _cleanServiceKey(serviceKey);

    if (cleanServiceKey.isEmpty) {
      throw ArgumentError('serviceKey é obrigatório.');
    }

    if (cleanServiceKey == 'geral') {
      return const <String>[];
    }

    final lanes = await loadFaixas(contractId);

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

    final docRef = _scheduleCellsItemsCol(contractId).doc(cellId);
    final snap = await docRef.get();

    final hasComment = comentario?.trim().isNotEmpty ?? false;
    final hasPhotos = finalPhotoUrls.isNotEmpty || newFilesBytes.isNotEmpty;

    var cleanStatus = _validateStatus(status);
    final takenMs = takenAtForNew?.millisecondsSinceEpoch;

    if (cleanStatus == 'a_iniciar' && (hasComment || hasPhotos)) {
      cleanStatus = 'em_andamento';
    }

    if (cleanStatus == 'a_iniciar') {
      if (snap.exists) {
        final data = snap.data() ?? const <String, dynamic>{};

        final urls = data['fotos'] is List
            ? List<String>.from(data['fotos'] as List)
            : const <String>[];

        for (final url in urls) {
          try {
            await _storage.refFromURL(url).delete();
          } catch (_) {}
        }

        await docRef.delete();
      }

      clearContractCache(contractId);

      return const <String>[];
    }

    final base = <String, dynamic>{
      'tenantId': tenantId,
      'contractId': contractId,
      'serviceKey': cleanServiceKey,
      'key': cleanServiceKey,
      'numero': estaca,
      'faixaIndex': faixaIndex,
      'tipo': tipoLabel,
      'status': cleanStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
      if (takenMs != null) 'takenAtMs': takenMs,
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

    if (newFilesBytes.isNotEmpty) {
      final folder = _photosFolderRef(
        contractId: contractId,
        serviceKey: cleanServiceKey,
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

        final unique = '${DateTime.now().microsecondsSinceEpoch}_$suggested';
        final contentType = _guessContentType(suggested);
        final ref = folder.child(unique);

        final task = await ref.putData(
          newFilesBytes[i],
          SettableMetadata(contentType: contentType),
        );

        final url = await task.ref.getDownloadURL();

        uploadedUrls.add(url);

        final meta = i < newPhotoMetas.length
            ? newPhotoMetas[i]
            : const pm.CarouselMetadata();

        final taken = meta.takenAt ?? takenAtForNew;

        uploadedMetas.add({
          'url': url,
          'name': meta.name ?? unique,
          if (taken != null) 'takenAt': taken.millisecondsSinceEpoch,
          if (taken != null) 'takenAtMs': taken.millisecondsSinceEpoch,
          if (meta.lat != null) 'lat': meta.lat,
          if (meta.lng != null) 'lng': meta.lng,
          if (meta.make != null) 'make': meta.make,
          if (meta.model != null) 'model': meta.model,
          if (meta.orientation != null) 'orientation': meta.orientation,
          'uploadedAtMs': meta.uploadedAtMs ?? nowMs,
          'uploadedBy': meta.uploadedBy ?? currentUserId,
        });
      }
    }

    final currentSnap = await docRef.get();
    final currentData = currentSnap.data() ?? const <String, dynamic>{};

    final currentUrls = currentData['fotos'] is List
        ? List<String>.from(currentData['fotos'] as List)
        : const <String>[];

    final removed = currentUrls
        .where(
          (url) => !finalPhotoUrls.contains(url) && !uploadedUrls.contains(url),
    )
        .toList(growable: false);

    for (final url in removed) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {}
    }

    final rawMetaList = currentData['fotosMeta'] is List
        ? currentData['fotosMeta'] as List
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
      final url = (meta['url'] as String?) ?? '';

      if (url.isNotEmpty && !removed.contains(url)) {
        byUrl[url] = meta;
      }
    }

    for (final meta in uploadedMetas) {
      final url = (meta['url'] as String?) ?? '';

      if (url.isNotEmpty) {
        byUrl[url] = meta;
      }
    }

    final orderedUrls = <String>[
      ...finalPhotoUrls.where((url) => url.trim().isNotEmpty),
      ...uploadedUrls,
    ];

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

    await docRef.set({
      if (orderedUrls.isEmpty) 'fotos': FieldValue.delete(),
      if (orderedUrls.isNotEmpty) 'fotos': orderedUrls,
      if (orderedMetas.isEmpty) 'fotosMeta': FieldValue.delete(),
      if (orderedMetas.isNotEmpty) 'fotosMeta': orderedMetas,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUserId,
      if (takenMs != null) 'takenAtMs': takenMs,
      if (takenMs == null) 'takenAtMs': FieldValue.delete(),
    }, SetOptions(merge: true));

    clearContractCache(contractId);

    return uploadedUrls;
  }

  Future<({List<int> periods, Map<String, List<double>> grid})>
  loadPhysFinGrid(String contractId) async {
    final cached = _physfinCache[contractId];

    if (cached != null) return cached;

    final doc = await _physFinDoc(contractId).get();

    if (!doc.exists) {
      const empty = (periods: <int>[], grid: <String, List<double>>{});
      _physfinCache[contractId] = empty;

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
      final key = entry.key.toString();
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

    _physfinCache[contractId] = frozen;

    return frozen;
  }

  Future<void> savePhysFinGrid({
    required String contractId,
    required List<int> periods,
    required Map<String, List<double>> grid,
    String? updatedBy,
  }) async {
    final nCols = periods.length;
    final normGrid = <String, List<double>>{};

    grid.forEach((key, row) {
      final values = List<double>.from(
        row.map((value) => value.toDouble()),
        growable: false,
      );

      if (values.length > nCols) {
        normGrid[key] = values.sublist(0, nCols);
      } else if (values.length < nCols) {
        normGrid[key] = <double>[
          ...values,
          ...List<double>.filled(nCols - values.length, 0.0),
        ];
      } else {
        normGrid[key] = values;
      }
    });

    await _physFinDoc(contractId).set({
      'tenantId': tenantId,
      'contractId': contractId,
      'periods': periods,
      'grid': normGrid,
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedBy != null && updatedBy.isNotEmpty) 'updatedBy': updatedBy,
      'version': 2,
    }, SetOptions(merge: true));

    _physfinCache.remove(contractId);
  }

  Future<ScheduleRoadData?> fetchProjectGeometry(String contractId) async {
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

    final result = ScheduleRoadData(
      numero: 0,
      faixaIndex: 0,
      key: 'geral',
      label: 'GERAL',
      iconKey: 'route_outlined',
      icon: Icons.route_outlined,
      color: Colors.grey,
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

    await _projectMainRef(cleanContractId).update({
      'geometryType': FieldValue.delete(),
      'storageMode': FieldValue.delete(),
      'totalSegments': FieldValue.delete(),
      'totalPoints': FieldValue.delete(),
      'bounds': FieldValue.delete(),
      'points': FieldValue.delete(),
      'multiLine': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
    });

    _geometryCache.remove(cleanContractId);
  }

  Future<ScheduleRoadData> upsertProjectGeometry({
    required String contractId,
    required ScheduleRoadData data,
    String? summarySubjectContract,
  }) async {
    final lines = data.getSegments();

    return _saveGeometryLines(
      contractId: contractId,
      rawLines: lines,
      summarySubjectContract: summarySubjectContract,
    );
  }

  Future<ScheduleRoadData> importGeoJson({
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

  Future<ScheduleRoadData> _saveGeometryLines({
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
      if (summarySubjectContract != null)
        'summarySubjectContract': summarySubjectContract,
      'geometryType': geometryType,
      'storageMode': 'inline_v1',
      'totalSegments': lines.length,
      'totalPoints': totalPoints,
      if (bounds != null) 'bounds': bounds,
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

    final result = ScheduleRoadData(
      numero: 0,
      faixaIndex: 0,
      key: 'geral',
      label: 'GERAL',
      iconKey: 'route_outlined',
      icon: Icons.route_outlined,
      color: Colors.grey,
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
        minLat = minLat == null
            ? point.latitude
            : math.min(minLat, point.latitude);
        maxLat = maxLat == null
            ? point.latitude
            : math.max(maxLat, point.latitude);
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

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();

    if (value is String) {
      final cleaned = value.trim();

      if (cleaned.isEmpty) return null;

      return int.tryParse(cleaned);
    }

    return null;
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

  Map<String, bool> _asBoolMap(dynamic value) {
    if (value is Map) {
      return <String, bool>{
        for (final entry in value.entries)
          entry.key.toString().trim(): entry.value == true,
      }..removeWhere((key, _) => key.isEmpty || key == 'geral');
    }

    return const <String, bool>{};
  }

  String docIdFromBoardData(ScheduleRoadData data) {
    return _cellDocId(
      serviceKey: data.key,
      estaca: data.numero,
      faixaIndex: data.faixaIndex,
    );
  }
}