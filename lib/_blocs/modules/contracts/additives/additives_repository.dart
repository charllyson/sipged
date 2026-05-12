// lib/_blocs/modules/contracts/additives/additives_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/registers/register_class.dart';

class AdditivesRepository {
  AdditivesRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    required String tenantId,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _tenantId = _cleanRequiredTenantId(tenantId);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  String _tenantId;

  final Map<String, List<AdditivesData>> _byContract =
  <String, List<AdditivesData>>{};

  final Map<String, bool> _loading = <String, bool>{};

  List<AdditivesData>? _allAdditivesCache;

  final Map<String, String> _statusByContract = <String, String>{};

  static String _cleanRequiredTenantId(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para criar AdditivesRepository.',
      );
    }

    return clean;
  }

  String get tenantId {
    final id = _tenantId.trim();

    if (id.isEmpty) {
      throw StateError(
        'tenantId não definido em AdditivesRepository. '
            'Selecione uma empresa antes de acessar aditivos.',
      );
    }

    return id;
  }

  String get currentTenantId {
    return tenantId;
  }

  bool get hasTenant {
    return tenantId.trim().isNotEmpty;
  }

  void setActiveTenantId(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório em AdditivesRepository.setActiveTenantId.',
      );
    }

    if (_tenantId == clean) return;

    _tenantId = clean;
    clearCache();
  }

  void clearCache() {
    _byContract.clear();
    _loading.clear();
    _allAdditivesCache = null;
    _statusByContract.clear();
  }

  String get tenantContractsCollectionPath {
    return 'tenants/$tenantId/contracts';
  }

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return _db.collection(tenantContractsCollectionPath);
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw ArgumentError('contractId é obrigatório.');
    }

    return _contractsCol().doc(cleanContractId);
  }

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _contractDoc(contractId).collection('additives');
  }

  DocumentReference<Map<String, dynamic>> _doc({
    required String contractId,
    required String additiveId,
  }) {
    final cleanAdditiveId = additiveId.trim();

    if (cleanAdditiveId.isEmpty) {
      throw ArgumentError('additiveId é obrigatório.');
    }

    return _col(contractId).doc(cleanAdditiveId);
  }

  String? _idToString(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  String _uid() {
    return _auth.currentUser?.uid ?? '';
  }

  void _invalidateAllAdditivesCache() {
    _allAdditivesCache = null;
  }

  List<AdditivesData> _sorted(List<AdditivesData> list) {
    final sorted = List<AdditivesData>.from(list);

    sorted.sort(
          (a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0),
    );

    return List<AdditivesData>.unmodifiable(sorted);
  }

  double _toDoubleSafe(dynamic raw) {
    if (raw == null) return 0.0;

    if (raw is num) return raw.toDouble();

    if (raw is String) {
      final normalized = raw
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();

      return double.tryParse(normalized) ?? 0.0;
    }

    return 0.0;
  }

  DateTime? _toDateSafe(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) return null;

      final iso = DateTime.tryParse(text);
      if (iso != null) return iso;

      final parts = text.split('/');

      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  String? _stringOrNull(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  bool _isTenantAdditivePath(String path) {
    final parts = path
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length < 6) return false;

    return parts[0] == 'tenants' &&
        parts[1] == tenantId &&
        parts[2] == 'contracts' &&
        parts[4] == 'additives';
  }

  Future<String?> _loadStatusContratoFromDfd(String contractId) async {
    try {
      final dfdSnap = await _contractDoc(contractId)
          .collection('dfd')
          .limit(1)
          .get();

      if (dfdSnap.docs.isEmpty) return null;

      final identSnap = await dfdSnap.docs.first.reference
          .collection('identificacao')
          .limit(1)
          .get();

      if (identSnap.docs.isEmpty) return null;

      final raw = identSnap.docs.first.data()['statusContrato'];

      if (raw == null) return null;

      final value = raw.toString().trim();

      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureStatusesForContracts(
      Iterable<ContractData> contratos,
      ) async {
    final futures = <Future<void>>[];

    for (final contract in contratos) {
      final id = _idToString(contract.id);

      if (id == null || _statusByContract.containsKey(id)) continue;

      futures.add(
            () async {
          final status = await _loadStatusContratoFromDfd(id);

          if (status != null && status.trim().isNotEmpty) {
            _statusByContract[id] = status.trim();
          }
        }(),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  String? _getDfdStatusForId(String? contractId) {
    if (contractId == null) return null;

    final value = _statusByContract[contractId];

    return value == null || value.trim().isEmpty ? null : value.trim();
  }

  Future<List<AdditivesData>> _loadAllAdditivesOnce() async {
    if (_allAdditivesCache != null) return _allAdditivesCache!;

    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await _db
          .collectionGroup('additives')
          .where('tenantId', isEqualTo: tenantId)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snap = await _db.collectionGroup('additives').get();
      } else {
        rethrow;
      }
    }

    final list = snap.docs
        .where((doc) => _isTenantAdditivePath(doc.reference.path))
        .map((doc) => AdditivesData.fromDocument(snapshot: doc))
        .toList();

    _allAdditivesCache = List<AdditivesData>.unmodifiable(_sorted(list));

    return _allAdditivesCache!;
  }

  Future<List<AdditivesData>> getAllAdditives() async {
    return _loadAllAdditivesOnce();
  }

  Future<List<AdditivesData>> getAdditivesByContractIds(
      Set<String> contractIds,
      ) async {
    if (contractIds.isEmpty) return const <AdditivesData>[];

    final all = await _loadAllAdditivesOnce();

    return all.where((additive) {
      final contractId = additive.contractId;
      return contractId != null && contractIds.contains(contractId);
    }).toList();
  }

  Future<List<AdditivesData>> getAllAdditivesOfContract({
    required String uidContract,
  }) async {
    final contractId = uidContract.trim();

    if (contractId.isEmpty) return const <AdditivesData>[];

    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await _col(contractId).orderBy('additiveorder').get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snap = await _col(contractId).get();
      } else {
        rethrow;
      }
    }

    return _sorted(
      snap.docs
          .map((doc) => AdditivesData.fromDocument(snapshot: doc))
          .toList(),
    );
  }

  Future<List<AdditivesData>> ensureForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return const <AdditivesData>[];

    if (_byContract.containsKey(cleanContractId)) {
      return _byContract[cleanContractId]!;
    }

    _loading[cleanContractId] = true;

    try {
      final list = await getAllAdditivesOfContract(
        uidContract: cleanContractId,
      );

      _byContract[cleanContractId] = _sorted(list);

      return _byContract[cleanContractId]!;
    } finally {
      _loading[cleanContractId] = false;
    }
  }

  Future<List<AdditivesData>> refreshForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return const <AdditivesData>[];

    _loading[cleanContractId] = true;

    try {
      final list = await getAllAdditivesOfContract(
        uidContract: cleanContractId,
      );

      _byContract[cleanContractId] = _sorted(list);
      _invalidateAllAdditivesCache();

      return _byContract[cleanContractId]!;
    } finally {
      _loading[cleanContractId] = false;
    }
  }

  List<AdditivesData> listCachedFor(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return const <AdditivesData>[];

    return _byContract[cleanContractId] ?? const <AdditivesData>[];
  }

  Future<double> getValorPorStatus(
      List<ContractData> contratos,
      String statusDesejado,
      ) async {
    if (contratos.isEmpty) return 0.0;

    await _ensureStatusesForContracts(contratos);

    final target = statusDesejado.trim().toUpperCase();

    final ids = <String>{
      for (final contract in contratos)
        if (_idToString(contract.id) != null)
          if ((_getDfdStatusForId(_idToString(contract.id)) ?? '')
              .toUpperCase() ==
              target)
            _idToString(contract.id)!,
    };

    if (ids.isEmpty) return 0.0;

    final values = await Future.wait(
      ids.map((contractId) async {
        try {
          final snap = await _col(contractId).get();

          return snap.docs.fold<double>(0.0, (totalAtual, doc) {
            final data = doc.data();
            final raw = data['additivevalue'] ?? data['additiveValue'];

            return totalAtual + _toDoubleSafe(raw);
          });
        } catch (_) {
          return 0.0;
        }
      }),
    );

    return values.fold<double>(0.0, (totalAtual, value) => totalAtual + value);
  }

  Future<double> somarValoresAditivosPorStatus({
    required List<ContractData> contratos,
    required String status,
  }) async {
    if (contratos.isEmpty) return 0.0;

    await _ensureStatusesForContracts(contratos);

    final target = status.trim().toUpperCase();

    final ids = <String>[
      for (final contract in contratos)
        if (_idToString(contract.id) != null)
          if ((_getDfdStatusForId(_idToString(contract.id)) ?? '')
              .toUpperCase() ==
              target)
            _idToString(contract.id)!,
    ];

    double total = 0.0;

    for (final contractId in ids) {
      final snap = await _col(contractId).get();

      for (final doc in snap.docs) {
        final additive = AdditivesData.fromDocument(snapshot: doc);
        total += additive.additiveValue ?? 0.0;
      }
    }

    return total;
  }

  Future<double> getAllAdditivesValue(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return 0.0;

    final snap = await _col(cleanContractId).get();

    return snap.docs.fold<double>(0.0, (totalAtual, doc) {
      final additive = AdditivesData.fromDocument(snapshot: doc);
      return totalAtual + (additive.additiveValue ?? 0.0);
    });
  }

  Future<void> saveOrUpdateAdditive({
    required String contractId,
    required AdditivesData data,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar aditivo.');
    }

    final firebaseUser = _auth.currentUser;

    final docRef = data.id != null && data.id!.trim().isNotEmpty
        ? _doc(
      contractId: cleanContractId,
      additiveId: data.id!.trim(),
    )
        : _col(cleanContractId).doc();

    final additiveId = docRef.id;

    data.id = additiveId;
    data.contractId = cleanContractId;

    final snapshot = await docRef.get();

    final json = data.toJson()
      ..addAll({
        'id': additiveId,
        'contractId': cleanContractId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'recordPath': docRef.path,
        'sourceCollectionModel': 'tenant_contract_additives',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      });

    final hasCreatedAt =
        snapshot.exists && snapshot.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    } else {
      json.remove('createdAt');
      json.remove('createdBy');
    }

    await docRef.set(json, SetOptions(merge: true));

    await _notificarUsuariosSobreAditivo(data, cleanContractId);

    await refreshForContract(cleanContractId);
    _invalidateAllAdditivesCache();
  }

  Future<void> deleteAdditive({
    required String contractId,
    required String additiveId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanAdditiveId = additiveId.trim();

    if (cleanContractId.isEmpty || cleanAdditiveId.isEmpty) {
      throw Exception('contractId e additiveId são obrigatórios para excluir.');
    }

    final docRef = _doc(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
    );

    final snap = await docRef.get();

    final data = snap.data();

    if (data != null) {
      final raw = data['attachments'];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final attachment = Attachment.fromMap(
              Map<String, dynamic>.from(item),
            );

            if (attachment.path.trim().isNotEmpty) {
              await deleteStorageByPath(attachment.path);
            }
          }
        }
      }
    }

    try {
      final folder = _storage.ref(
        'tenants/$tenantId/contracts/$cleanContractId/additives/$cleanAdditiveId/',
      );

      final result = await folder.listAll();

      for (final item in result.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}

    await docRef.delete();

    final current = List<AdditivesData>.from(
      _byContract[cleanContractId] ?? const <AdditivesData>[],
    )..removeWhere((item) => item.id == cleanAdditiveId);

    _byContract[cleanContractId] = _sorted(current);

    _invalidateAllAdditivesCache();
  }

  Future<void> _notificarUsuariosSobreAditivo(
      AdditivesData aditivo,
      String contractId,
      ) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null || uid.trim().isEmpty) return;

    final ref = _db.collection('users').doc(uid).collection('notifications').doc();

    await ref.set({
      'tipo': 'aditivo',
      'titulo': 'Novo aditivo nº ${aditivo.additiveOrder}',
      'tenantId': tenantId,
      'contractId': contractId,
      'additiveId': aditivo.id,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  Stream<List<Registro>> getNotificacoesRecentesStream(String uid) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Stream<List<Registro>>.value(const <Registro>[]);
    }

    return _db
        .collection('users')
        .doc(cleanUid)
        .collection('notifications')
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((snapshot) async {
      final registros = <Registro>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['tipo'] != 'aditivo') continue;

        final contractId = data['contractId']?.toString().trim();
        final additiveId = data['additiveId']?.toString().trim();

        if (contractId == null ||
            contractId.isEmpty ||
            additiveId == null ||
            additiveId.isEmpty) {
          continue;
        }

        final originalSnap = await _doc(
          contractId: contractId,
          additiveId: additiveId,
        ).get();

        if (!originalSnap.exists) continue;

        final original = AdditivesData.fromDocument(snapshot: originalSnap);

        registros.add(
          Registro(
            id: doc.id,
            tipo: 'aditivo',
            data: _toDateSafe(data['createdAt']) ?? DateTime.now(),
            original: original,
            contractData: await buscarContrato(contractId),
          ),
        );
      }

      return registros;
    });
  }

  Future<ContractData?> buscarContrato(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final snap = await _contractDoc(cleanContractId).get();

    if (!snap.exists) return null;

    return ContractData.fromDocument(snapshot: snap);
  }

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');
  }

  String _extFromName(String name) {
    final match = RegExp(
      r'\.([a-z0-9]+)$',
      caseSensitive: false,
    ).firstMatch(name.trim());

    return match == null ? '' : '.${match.group(1)!.toLowerCase()}';
  }

  String _baseName(String name) {
    var value = name.trim();

    final queryIndex = value.indexOf('?');

    if (queryIndex != -1) {
      value = value.substring(0, queryIndex);
    }

    final hashIndex = value.indexOf('#');

    if (hashIndex != -1) {
      value = value.substring(0, hashIndex);
    }

    value = value.split('/').last;

    return value.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String storedFileName(String original) {
    final base = _sanitize(_baseName(original));
    final random = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final ext = _extFromName(original);

    return '$base-$random${ext.isEmpty ? ".bin" : ext}';
  }

  String folderFor(ContractData contract, AdditivesData additive) {
    final contractId = contract.id?.trim();
    final additiveId = additive.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contract.id é obrigatório para anexos de aditivo.');
    }

    if (additiveId == null || additiveId.isEmpty) {
      throw Exception('additive.id é obrigatório para anexos de aditivo.');
    }

    return 'tenants/$tenantId/contracts/$contractId/additives/$additiveId/';
  }

  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }

    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ContractData contract,
    required AdditivesData additive,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = folderFor(contract, additive);
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir$name');

    final ext = _extFromName(originalName);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: ext == '.pdf'
            ? 'application/pdf'
            : 'application/octet-stream',
        customMetadata: {
          'tenantId': tenantId,
          'originalName': originalName,
          'label': label,
          'contractId': contract.id ?? '',
          'additiveId': additive.id ?? '',
        },
      ),
    );

    task.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        onProgress?.call(event.bytesTransferred / event.totalBytes);
      }
    });

    await task;

    final url = await ref.getDownloadURL();
    final meta = await ref.getMetadata();

    return Attachment(
      id: ref.name,
      label: label.trim().isEmpty ? _baseName(originalName) : label.trim(),
      url: url,
      path: ref.fullPath,
      ext: ext,
      size: meta.size?.toInt(),
      createdAt: DateTime.now(),
      createdBy: _auth.currentUser?.uid,
    );
  }

  Future<List<({String name, String url})>> listarArquivosDoAditivo({
    required String contractId,
    required String additiveId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanAdditiveId = additiveId.trim();

    if (cleanContractId.isEmpty || cleanAdditiveId.isEmpty) {
      return const <({String name, String url})>[];
    }

    final folderRef = _storage.ref(
      'tenants/$tenantId/contracts/$cleanContractId/additives/$cleanAdditiveId/',
    );

    final out = <({String name, String url})>[];

    try {
      final result = await folderRef.listAll();

      for (final item in result.items) {
        try {
          final url = await item.getDownloadURL();
          out.add((name: item.name, url: url));
        } catch (_) {}
      }
    } catch (_) {}

    final unique = <String, ({String name, String url})>{};

    for (final item in out) {
      unique[item.url] = item;
    }

    final list = unique.values.toList();

    list.sort((a, b) => a.name.compareTo(b.name));

    return list;
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    final cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) return;

    final expectedPrefix = 'tenants/$tenantId/';

    if (!cleanPath.startsWith(expectedPrefix)) {
      throw Exception(
        'Caminho de storage fora do tenant ativo. '
            'tenantId: $tenantId | path: $cleanPath',
      );
    }

    try {
      await _storage.ref(cleanPath).delete();
    } catch (_) {}
  }

  Future<void> setAttachments({
    required String contractId,
    required String additiveId,
    required List<Attachment> attachments,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanAdditiveId = additiveId.trim();

    if (cleanContractId.isEmpty || cleanAdditiveId.isEmpty) {
      throw Exception('contractId e additiveId são obrigatórios.');
    }

    final docRef = _doc(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
    );

    await docRef.set(
      {
        'attachments': attachments.isEmpty
            ? FieldValue.delete()
            : attachments.map((item) => item.toMap()).toList(),
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );

    final current = List<AdditivesData>.from(
      _byContract[cleanContractId] ?? const <AdditivesData>[],
    );

    final index = current.indexWhere((item) => item.id == cleanAdditiveId);

    if (index >= 0) {
      current[index] = current[index].copyWith(
        attachments: attachments,
        clearAttachments: attachments.isEmpty,
      );

      _byContract[cleanContractId] = _sorted(current);
    }

    _invalidateAllAdditivesCache();
  }

  String legacyFileName(ContractData contract, AdditivesData additive) {
    final contrato = _sanitize('contrato');
    final ordem = (additive.additiveOrder ?? 0).toString().padLeft(3, '0');
    final processo = _sanitize(additive.additiveNumberProcess ?? 'processo');

    return '$contrato-$ordem-$processo.pdf';
  }

  String legacyPathFor(ContractData contract, AdditivesData additive) {
    return '${folderFor(contract, additive)}${legacyFileName(contract, additive)}';
  }

  Future<String> uploadLegacyBytes({
    required ContractData contract,
    required AdditivesData additive,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(legacyPathFor(contract, additive));

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'tenantId': tenantId,
          'contractId': contract.id ?? '',
          'additiveId': additive.id ?? '',
        },
      ),
    );

    task.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        onProgress?.call(event.bytesTransferred / event.totalBytes);
      }
    });

    await task;

    return ref.getDownloadURL();
  }

  Future<bool> deleteLegacyPdf({
    required ContractData contract,
    required AdditivesData additive,
  }) async {
    bool deleted = false;

    try {
      await _storage.ref(legacyPathFor(contract, additive)).delete();
      deleted = true;
    } catch (_) {}

    _invalidateAllAdditivesCache();

    return deleted;
  }

  Future<bool> verificarSePdfDeAditivoExiste({
    required ContractData contract,
    required AdditivesData additive,
  }) async {
    try {
      await _storage.ref(legacyPathFor(contract, additive)).getMetadata();
      return true;
    } catch (_) {}

    return false;
  }

  Future<String?> getPdfUrlDoAditivo({
    required ContractData contract,
    required AdditivesData additive,
  }) async {
    try {
      return await _storage
          .ref(legacyPathFor(contract, additive))
          .getDownloadURL();
    } catch (_) {}

    final contractId = contract.id?.trim();
    final additiveId = additive.id?.trim();

    if (contractId == null || contractId.isEmpty) return null;
    if (additiveId == null || additiveId.isEmpty) return null;

    final snap = await _doc(
      contractId: contractId,
      additiveId: additiveId,
    ).get();

    final data = snap.data();

    return _stringOrNull(data?['pdfUrl']);
  }

  Future<void> salvarUrlPdfDoAditivo({
    required String contractId,
    required String additiveId,
    required String url,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanAdditiveId = additiveId.trim();
    final cleanUrl = url.trim();

    if (cleanContractId.isEmpty || cleanAdditiveId.isEmpty) {
      throw Exception('contractId e additiveId são obrigatórios.');
    }

    final docRef = _doc(
      contractId: cleanContractId,
      additiveId: cleanAdditiveId,
    );

    await docRef.set(
      {
        'pdfUrl': cleanUrl.isEmpty ? FieldValue.delete() : cleanUrl,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );

    _invalidateAllAdditivesCache();
  }
}