// lib/_blocs/modules/contracts/apostilles/apostilles_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/registers/register_class.dart';

class ApostillesRepository {
  ApostillesRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  final Map<String, List<ApostillesData>> _byContract =
  <String, List<ApostillesData>>{};

  final Map<String, bool> _loading = <String, bool>{};

  List<ApostillesData>? _allApostillesCache;

  final Map<String, String> _statusByContract = <String, String>{};

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('apostilles');
  }

  DocumentReference<Map<String, dynamic>> _doc({
    required String contractId,
    required String apostilleId,
  }) {
    return _col(contractId).doc(apostilleId);
  }

  String? _idToString(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  void _invalidateAllApostillesCache() {
    _allApostillesCache = null;
  }

  List<ApostillesData> _sorted(List<ApostillesData> list) {
    final sorted = List<ApostillesData>.from(list);

    sorted.sort(
          (a, b) => (a.apostilleOrder ?? 0).compareTo(b.apostilleOrder ?? 0),
    );

    return List<ApostillesData>.unmodifiable(sorted);
  }

  Future<List<ApostillesData>> _loadAllApostillesOnce() async {
    if (_allApostillesCache != null) return _allApostillesCache!;

    final snap = await _db.collectionGroup('apostilles').get();

    final list = snap.docs
        .map((doc) => ApostillesData.fromDocument(snapshot: doc))
        .toList();

    _allApostillesCache = List<ApostillesData>.unmodifiable(list);

    return _allApostillesCache!;
  }

  // ---------------------------------------------------------------------------
  // Status via DFD
  // ---------------------------------------------------------------------------

  Future<String?> _loadStatusContratoFromDfd(String contractId) async {
    try {
      final dfdSnap = await _db
          .collection('contracts')
          .doc(contractId)
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
      Iterable<ProcessData> contratos,
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

  // ---------------------------------------------------------------------------
  // Listagens
  // ---------------------------------------------------------------------------

  Future<List<ApostillesData>> getAllApostilles() async {
    return _loadAllApostillesOnce();
  }

  Future<List<ApostillesData>> getApostillesByContractIds(
      Set<String> contractIds,
      ) async {
    if (contractIds.isEmpty) return const <ApostillesData>[];

    final all = await _loadAllApostillesOnce();

    return all.where((apostille) {
      final contractId = apostille.contractId;
      return contractId != null && contractIds.contains(contractId);
    }).toList();
  }

  Future<List<ApostillesData>> getAllApostillesOfContract({
    required String uidContract,
  }) async {
    final contractId = uidContract.trim();

    if (contractId.isEmpty) return const <ApostillesData>[];

    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await _col(contractId).orderBy('apostilleorder').get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snap = await _col(contractId).get();
      } else {
        rethrow;
      }
    }

    return snap.docs
        .map((doc) => ApostillesData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<List<ApostillesData>> ensureForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return const <ApostillesData>[];

    if (_byContract.containsKey(cleanContractId)) {
      return _byContract[cleanContractId]!;
    }

    _loading[cleanContractId] = true;

    try {
      final list = await getAllApostillesOfContract(
        uidContract: cleanContractId,
      );

      _byContract[cleanContractId] = _sorted(list);

      return _byContract[cleanContractId]!;
    } finally {
      _loading[cleanContractId] = false;
    }
  }

  Future<List<ApostillesData>> refreshForContract(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return const <ApostillesData>[];

    _loading[cleanContractId] = true;

    try {
      final list = await getAllApostillesOfContract(
        uidContract: cleanContractId,
      );

      _byContract[cleanContractId] = _sorted(list);
      _invalidateAllApostillesCache();

      return _byContract[cleanContractId]!;
    } finally {
      _loading[cleanContractId] = false;
    }
  }

  List<ApostillesData> listCachedFor(String contractId) {
    return _byContract[contractId] ?? const <ApostillesData>[];
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdateApostille({
    required String contractId,
    required ApostillesData data,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar apostilamento.');
    }

    final firebaseUser = _auth.currentUser;

    final ref = _col(cleanContractId);

    final docRef = data.id != null && data.id!.trim().isNotEmpty
        ? ref.doc(data.id!.trim())
        : ref.doc();

    final apostilleId = docRef.id;

    data.id = apostilleId;
    data.contractId = cleanContractId;

    final snapshot = await docRef.get();

    final json = data.toJson()
      ..addAll({
        'id': apostilleId,
        'contractId': cleanContractId,
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

    await _notificarUsuariosSobreApostilamento(data, cleanContractId);

    await refreshForContract(cleanContractId);
    _invalidateAllApostillesCache();
  }

  Future<void> deleteApostille({
    required String contractId,
    required String apostilleId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanApostilleId = apostilleId.trim();

    if (cleanContractId.isEmpty || cleanApostilleId.isEmpty) return;

    final docRef = _doc(
      contractId: cleanContractId,
      apostilleId: cleanApostilleId,
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
        'contracts/$cleanContractId/apostilles/$cleanApostilleId/',
      );

      final result = await folder.listAll();

      for (final item in result.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}

    await docRef.delete();

    final current = List<ApostillesData>.from(
      _byContract[cleanContractId] ?? const <ApostillesData>[],
    )..removeWhere((item) => item.id == cleanApostilleId);

    _byContract[cleanContractId] = _sorted(current);

    _invalidateAllApostillesCache();
  }

  // ---------------------------------------------------------------------------
  // Notificações
  // ---------------------------------------------------------------------------

  Future<void> _notificarUsuariosSobreApostilamento(
      ApostillesData apostila,
      String contractId,
      ) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    final ref = _db.collection('users').doc(uid).collection('notifications').doc();

    await ref.set({
      'tipo': 'apostilamento',
      'titulo': 'Novo apostilamento nº ${apostila.apostilleOrder}',
      'contractId': contractId,
      'apostilleId': apostila.id,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  Stream<List<Registro>> getNotificacoesRecentesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((snapshot) async {
      final registros = <Registro>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['tipo'] != 'apostilamento') continue;

        final contractId = data['contractId']?.toString();
        final apostilleId = data['apostilleId']?.toString();

        if (contractId == null || apostilleId == null) continue;

        final originalSnap = await _col(contractId).doc(apostilleId).get();

        if (!originalSnap.exists) continue;

        final original = ApostillesData.fromDocument(snapshot: originalSnap);

        registros.add(
          Registro(
            id: doc.id,
            tipo: 'apostilamento',
            data: data['createdAt']?.toDate() ?? DateTime.now(),
            original: original,
            contractData: await buscarContrato(contractId),
          ),
        );
      }

      return registros;
    });
  }

  Future<ProcessData?> buscarContrato(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final snap = await _db.collection('contracts').doc(cleanContractId).get();

    if (!snap.exists) return null;

    return ProcessData.fromDocument(snapshot: snap);
  }

  // ---------------------------------------------------------------------------
  // Agregações
  // ---------------------------------------------------------------------------

  Future<double> somarValoresApostilamentosPorStatus({
    required List<ProcessData> contratos,
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
        final apostille = ApostillesData.fromDocument(snapshot: doc);
        total += apostille.apostilleValue ?? 0.0;
      }
    }

    return total;
  }

  Future<double> getAllApostillesValue(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return 0.0;

    final snap = await _col(cleanContractId).get();

    return snap.docs.fold<double>(0.0, (totalAtual, doc) {
      final apostille = ApostillesData.fromDocument(snapshot: doc);
      return totalAtual + (apostille.apostilleValue ?? 0.0);
    });
  }

  // ---------------------------------------------------------------------------
  // Attachments + Storage
  // ---------------------------------------------------------------------------

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

  String folderFor(ProcessData contract, ApostillesData apostille) {
    final contractId = contract.id?.trim();
    final apostilleId = apostille.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contract.id é obrigatório para anexos de apostilamento.');
    }

    if (apostilleId == null || apostilleId.isEmpty) {
      throw Exception('apostille.id é obrigatório para anexos de apostilamento.');
    }

    return 'contracts/$contractId/apostilles/$apostilleId/';
  }

  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }

    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required ApostillesData apostille,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = folderFor(contract, apostille);
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
          'originalName': originalName,
          'label': label,
          'contractId': contract.id ?? '',
          'apostilleId': apostille.id ?? '',
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

  Future<List<({String name, String url})>> listarArquivosDaApostila({
    required String contractId,
    required String apostilleId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanApostilleId = apostilleId.trim();

    if (cleanContractId.isEmpty || cleanApostilleId.isEmpty) {
      return const <({String name, String url})>[];
    }

    final folderRef = _storage.ref(
      'contracts/$cleanContractId/apostilles/$cleanApostilleId/',
    );

    final result = await folderRef.listAll();

    final out = <({String name, String url})>[];

    for (final item in result.items) {
      try {
        final url = await item.getDownloadURL();
        out.add((name: item.name, url: url));
      } catch (_) {}
    }

    out.sort((a, b) => a.name.compareTo(b.name));

    return out;
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    final cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) return;

    try {
      await _storage.ref(cleanPath).delete();
    } catch (_) {}
  }

  Future<void> setAttachments({
    required String contractId,
    required String apostilleId,
    required List<Attachment> attachments,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanApostilleId = apostilleId.trim();

    if (cleanContractId.isEmpty || cleanApostilleId.isEmpty) {
      throw Exception('contractId e apostilleId são obrigatórios.');
    }

    await _doc(
      contractId: cleanContractId,
      apostilleId: cleanApostilleId,
    ).set(
      {
        'attachments': attachments.isEmpty
            ? FieldValue.delete()
            : attachments.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );

    final current = List<ApostillesData>.from(
      _byContract[cleanContractId] ?? const <ApostillesData>[],
    );

    final index = current.indexWhere((item) => item.id == cleanApostilleId);

    if (index >= 0) {
      current[index] = current[index].copyWith(
        attachments: attachments,
        clearAttachments: attachments.isEmpty,
      );

      _byContract[cleanContractId] = _sorted(current);
    }

    _invalidateAllApostillesCache();
  }

  // ---------------------------------------------------------------------------
  // PDF legado
  // ---------------------------------------------------------------------------

  String legacyFileName(ProcessData contract, ApostillesData apostille) {
    final contrato = _sanitize('contrato');
    final ordem = (apostille.apostilleOrder ?? 0).toString().padLeft(3, '0');
    final processo = _sanitize(apostille.apostilleNumberProcess ?? 'processo');

    return '$contrato-$ordem-$processo.pdf';
  }

  String legacyPathFor(ProcessData contract, ApostillesData apostille) {
    return '${folderFor(contract, apostille)}${legacyFileName(contract, apostille)}';
  }

  Future<String> uploadLegacyBytes({
    required ProcessData contract,
    required ApostillesData apostille,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(legacyPathFor(contract, apostille));

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
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
    required ProcessData contract,
    required ApostillesData apostille,
  }) async {
    try {
      await _storage.ref(legacyPathFor(contract, apostille)).delete();
      _invalidateAllApostillesCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verificarSePdfDeApostilaExiste({
    required ProcessData contract,
    required ApostillesData apostille,
  }) async {
    try {
      await _storage.ref(legacyPathFor(contract, apostille)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrlDaApostila({
    required ProcessData contract,
    required ApostillesData apostille,
  }) async {
    try {
      return await _storage.ref(legacyPathFor(contract, apostille)).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarUrlPdfDaApostila({
    required String contractId,
    required String apostilleId,
    required String url,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanApostilleId = apostilleId.trim();
    final cleanUrl = url.trim();

    if (cleanContractId.isEmpty || cleanApostilleId.isEmpty) {
      throw Exception('contractId e apostilleId são obrigatórios.');
    }

    await _doc(
      contractId: cleanContractId,
      apostilleId: cleanApostilleId,
    ).set(
      {
        'pdfUrl': cleanUrl.isEmpty ? FieldValue.delete() : cleanUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );

    _invalidateAllApostillesCache();
  }
}