import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/registers/register_class.dart';

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

  /// Cache por contrato (tela do contrato).
  final Map<String, List<ApostillesData>> _byContract =
  <String, List<ApostillesData>>{};
  final Map<String, bool> _loading = <String, bool>{};

  /// Cache global para dashboards via `collectionGroup('apostilles')`.
  List<ApostillesData>? _allApostillesCache;

  final Map<String, String> _statusByContract = <String, String>{};

  // =========================
  // Helpers internos
  // =========================

  String? _idToString(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    return id;
  }

  void _invalidateAllApostillesCache() {
    _allApostillesCache = null;
  }

  List<ApostillesData> _sorted(List<ApostillesData> list) {
    final l = List<ApostillesData>.from(list);
    l.sort((a, b) => (a.apostilleOrder ?? 0).compareTo(b.apostilleOrder ?? 0));
    return List<ApostillesData>.unmodifiable(l);
  }

  Future<List<ApostillesData>> _loadAllApostillesOnce() async {
    if (_allApostillesCache != null) return _allApostillesCache!;

    final snap = await _db.collectionGroup('apostilles').get();

    final list = snap.docs
        .map((d) => ApostillesData.fromDocument(snapshot: d))
        .toList();

    _allApostillesCache = List<ApostillesData>.unmodifiable(list);
    return _allApostillesCache!;
  }

  // =========================
  // Status via DFD (statusContrato)
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
  // Listagens (Dashboard + Tela)
  // =========================

  Future<List<ApostillesData>> getAllApostilles() async {
    return _loadAllApostillesOnce();
  }

  /// (mantém nome antigo por compatibilidade no seu projeto, se quiser)
  Future<List<ApostillesData>> getApostillesByContractIds(
      Set<String> contractIds,
      ) async {
    if (contractIds.isEmpty) return const <ApostillesData>[];
    final all = await _loadAllApostillesOnce();
    return all
        .where((a) => a.contractId != null && contractIds.contains(a.contractId))
        .toList();
  }

  Future<List<ApostillesData>> getAllApostillesOfContract({
    required String uidContract,
  }) async {
    if (uidContract.isEmpty) return const <ApostillesData>[];

    final contractRef = _db.collection('contracts').doc(uidContract);
    QuerySnapshot<Map<String, dynamic>> snap;

    try {
      snap = await contractRef
          .collection('apostilles')
          .orderBy('apostilleorder')
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snap = await contractRef.collection('apostilles').get();
      } else {
        rethrow;
      }
    }

    final list = snap.docs
        .map((d) => ApostillesData.fromDocument(snapshot: d))
        .toList();

    return list;
  }

  Future<List<ApostillesData>> ensureForContract(String contractId) async {
    if (contractId.isEmpty) return const <ApostillesData>[];
    if (_byContract.containsKey(contractId)) return _byContract[contractId]!;

    _loading[contractId] = true;
    try {
      final list = await getAllApostillesOfContract(uidContract: contractId);
      _byContract[contractId] = _sorted(list);
      return _byContract[contractId]!;
    } finally {
      _loading[contractId] = false;
    }
  }

  Future<List<ApostillesData>> refreshForContract(String contractId) async {
    if (contractId.isEmpty) return const <ApostillesData>[];
    _loading[contractId] = true;
    try {
      final list = await getAllApostillesOfContract(uidContract: contractId);
      _byContract[contractId] = _sorted(list);

      _invalidateAllApostillesCache();
      return _byContract[contractId]!;
    } finally {
      _loading[contractId] = false;
    }
  }

  List<ApostillesData> listCachedFor(String contractId) =>
      _byContract[contractId] ?? const <ApostillesData>[];

  // =========================
  // CRUD Apostilamento
  // =========================

  Future<void> saveOrUpdateApostille({
    required String contractId,
    required ApostillesData data,
  }) async {
    final firebaseUser = _auth.currentUser;

    final ref = _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles');

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

    // preserva createdAt/createdBy
    final snapshot = await docRef.get();
    final hasCreatedAt = snapshot.exists && snapshot.data()?['createdAt'] != null;
    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));
    await _notificarUsuariosSobreApostilamento(data, contractId);

    await refreshForContract(contractId);
    _invalidateAllApostillesCache();
  }

  Future<void> deleteApostille({
    required String contractId,
    required String apostilleId,
  }) async {
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .doc(apostilleId)
        .delete();

    final current = List<ApostillesData>.from(
      _byContract[contractId] ?? const <ApostillesData>[],
    )..removeWhere((e) => e.id == apostilleId);
    _byContract[contractId] = _sorted(current);

    _invalidateAllApostillesCache();
  }

  // =========================
  // Notificações
  // =========================

  Future<void> _notificarUsuariosSobreApostilamento(
      ApostillesData apostila,
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
      'tipo': 'apostilamento',
      'titulo': 'Novo apostilamento nº ${apostila.apostilleOrder}',
      'contractId': contractId,
      'apostilleId': apostila.id,
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
        if (data['tipo'] != 'apostilamento') continue;

        final contractId = data['contractId'];
        final apostilleId = data['apostilleId'];

        final originalSnap = await _db
            .collection('contracts')
            .doc(contractId)
            .collection('apostilles')
            .doc(apostilleId)
            .get();

        if (originalSnap.exists) {
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
  // Agregações por status (DFD.statusContrato)
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
          if ((_getDfdStatusForId(_idToString(c.id)) ?? '').toUpperCase() ==
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
              .collection('apostilles')
              .get();

          return snap.docs.fold<double>(0.0, (sum, doc) {
            final data = doc.data();
            final raw = data['apostilleValue'] ?? data['apostillevalue'];
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

  Future<double> somarValoresApostilamentosPorStatus({
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
          if ((_getDfdStatusForId(_idToString(c.id)) ?? '').toUpperCase() ==
              alvo)
            _idToString(c.id)!,
    ];

    for (final contractId in ids) {
      final s = await _db
          .collection('contracts')
          .doc(contractId)
          .collection('apostilles')
          .get();

      for (final d in s.docs) {
        final a = ApostillesData.fromDocument(snapshot: d);
        total += (a.apostilleValue ?? 0.0);
      }
    }

    return total;
  }

  Future<double> getAllApostillesValue(String contractId) async {
    final s = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .get();

    return s.docs.fold<double>(0.0, (sum, d) {
      final a = ApostillesData.fromDocument(snapshot: d);
      return sum + (a.apostilleValue ?? 0.0);
    });
  }

  // =========================
  // Attachments + Storage
  // =========================

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String _extFromName(String name) {
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
        .firstMatch(name.trim());
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

  String folderFor(ProcessData c, ApostillesData a) =>
      'contracts/${c.id}/apostilles/${a.id}/';

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

  Future<List<({String name, String url})>> listarArquivosDaApostila({
    required String contractId,
    required String apostilleId,
  }) async {
    final folderRef =
    _storage.ref('contracts/$contractId/apostilles/$apostilleId/');
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
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> setAttachments({
    required String contractId,
    required String apostilleId,
    required List<Attachment> attachments,
  }) async {
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .doc(apostilleId)
        .set(
      {
        'attachments': attachments.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );

    _invalidateAllApostillesCache();
  }

  // =========================
  // PDF legado (pdfUrl)
  // =========================

  String legacyFileName(ProcessData c, ApostillesData a) {
    final contrato = _sanitize('contrato');
    final ordem = (a.apostilleOrder ?? 0).toString().padLeft(3, '0');
    final proc = _sanitize(a.apostilleNumberProcess ?? 'processo');
    return '$contrato-$ordem-$proc.pdf';
  }

  String legacyPathFor(ProcessData c, ApostillesData a) =>
      '${folderFor(c, a)}${legacyFileName(c, a)}';

  Future<String> uploadLegacyBytes({
    required ProcessData contract,
    required ApostillesData apostille,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final path = legacyPathFor(contract, apostille);
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
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .doc(apostilleId)
        .update({
      'pdfUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    });

    _invalidateAllApostillesCache();
  }
}
