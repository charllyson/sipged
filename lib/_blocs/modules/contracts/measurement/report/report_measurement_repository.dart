import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/budget/budget_data.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'report_measurement_data.dart';

class ReportMeasurementRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  ReportMeasurementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  static const int _kMaxBatchOps = 500;

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  String _orderKeyFromCode(String code) {
    final parts = code.split('.');
    return parts.map((p) => p.padLeft(4, '0')).join('');
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  String _safeExt(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '.pdf';
    final idx = n.lastIndexOf('.');
    if (idx <= 0) return '.pdf';
    final ext = n.substring(idx).toLowerCase();
    return ext.isEmpty ? '.pdf' : ext;
  }

  String _safeLabelFromName(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return 'Arquivo';
    final idx = n.lastIndexOf('.');
    if (idx <= 0) return n;
    return n.substring(0, idx);
  }

  // ---------------------------------------------------------------------------
  // Coleções base
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _col(String contractId) => _db
      .collection('contracts')
      .doc(contractId)
      .collection(ReportMeasurementData.collectionName);

  DocumentReference<Map<String, dynamic>> _measurementDoc({
    required String contractId,
    required String measurementId,
  }) {
    return _col(contractId).doc(measurementId);
  }

  // Storage path: contracts/{contractId}/reportsMeasurement/{measurementId}/files/{attachmentId}.pdf
  String _storageFilePath({
    required String contractId,
    required String measurementId,
    required String attachmentId,
    required String ext,
  }) {
    final e = ext.startsWith('.') ? ext : '.$ext';
    return 'contracts/$contractId/${ReportMeasurementData.collectionName}/$measurementId/files/$attachmentId$e';
  }

  Reference _storageRef(String path) => _storage.ref(path);

  // ---------------------------------------------------------------------------
  // Consultas (por contrato / collectionGroup)
  // ---------------------------------------------------------------------------

  Future<List<ReportMeasurementData>> getAllMeasurementsOfContract({
    required String uidContract,
  }) async {
    final snapshot = await _col(uidContract).orderBy('order').get();
    return snapshot.docs.map((doc) => ReportMeasurementData.fromDocument(doc)).toList();
  }

  Future<List<ReportMeasurementData>> getAllMeasurementsCollectionGroup() async {
    final query = await _db.collectionGroup(ReportMeasurementData.collectionName).get();
    return query.docs.map((doc) => ReportMeasurementData.fromDocument(doc)).toList();
  }

  Future<ProcessData?> buscarContrato(String contractId) async {
    final snap = await _db.collection('contracts').doc(contractId).get();
    if (!snap.exists) return null;
    return ProcessData.fromDocument(snapshot: snap);
  }

  // ---------------------------------------------------------------------------
  // CRUD principal
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdateReport(ReportMeasurementData report) async {
    final user = _auth.currentUser;
    final contractId = report.contractId;
    if (contractId == null) throw Exception('contractId é obrigatório');

    final ref = _col(contractId);
    final docRef = (report.id != null) ? ref.doc(report.id) : ref.doc();
    report.id ??= docRef.id;

    final data = report.toFirestore()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
        'contractId': contractId,
      });

    final existing = await docRef.get();
    final hasCreatedAt = existing.exists && existing.data()?['createdAt'] != null;
    if (!hasCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = user?.uid ?? '';
    }

    await docRef.set(data, SetOptions(merge: true));
    await _recalcularFinancialPercentage(contractId);
    await _notificar(report, contractId);
  }

  Future<void> deleteMeasurement({
    required String contractId,
    required String measurementId,
  }) async {
    // ✅ apaga também arquivos do storage (pasta)
    // (Firestore não tem delete em lote de storage, então tentamos listar)
    try {
      final folder = _storage.ref(
        'contracts/$contractId/${ReportMeasurementData.collectionName}/$measurementId/files',
      );
      final ls = await folder.listAll();
      for (final item in ls.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}

    await _col(contractId).doc(measurementId).delete();
    await _recalcularFinancialPercentage(contractId);
  }

  // ---------------------------------------------------------------------------
  // ATTACHMENTS (novo)
  // ---------------------------------------------------------------------------

  /// ✅ Pick PDF -> upload Storage -> salva Attachment em `attachments[]`
  Future<Attachment> pickAndUploadAttachment({
    required String contractId,
    required String measurementId,
    void Function(double p)? onProgress, // 0..1
    String? forcedLabel,
  }) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true, // ✅ garante bytes (web + mobile)
    );

    if (res == null || res.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado.');
    }

    final f = res.files.first;
    final Uint8List? bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Não foi possível ler o arquivo. Tente novamente.');
    }

    final ext = _safeExt(f.name);
    final label = (forcedLabel?.trim().isNotEmpty ?? false)
        ? forcedLabel!.trim()
        : _safeLabelFromName(f.name);

    final attachmentId = _db.collection('_').doc().id; // id aleatório
    final path = _storageFilePath(
      contractId: contractId,
      measurementId: measurementId,
      attachmentId: attachmentId,
      ext: ext,
    );

    final ref = _storageRef(path);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'contractId': contractId,
          'measurementId': measurementId,
          'attachmentId': attachmentId,
        },
      ),
    );

    // progresso
    task.snapshotEvents.listen((snap) {
      final total = snap.totalBytes;
      if (total <= 0) return;
      final p = snap.bytesTransferred / total;
      onProgress?.call(p.clamp(0.0, 1.0));
    });

    await task;
    final url = await ref.getDownloadURL();

    final att = Attachment(
      id: attachmentId,
      label: label,
      url: url,
      path: path,
      ext: ext,
    );

    await _addAttachmentToMeasurementDoc(
      contractId: contractId,
      measurementId: measurementId,
      attachment: att,
    );

    return att;
  }

  Future<void> _addAttachmentToMeasurementDoc({
    required String contractId,
    required String measurementId,
    required Attachment attachment,
  }) async {
    final docRef = _measurementDoc(contractId: contractId, measurementId: measurementId);

    // garante que exista
    await docRef.set({
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
      'contractId': contractId,
    }, SetOptions(merge: true));

    // merge manual (array de maps)
    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    final raw = data['attachments'];

    final list = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    }

    // evita duplicar pelo id
    list.removeWhere((m) => (m['id']?.toString() ?? '') == attachment.id);

    list.add(attachment.toMap());

    await docRef.set({
      'attachments': list,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    }, SetOptions(merge: true));
  }

  Future<void> deleteAttachment({
    required String contractId,
    required String measurementId,
    required Attachment attachment,
  }) async {
    // 1) remove do firestore
    final docRef = _measurementDoc(contractId: contractId, measurementId: measurementId);
    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};

    final raw = data['attachments'];
    final list = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    }

    list.removeWhere((m) => (m['id']?.toString() ?? '') == attachment.id);

    await docRef.set({
      'attachments': list.isEmpty ? FieldValue.delete() : list,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    }, SetOptions(merge: true));

    // 2) apaga do storage
    final p = (attachment.path).trim();
    if (p.isNotEmpty) {
      try {
        await _storageRef(p).delete();
      } catch (_) {}
    }
  }

  Future<void> renameAttachmentLabel({
    required String contractId,
    required String measurementId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    final docRef = _measurementDoc(contractId: contractId, measurementId: measurementId);
    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};

    final raw = data['attachments'];
    final list = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    }

    for (int i = 0; i < list.length; i++) {
      final id = (list[i]['id']?.toString() ?? '');
      if (id == oldItem.id) {
        list[i] = newItem.toMap();
        break;
      }
    }

    await docRef.set({
      'attachments': list,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // PDF legado (mantido)
  // ---------------------------------------------------------------------------

  Future<void> salvarUrlPdfDaMedicao({
    required String contractId,
    required String measurementId,
    required String url,
  }) async {
    await _col(contractId).doc(measurementId).update({
      'pdfUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    });
  }

  // ---------------------------------------------------------------------------
  // Notificações
  // ---------------------------------------------------------------------------

  Future<void> _notificar(ReportMeasurementData report, String contractId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _db.collection('users').doc(uid).collection('notifications').doc();
    await ref.set({
      'tipo': 'medicao',
      'titulo': 'Nova medição nº ${report.order}',
      'contractId': contractId,
      'measurementId': report.id,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  // ---------------------------------------------------------------------------
  // Agregações e totais
  // ---------------------------------------------------------------------------

  double somarValorMedicoes(List<ReportMeasurementData> medicoes) {
    return medicoes.fold<double>(0.0, (s, m) => s + (m.value ?? 0.0));
  }

  // ---------------------------------------------------------------------------
  // % financeiro (contrato)
  // ---------------------------------------------------------------------------

  Future<void> _recalcularFinancialPercentage(String contractId) async {
    double total = 0.0;

    final reps = await _col(contractId).get();
    for (final d in reps.docs) {
      final v = (d.data()['value'] ?? 0);
      total += (v is num) ? v.toDouble() : 0.0;
    }

    final contractSnap = await _db.collection('contracts').doc(contractId).get();
    final initialValue = (contractSnap.data()?['initialContractValue'] ?? 0);
    final baseInicial = (initialValue is num) ? initialValue.toDouble() : 0.0;

    final adds = await _db.collection('contracts').doc(contractId).collection('additives').get();
    double totAdd = 0.0;
    for (final a in adds.docs) {
      final v = (a.data()['additiveValue'] ?? 0);
      totAdd += (v is num) ? v.toDouble() : 0;
    }

    final apos = await _db.collection('contracts').doc(contractId).collection('apostilles').get();
    double totApo = 0.0;
    for (final ap in apos.docs) {
      final v = (ap.data()['apostilleValue'] ?? 0);
      totApo += (v is num) ? v.toDouble() : 0;
    }

    final totalBase = baseInicial + totAdd + totApo;
    final percent = totalBase > 0 ? (total / totalBase) * 100.0 : 0.0;

    await _db.collection('contracts').doc(contractId).set({
      'financialPercentage': percent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // ITENS da medição (mantido)
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _itemsCol({
    required String contractId,
    required String measurementId,
  }) =>
      _measurementDoc(contractId: contractId, measurementId: measurementId)
          .collection('items');

  Future<Map<String, Map<String, dynamic>>> loadItemsMap({
    required String contractId,
    required String measurementId,
  }) async {
    final qs = await _itemsCol(contractId: contractId, measurementId: measurementId).get();

    final out = <String, Map<String, dynamic>>{};
    for (final d in qs.docs) {
      final m = d.data();
      out[d.id] = {
        'qtyPrev': _asDouble(m['qtyPrev']),
        'qtyPeriod': _asDouble(m['qtyPeriod']),
        'qtyAccum': _asDouble(m['qtyAccum']),
        'qtyContractBal': _asDouble(m['qtyContractBal']),
        'valPrev': _asDouble(m['valPrev']),
        'valPeriod': _asDouble(m['valPeriod']),
        'valAccum': _asDouble(m['valAccum']),
        'valContractBal': _asDouble(m['valContractBal']),
        'updatedAt': m['updatedAt'],
        'updatedBy': m['updatedBy'],
        'budgetItemId': m['budgetItemId'] ?? d.id,
      };
    }
    return out;
  }

  Future<void> upsertMeasurementItem({
    required String contractId,
    required String measurementId,
    required String budgetItemId,
    required Map<String, dynamic> payload,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final data = <String, dynamic>{
      'budgetItemId': budgetItemId,
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
      'contractId': contractId,
      'measurementId': measurementId,
    };
    await _itemsCol(contractId: contractId, measurementId: measurementId)
        .doc(budgetItemId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateMeasurementValue({
    required String contractId,
    required String measurementId,
    required double value,
  }) async {
    await _col(contractId).doc(measurementId).set({
      'value': value,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    }, SetOptions(merge: true));

    await _recalcularFinancialPercentage(contractId);
  }

  // ---------------------------------------------------------------------------
  // BREAKDOWN (mantido)
  // ---------------------------------------------------------------------------

  Future<void> saveBreakdownDomain({
    required String contractId,
    required String measurementId,
    required BudgetData data,
  }) async {
    final metaRef = _measurementDoc(contractId: contractId, measurementId: measurementId)
        .collection('breakdownMeta')
        .doc('meta');

    await metaRef.set({
      'headers': data.schema.headerNames,
      'colTypes': data.schema.headerTypes,
      'colWidths': data.schema.headerWidths,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final writeId = DateTime.now().millisecondsSinceEpoch.toString();
    final rowsVersionDoc = metaRef.collection('rows_v').doc(writeId);
    final groupsCol = rowsVersionDoc.collection('groups');

    final pendingGroupSets =
    <MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>[];
    final pendingItemSets =
    <MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>[];

    int runningIndex = 0;
    int currentGroupOrder = -1;
    String currentGroupId = '';

    for (final entry in data.entries) {
      if (entry is BudgetSection) {
        currentGroupOrder = entry.order;
        currentGroupId = currentGroupOrder.toString();
        final gRef = groupsCol.doc(currentGroupId);
        pendingGroupSets.add(MapEntry(gRef, {
          'order': entry.order,
          'title': entry.title,
          'updatedAt': FieldValue.serverTimestamp(),
        }));
      } else if (entry is BudgetItem) {
        if (currentGroupId.isEmpty) {
          currentGroupOrder = 0;
          currentGroupId = '0';
          final gRef = groupsCol.doc(currentGroupId);
          pendingGroupSets.add(MapEntry(gRef, {
            'order': currentGroupOrder,
            'title': '',
            'updatedAt': FieldValue.serverTimestamp(),
          }));
        }

        final itemsCol = groupsCol.doc(currentGroupId).collection('items');
        final orderKey = _orderKeyFromCode(entry.code);
        final docId =
        ('${orderKey}_$runningIndex').padRight(40, '0').substring(0, 40);

        final fixedRow = List<String>.generate(
          data.schema.columns.length,
              (i) => (i < entry.values.length) ? entry.values[i] : '',
        );

        pendingItemSets.add(MapEntry(itemsCol.doc(docId), {
          'code': entry.code,
          'depth': entry.depth,
          'index': runningIndex,
          'orderKey': orderKey,
          'values': fixedRow,
          'updatedAt': FieldValue.serverTimestamp(),
        }));

        runningIndex++;
      }
    }

    for (final chunk in _chunk(pendingGroupSets, _kMaxBatchOps)) {
      final batch = _db.batch();
      for (final e in chunk) {
        batch.set(e.key, e.value, SetOptions(merge: true));
      }
      await batch.commit();
    }
    for (final chunk in _chunk(pendingItemSets, _kMaxBatchOps)) {
      final batch = _db.batch();
      for (final e in chunk) {
        batch.set(e.key, e.value, SetOptions(merge: true));
      }
      await batch.commit();
    }

    final rowsCol = metaRef.collection('rows');
    final existingGroups = await rowsCol.get();
    for (final g in existingGroups.docs) {
      final its = await g.reference.collection('items').get();
      for (final chunk in _chunk(its.docs, _kMaxBatchOps)) {
        final batch = _db.batch();
        for (final d in chunk) batch.delete(d.reference);
        await batch.commit();
      }
      await g.reference.delete();
    }

    final batchGroups = _db.batch();
    for (final e in pendingGroupSets) {
      final groupId = e.key.id;
      final gRef = rowsCol.doc(groupId);
      batchGroups.set(gRef, {
        'order': e.value['order'],
        'title': e.value['title'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batchGroups.commit();

    final byGroup = <String,
        List<MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>>{};
    for (final it in pendingItemSets) {
      final groupId = it.key.parent.parent!.id;
      (byGroup[groupId] ??= []).add(it);
    }
    for (final entry in byGroup.entries) {
      final groupId = entry.key;
      final itemsCol = rowsCol.doc(groupId).collection('items');
      for (final chunk in _chunk(entry.value, _kMaxBatchOps)) {
        final batch = _db.batch();
        for (final it in chunk) {
          final docId = it.key.id;
          final data = it.value;
          batch.set(itemsCol.doc(docId), data, SetOptions(merge: true));
        }
        await batch.commit();
      }
    }

    await metaRef.set({
      'activeWriteId': writeId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _cleanupOldBreakdownVersions(metaRef, keepLast: 2);
  }

  Future<void> _cleanupOldBreakdownVersions(
      DocumentReference<Map<String, dynamic>> metaRef, {
        int keepLast = 2,
      }) async {
    final rowsV = await metaRef.collection('rows_v').get();
    if (rowsV.docs.length <= keepLast) return;

    final docs = rowsV.docs..sort((a, b) => a.id.compareTo(b.id));
    final toDelete = docs.take(docs.length - keepLast).toList();

    for (final d in toDelete) {
      final groups = await d.reference.collection('groups').get();
      for (final g in groups.docs) {
        final items = await g.reference.collection('items').get();
        for (final chunk in _chunk(items.docs, _kMaxBatchOps)) {
          final batch = _db.batch();
          for (final it in chunk) batch.delete(it.reference);
          await batch.commit();
        }
        await g.reference.delete();
      }
      await d.reference.delete();
    }
  }
}
