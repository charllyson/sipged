// lib/_blocs/modules/contracts/measurement/report/report_measurement_repository.dart

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
  ReportMeasurementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  static const int _kMaxBatchOps = 500;

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];

    for (int i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(
          i,
          i + size > list.length ? list.length : i + size,
        ),
      );
    }

    return chunks;
  }

  String _orderKeyFromCode(String code) {
    final parts = code.split('.');
    return parts.map((p) => p.padLeft(4, '0')).join('');
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }

    return 0.0;
  }

  String _safeExt(String? name) {
    final cleanName = (name ?? '').trim();

    if (cleanName.isEmpty) return '.pdf';

    final index = cleanName.lastIndexOf('.');

    if (index <= 0) return '.pdf';

    final ext = cleanName.substring(index).toLowerCase();

    return ext.isEmpty ? '.pdf' : ext;
  }

  String _safeLabelFromName(String? name) {
    final cleanName = (name ?? '').trim();

    if (cleanName.isEmpty) return 'Arquivo';

    final index = cleanName.lastIndexOf('.');

    if (index <= 0) return cleanName;

    return cleanName.substring(0, index);
  }

  // ---------------------------------------------------------------------------
  // Referências
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _db
        .collection('contracts')
        .doc(contractId)
        .collection(ReportMeasurementData.collectionName);
  }

  DocumentReference<Map<String, dynamic>> _measurementDoc({
    required String contractId,
    required String measurementId,
  }) {
    return _col(contractId).doc(measurementId);
  }

  CollectionReference<Map<String, dynamic>> _itemsCol({
    required String contractId,
    required String measurementId,
  }) {
    return _measurementDoc(
      contractId: contractId,
      measurementId: measurementId,
    ).collection('items');
  }

  String _storageFilePath({
    required String contractId,
    required String measurementId,
    required String attachmentId,
    required String ext,
  }) {
    final cleanExt = ext.startsWith('.') ? ext : '.$ext';

    return 'contracts/$contractId/${ReportMeasurementData.collectionName}/$measurementId/files/$attachmentId$cleanExt';
  }

  Reference _storageRef(String path) {
    return _storage.ref(path);
  }

  // ---------------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------------

  Future<List<ReportMeasurementData>> getAllMeasurementsOfContract({
    required String uidContract,
  }) async {
    final snapshot = await _col(uidContract).orderBy('order').get();

    return snapshot.docs.map(ReportMeasurementData.fromDocument).toList();
  }

  Future<List<ReportMeasurementData>> getAllMeasurementsCollectionGroup() async {
    final query = await _db
        .collectionGroup(ReportMeasurementData.collectionName)
        .get();

    return query.docs.map(ReportMeasurementData.fromDocument).toList();
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
    final contractId = report.contractId?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório');
    }

    final ref = _col(contractId);

    final docRef = report.id != null && report.id!.trim().isNotEmpty
        ? ref.doc(report.id!.trim())
        : ref.doc();

    report.id = docRef.id;
    report.contractId = contractId;

    final existing = await docRef.get();

    final data = report.toFirestore()
      ..addAll({
        'id': docRef.id,
        'contractId': contractId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
      });

    final hasCreatedAt =
        existing.exists && existing.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = user?.uid ?? '';
    } else {
      data.remove('createdAt');
      data.remove('createdBy');
    }

    await docRef.set(data, SetOptions(merge: true));

    await _recalcularFinancialPercentage(contractId);

    /*
      IMPORTANTE:
      Não criar notificação aqui.

      A notificação correta já é criada na tela ReportMeasurement,
      usando NotificationMeasurements.show(...).

      O método legado _notificar() foi removido porque criava um segundo
      documento em users/{uid}/notifications com campos antigos:
      tipo, titulo, contractId, measurementId, seen.

      Esse documento antigo era o que aparecia no sino como "Notificação".
    */
  }

  Future<void> deleteMeasurement({
    required String contractId,
    required String measurementId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty || cleanMeasurementId.isEmpty) return;

    try {
      final folder = _storage.ref(
        'contracts/$cleanContractId/${ReportMeasurementData.collectionName}/$cleanMeasurementId/files',
      );

      final list = await folder.listAll();

      for (final item in list.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}

    await _col(cleanContractId).doc(cleanMeasurementId).delete();

    await _recalcularFinancialPercentage(cleanContractId);
  }

  // ---------------------------------------------------------------------------
  // Attachments
  // ---------------------------------------------------------------------------

  Future<Attachment> pickAndUploadAttachment({
    required String contractId,
    required String measurementId,
    void Function(double progress)? onProgress,
    String? forcedLabel,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMeasurementId = measurementId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para anexar arquivo.');
    }

    if (cleanMeasurementId.isEmpty) {
      throw Exception('measurementId é obrigatório para anexar arquivo.');
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado.');
    }

    final file = result.files.first;
    final Uint8List? bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Não foi possível ler o arquivo. Tente novamente.');
    }

    final ext = _safeExt(file.name);

    final label = forcedLabel?.trim().isNotEmpty == true
        ? forcedLabel!.trim()
        : _safeLabelFromName(file.name);

    final attachmentId = _db.collection('_').doc().id;

    final path = _storageFilePath(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      attachmentId: attachmentId,
      ext: ext,
    );

    final ref = _storageRef(path);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'contractId': cleanContractId,
          'measurementId': cleanMeasurementId,
          'attachmentId': attachmentId,
        },
      ),
    );

    task.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;

      if (total <= 0) return;

      final progress = snapshot.bytesTransferred / total;

      onProgress?.call(progress.clamp(0.0, 1.0));
    });

    await task;

    final url = await ref.getDownloadURL();

    final attachment = Attachment(
      id: attachmentId,
      label: label,
      url: url,
      path: path,
      ext: ext,
    );

    await _addAttachmentToMeasurementDoc(
      contractId: cleanContractId,
      measurementId: cleanMeasurementId,
      attachment: attachment,
    );

    return attachment;
  }

  Future<void> _addAttachmentToMeasurementDoc({
    required String contractId,
    required String measurementId,
    required Attachment attachment,
  }) async {
    final docRef = _measurementDoc(
      contractId: contractId,
      measurementId: measurementId,
    );

    await docRef.set({
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
      'contractId': contractId,
    }, SetOptions(merge: true));

    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    final raw = data['attachments'];

    final list = <Map<String, dynamic>>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }

    list.removeWhere((item) {
      return item['id']?.toString() == attachment.id;
    });

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
    final docRef = _measurementDoc(
      contractId: contractId,
      measurementId: measurementId,
    );

    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    final raw = data['attachments'];

    final list = <Map<String, dynamic>>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }

    list.removeWhere((item) {
      return item['id']?.toString() == attachment.id;
    });

    await docRef.set({
      'attachments': list.isEmpty ? FieldValue.delete() : list,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    }, SetOptions(merge: true));

    final path = attachment.path.trim();

    if (path.isNotEmpty) {
      try {
        await _storageRef(path).delete();
      } catch (_) {}
    }
  }

  Future<void> renameAttachmentLabel({
    required String contractId,
    required String measurementId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    final docRef = _measurementDoc(
      contractId: contractId,
      measurementId: measurementId,
    );

    final snap = await docRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    final raw = data['attachments'];

    final list = <Map<String, dynamic>>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }

    for (int i = 0; i < list.length; i++) {
      final id = list[i]['id']?.toString() ?? '';

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
  // PDF legado
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
  // Totais
  // ---------------------------------------------------------------------------

  double somarValorMedicoes(List<ReportMeasurementData> medicoes) {
    return medicoes.fold<double>(
      0.0,
          (total, medicao) => total + (medicao.value ?? 0.0),
    );
  }

  // ---------------------------------------------------------------------------
  // Percentual financeiro
  // ---------------------------------------------------------------------------

  Future<void> _recalcularFinancialPercentage(String contractId) async {
    double totalMedicoes = 0.0;

    final reportsSnapshot = await _col(contractId).get();

    for (final doc in reportsSnapshot.docs) {
      final value = doc.data()['value'];

      if (value is num) {
        totalMedicoes += value.toDouble();
      }
    }

    final contractSnap = await _db.collection('contracts').doc(contractId).get();

    final initialValue = contractSnap.data()?['initialContractValue'];

    final baseInicial = initialValue is num ? initialValue.toDouble() : 0.0;

    final additivesSnapshot = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();

    double totalAditivos = 0.0;

    for (final doc in additivesSnapshot.docs) {
      final value = doc.data()['additiveValue'];

      if (value is num) {
        totalAditivos += value.toDouble();
      }
    }

    final apostillesSnapshot = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .get();

    double totalApostilas = 0.0;

    for (final doc in apostillesSnapshot.docs) {
      final value = doc.data()['apostilleValue'];

      if (value is num) {
        totalApostilas += value.toDouble();
      }
    }

    final totalBase = baseInicial + totalAditivos + totalApostilas;

    final percent = totalBase > 0 ? (totalMedicoes / totalBase) * 100.0 : 0.0;

    await _db.collection('contracts').doc(contractId).set({
      'financialPercentage': percent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Itens da medição
  // ---------------------------------------------------------------------------

  Future<Map<String, Map<String, dynamic>>> loadItemsMap({
    required String contractId,
    required String measurementId,
  }) async {
    final snapshot = await _itemsCol(
      contractId: contractId,
      measurementId: measurementId,
    ).get();

    final output = <String, Map<String, dynamic>>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      output[doc.id] = {
        'qtyPrev': _asDouble(data['qtyPrev']),
        'qtyPeriod': _asDouble(data['qtyPeriod']),
        'qtyAccum': _asDouble(data['qtyAccum']),
        'qtyContractBal': _asDouble(data['qtyContractBal']),
        'valPrev': _asDouble(data['valPrev']),
        'valPeriod': _asDouble(data['valPeriod']),
        'valAccum': _asDouble(data['valAccum']),
        'valContractBal': _asDouble(data['valContractBal']),
        'updatedAt': data['updatedAt'],
        'updatedBy': data['updatedBy'],
        'budgetItemId': data['budgetItemId'] ?? doc.id,
      };
    }

    return output;
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

    await _itemsCol(
      contractId: contractId,
      measurementId: measurementId,
    ).doc(budgetItemId).set(data, SetOptions(merge: true));
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
  // Breakdown
  // ---------------------------------------------------------------------------

  Future<void> saveBreakdownDomain({
    required String contractId,
    required String measurementId,
    required BudgetData data,
  }) async {
    final metaRef = _measurementDoc(
      contractId: contractId,
      measurementId: measurementId,
    ).collection('breakdownMeta').doc('meta');

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

        final groupRef = groupsCol.doc(currentGroupId);

        pendingGroupSets.add(
          MapEntry(
            groupRef,
            {
              'order': entry.order,
              'title': entry.title,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          ),
        );
      } else if (entry is BudgetItem) {
        if (currentGroupId.isEmpty) {
          currentGroupOrder = 0;
          currentGroupId = '0';

          final groupRef = groupsCol.doc(currentGroupId);

          pendingGroupSets.add(
            MapEntry(
              groupRef,
              {
                'order': currentGroupOrder,
                'title': '',
                'updatedAt': FieldValue.serverTimestamp(),
              },
            ),
          );
        }

        final itemsCol = groupsCol.doc(currentGroupId).collection('items');

        final orderKey = _orderKeyFromCode(entry.code);

        final docId = ('${orderKey}_$runningIndex')
            .padRight(40, '0')
            .substring(0, 40);

        final fixedRow = List<String>.generate(
          data.schema.columns.length,
              (index) {
            return index < entry.values.length ? entry.values[index] : '';
          },
        );

        pendingItemSets.add(
          MapEntry(
            itemsCol.doc(docId),
            {
              'code': entry.code,
              'depth': entry.depth,
              'index': runningIndex,
              'orderKey': orderKey,
              'values': fixedRow,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          ),
        );

        runningIndex++;
      }
    }

    for (final chunk in _chunk(pendingGroupSets, _kMaxBatchOps)) {
      final batch = _db.batch();

      for (final item in chunk) {
        batch.set(item.key, item.value, SetOptions(merge: true));
      }

      await batch.commit();
    }

    for (final chunk in _chunk(pendingItemSets, _kMaxBatchOps)) {
      final batch = _db.batch();

      for (final item in chunk) {
        batch.set(item.key, item.value, SetOptions(merge: true));
      }

      await batch.commit();
    }

    final rowsCol = metaRef.collection('rows');

    final existingGroups = await rowsCol.get();

    for (final group in existingGroups.docs) {
      final items = await group.reference.collection('items').get();

      for (final chunk in _chunk(items.docs, _kMaxBatchOps)) {
        final batch = _db.batch();

        for (final doc in chunk) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      await group.reference.delete();
    }

    final batchGroups = _db.batch();

    for (final item in pendingGroupSets) {
      final groupId = item.key.id;
      final groupRef = rowsCol.doc(groupId);

      batchGroups.set(
        groupRef,
        {
          'order': item.value['order'],
          'title': item.value['title'],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batchGroups.commit();

    final byGroup = <String,
        List<MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>>>{};

    for (final item in pendingItemSets) {
      final groupId = item.key.parent.parent!.id;
      (byGroup[groupId] ??= []).add(item);
    }

    for (final entry in byGroup.entries) {
      final groupId = entry.key;
      final itemsCol = rowsCol.doc(groupId).collection('items');

      for (final chunk in _chunk(entry.value, _kMaxBatchOps)) {
        final batch = _db.batch();

        for (final item in chunk) {
          batch.set(
            itemsCol.doc(item.key.id),
            item.value,
            SetOptions(merge: true),
          );
        }

        await batch.commit();
      }
    }

    await metaRef.set({
      'activeWriteId': writeId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _cleanupOldBreakdownVersions(
      metaRef,
      keepLast: 2,
    );
  }

  Future<void> _cleanupOldBreakdownVersions(
      DocumentReference<Map<String, dynamic>> metaRef, {
        int keepLast = 2,
      }) async {
    final rowsVersions = await metaRef.collection('rows_v').get();

    if (rowsVersions.docs.length <= keepLast) return;

    final docs = rowsVersions.docs
      ..sort(
            (a, b) => a.id.compareTo(b.id),
      );

    final toDelete = docs.take(docs.length - keepLast).toList();

    for (final doc in toDelete) {
      final groups = await doc.reference.collection('groups').get();

      for (final group in groups.docs) {
        final items = await group.reference.collection('items').get();

        for (final chunk in _chunk(items.docs, _kMaxBatchOps)) {
          final batch = _db.batch();

          for (final item in chunk) {
            batch.delete(item.reference);
          }

          await batch.commit();
        }

        await group.reference.delete();
      }

      await doc.reference.delete();
    }
  }
}