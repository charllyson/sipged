// lib/_blocs/process/additives/additives_repository.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/additives/additives_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/registers/register_class.dart';

class AdditivesRepository {
  AdditivesRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  /// Cache por contrato (usado nas telas de aditivo do contrato).
  final Map<String, List<AdditivesData>> _byContract =
  <String, List<AdditivesData>>{};
  final Map<String, bool> _loading = <String, bool>{};

  /// Cache global de TODOS os aditivos (para dashboards).
  ///
  /// - Carregado UMA VEZ por meio de `collectionGroup('additives')`.
  /// - Filtrado em memória por `contractId` nas chamadas do dashboard.
  List<AdditivesData>? _allAdditivesCache;

  final Map<String, String> _statusByContract = <String, String>{};

  // =========================
  // Helpers internos de ID / cache
  // =========================

  String? _idToString(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    return id;
  }

  void _invalidateAllAdditivesCache() {
    _allAdditivesCache = null;
  }

  Future<List<AdditivesData>> _loadAllAdditivesOnce() async {
    // Se já carregamos antes, reaproveita.
    if (_allAdditivesCache != null) return _allAdditivesCache!;

    // collectionGroup pega TODOS os subdocs "additives" em qualquer coleção-pai
    final snap = await _db.collectionGroup('additives').get();

    final list = snap.docs
        .map((d) => AdditivesData.fromDocument(snapshot: d))
        .toList();

    // Deixa o cache imutável para evitar alterações involuntárias.
    _allAdditivesCache = List<AdditivesData>.unmodifiable(list);
    return _allAdditivesCache!;
  }

  // =========================
  // Status via DFD (apenas para funções específicas)
  // =========================

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

      final data = identSnap.docs.first.data();
      final raw = data['statusContrato'];
      if (raw == null) return null;
      final s = raw.toString().trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureStatusesForContracts(
      Iterable<ProcessData> contratos,
      ) async {
    final futures = <Future<void>>[];

    for (final c in contratos) {
      final id = _idToString(c.id);
      if (id == null || _statusByContract.containsKey(id)) continue;

      futures.add(() async {
        final s = await _loadStatusContratoFromDfd(id);
        if (s != null && s.trim().isNotEmpty) {
          _statusByContract[id] = s.trim();
        }
      }());
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  String? _getDfdStatusForId(String? contractId) {
    if (contractId == null) return null;
    final v = _statusByContract[contractId];
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  // =========================
  // Listagens
  // =========================

  /// Retorna TODOS os aditivos (todas as coleções `.../additives/...`)
  /// usando `collectionGroup`, com cache em memória.
  Future<List<AdditivesData>> getAllAdditives() async {
    return _loadAllAdditivesOnce();
  }

  /// Retorna APENAS os aditivos cujos `contractId` estão em [contractIds].
  ///
  /// Implementação:
  /// - Carrega todos os aditivos UMA VEZ com `collectionGroup('additives')`.
  /// - Filtra em memória pelos IDs desejados.
  ///
  /// Isso é extremamente mais rápido que:
  /// - listar todos os contratos,
  /// - percorrer 1 a 1 e chamar `.collection('additives')` para cada.
  Future<List<AdditivesData>> getAdditivesByContractIds(
      Set<String> contractIds,
      ) async {
    if (contractIds.isEmpty) return const <AdditivesData>[];

    final all = await _loadAllAdditivesOnce();

    return all
        .where(
          (a) =>
      a.contractId != null && contractIds.contains(a.contractId),
    )
        .toList();
  }

  Future<List<AdditivesData>> getAllAdditivesOfContract({
    required String uidContract,
  }) async {
    if (uidContract.isEmpty) return const <AdditivesData>[];

    final contractRef = _db.collection('contracts').doc(uidContract);
    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await contractRef
          .collection('additives')
          .orderBy('additiveorder')
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snap = await contractRef.collection('additives').get();
      } else {
        rethrow;
      }
    }

    if (snap.docs.isEmpty) {
      // fallback legado em temContracts, se existir
      final altRef = _db.collection('temContracts').doc(uidContract);
      final altSnap = await altRef.collection('additives').get();
      if (altSnap.docs.isNotEmpty) {
        final altList = altSnap.docs
            .map((d) => AdditivesData.fromDocument(snapshot: d))
            .toList();
        return altList;
      }
    }

    final list = snap.docs
        .map((d) => AdditivesData.fromDocument(snapshot: d))
        .toList();

    return list;
  }

  Future<List<AdditivesData>> ensureForContract(String contractId) async {
    if (contractId.isEmpty) return const <AdditivesData>[];
    if (_byContract.containsKey(contractId)) {
      return _byContract[contractId]!;
    }

    _loading[contractId] = true;
    try {
      final list = await getAllAdditivesOfContract(uidContract: contractId);
      _byContract[contractId] = _sorted(list);
      return _byContract[contractId]!;
    } finally {
      _loading[contractId] = false;
    }
  }

  Future<List<AdditivesData>> refreshForContract(String contractId) async {
    if (contractId.isEmpty) return const <AdditivesData>[];
    _loading[contractId] = true;
    try {
      final list = await getAllAdditivesOfContract(uidContract: contractId);
      _byContract[contractId] = _sorted(list);

      // Mudou dado em Firestore -> invalida cache global do dashboard
      _invalidateAllAdditivesCache();

      return _byContract[contractId]!;
    } finally {
      _loading[contractId] = false;
    }
  }

  List<AdditivesData> listCachedFor(String contractId) =>
      _byContract[contractId] ?? const <AdditivesData>[];

  // =========================
  // Agregações por status (usadas em contextos específicos)
  // =========================

  Future<double> getValorPorStatus(
      List<ProcessData> contratos,
      String statusDesejado,
      ) async {
    if (contratos.isEmpty) return 0.0;

    await _ensureStatusesForContracts(contratos);

    final alvo = statusDesejado.trim().toUpperCase();

    final idsFiltrados = <String>{
      for (final c in contratos)
        if (_idToString(c.id) != null)
          if ((_getDfdStatusForId(_idToString(c.id)) ?? '')
              .toUpperCase() ==
              alvo)
            _idToString(c.id)!,
    };

    if (idsFiltrados.isEmpty) return 0.0;

    final totais = await Future.wait(
      idsFiltrados.map((contractId) async {
        try {
          final snap = await _db
              .collection('contracts')
              .doc(contractId)
              .collection('additives')
              .get();

          return snap.docs.fold<double>(0.0, (sum, doc) {
            final data = doc.data();
            final raw = data['additivevalue'] ?? data['additiveValue'];
            num? n;
            if (raw is num) {
              n = raw;
            } else if (raw is String) {
              n = num.tryParse(raw);
            }
            return sum + (n?.toDouble() ?? 0.0);
          });
        } catch (_) {
          return 0.0;
        }
      }),
    );

    return totais.fold<double>(0.0, (a, b) => a + b);
  }

  Future<double> somarValoresAditivosPorStatus({
    required List<ProcessData> contratos,
    required String status,
  }) async {
    if (contratos.isEmpty) return 0.0;

    await _ensureStatusesForContracts(contratos);

    final alvo = status.trim().toUpperCase();
    double total = 0.0;

    final ids = <String>[
      for (final c in contratos)
        if (_idToString(c.id) != null)
          if ((_getDfdStatusForId(_idToString(c.id)) ?? '')
              .toUpperCase() ==
              alvo)
            _idToString(c.id)!,
    ];

    for (final contractId in ids) {
      final s = await _db
          .collection('contracts')
          .doc(contractId)
          .collection('additives')
          .get();

      for (final d in s.docs) {
        final a = AdditivesData.fromDocument(snapshot: d);
        total += (a.additiveValue ?? 0.0);
      }
    }
    return total;
  }

  Future<double> getAllAdditivesValue(String contractId) async {
    final s = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();
    return s.docs.fold<double>(0.0, (sum, d) {
      final a = AdditivesData.fromDocument(snapshot: d);
      return sum + (a.additiveValue ?? 0.0);
    });
  }

  // =========================
  // CRUD Aditivo
  // =========================

  Future<void> saveOrUpdateAdditive({
    required String contractId,
    required AdditivesData data,
  }) async {
    final firebaseUser = _auth.currentUser;

    final ref = _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives');

    final docRef = (data.id != null && data.id!.isNotEmpty)
        ? ref.doc(data.id)
        : ref.doc();

    data.id ??= docRef.id;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'contractId': contractId,
      });

    final snapshot = await docRef.get();
    final hasCreatedAt =
        snapshot.exists && snapshot.data()?['createdAt'] != null;
    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));
    await _notificarUsuariosSobreAditivo(data, contractId);

    // Atualiza cache local por contrato + invalida cache global de dashboard
    await refreshForContract(contractId);
    _invalidateAllAdditivesCache();
  }

  Future<void> deleteAdditive({
    required String contractId,
    required String additiveId,
  }) async {
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .doc(additiveId)
        .delete();

    final current = List<AdditivesData>.from(
      _byContract[contractId] ?? const <AdditivesData>[],
    )..removeWhere((e) => e.id == additiveId);
    _byContract[contractId] = _sorted(current);

    // Aditivo removido => invalidar cache global
    _invalidateAllAdditivesCache();
  }

  // =========================
  // Notificações
  // =========================

  Future<void> _notificarUsuariosSobreAditivo(
      AdditivesData aditivo,
      String contractId,
      ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final batch = _db.batch();
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc();
    batch.set(ref, {
      'tipo': 'aditivo',
      'titulo': 'Novo aditivo nº ${aditivo.additiveOrder}',
      'contractId': contractId,
      'additiveId': aditivo.id,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
    await batch.commit();
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
      final List<Registro> registros = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['tipo'] == 'aditivo') {
          final contractId = data['contractId'];
          final additiveId = data['additiveId'];

          final originalSnap = await _db
              .collection('contracts')
              .doc(contractId)
              .collection('additives')
              .doc(additiveId)
              .get();

          if (originalSnap.exists) {
            final original =
            AdditivesData.fromDocument(snapshot: originalSnap);
            registros.add(
              Registro(
                id: doc.id,
                tipo: 'aditivo',
                data: data['createdAt']?.toDate() ?? DateTime.now(),
                original: original,
                contractData: await buscarContrato(contractId),
              ),
            );
          }
        }
      }
      return registros;
    });
  }

  Future<ProcessData?> buscarContrato(String contractId) async {
    final snap = await _db.collection('contracts').doc(contractId).get();
    if (!snap.exists) return null;
    return ProcessData.fromDocument(snapshot: snap);
  }

  // =========================
  // Attachments + Storage
  // =========================

  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String _extFromName(String name) {
    final m = RegExp(
      r'\.([a-z0-9]+)$',
      caseSensitive: false,
    ).firstMatch(name.trim());
    return m == null ? '' : '.${m.group(1)!.toLowerCase()}';
  }

  String _baseName(String name) {
    var s = name.trim();
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#');
    if (h != -1) s = s.substring(0, h);
    s = s.split('/').last;
    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String storedFileName(String original) {
    final base = _sanitize(_baseName(original));
    final rnd = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final ext = _extFromName(original);
    return '$base-$rnd${ext.isEmpty ? ".bin" : ext}';
  }

  String folderFor(ProcessData c, AdditivesData a) =>
      'contracts/${c.id}/additives/${a.id}/';

  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }
    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required AdditivesData additive,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = folderFor(contract, additive);
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final contentType = (_extFromName(originalName) == '.pdf')
        ? 'application/pdf'
        : 'application/octet-stream';

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {'originalName': originalName, 'label': label},
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) {
          onProgress(e.bytesTransferred / e.totalBytes);
        }
      });
    }

    await task;
    final url = await ref.getDownloadURL();
    final meta = await ref.getMetadata();

    return Attachment(
      id: ref.name,
      label: label.isEmpty ? _baseName(originalName) : label,
      url: url,
      path: ref.fullPath,
      ext: _extFromName(originalName),
      size: meta.size?.toInt(),
      createdAt: DateTime.now(),
      createdBy: _auth.currentUser?.uid,
    );
  }

  Future<List<({String name, String url})>> listarArquivosDoAditivo({
    required String contractId,
    required String additiveId,
  }) async {
    final folderRef =
    _storage.ref('contracts/$contractId/additives/$additiveId/');
    final result = await folderRef.listAll();

    final out = <({String name, String url})>[];
    for (final item in result.items) {
      try {
        final url = await item.getDownloadURL();
        out.add((name: item.name, url: url));
      } catch (_) {
        // ignora itens inacessíveis
      }
    }

    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> setAttachments({
    required String contractId,
    required String additiveId,
    required List<Attachment> attachments,
  }) async {
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .doc(additiveId)
        .set(
      {
        'attachments': attachments.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );

    // Atualização de anexos => invalida cache global de aditivos
    _invalidateAllAdditivesCache();
  }

  // =========================
  // PDFs legados
  // =========================

  String legacyFileName(ProcessData c, AdditivesData a) {
    final contrato = _sanitize('contrato');
    final ordem = (a.additiveOrder ?? 0).toString().padLeft(3, '0');
    final proc = _sanitize(a.additiveNumberProcess ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String legacyPathFor(ProcessData c, AdditivesData a) =>
      '${folderFor(c, a)}${legacyFileName(c, a)}';

  Future<String> uploadLegacyBytes({
    required ProcessData contract,
    required AdditivesData additive,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final path = legacyPathFor(contract, additive);
    final ref = _storage.ref(path);

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) {
          onProgress(e.bytesTransferred / e.totalBytes);
        }
      });
    }

    await task;
    return ref.getDownloadURL();
  }

  Future<bool> deleteLegacyPdf({
    required ProcessData contract,
    required AdditivesData additive,
  }) async {
    try {
      await _storage.ref(legacyPathFor(contract, additive)).delete();
      _invalidateAllAdditivesCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verificarSePdfDeAditivoExiste({
    required ProcessData contract,
    required AdditivesData additive,
  }) async {
    try {
      await _storage.ref(legacyPathFor(contract, additive)).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrlDoAditivo({
    required ProcessData contract,
    required AdditivesData additive,
  }) async {
    try {
      return await _storage
          .ref(legacyPathFor(contract, additive))
          .getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarUrlPdfDoAditivo({
    required String contractId,
    required String additiveId,
    required String url,
  }) async {
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .doc(additiveId)
        .update({
      'pdfUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    });

    _invalidateAllAdditivesCache();
  }

  // =========================
  // Utils internos
  // =========================

  List<AdditivesData> _sorted(List<AdditivesData> list) {
    final l = List<AdditivesData>.from(list);
    l.sort(
          (a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0),
    );
    return List<AdditivesData>.unmodifiable(l);
  }
}
