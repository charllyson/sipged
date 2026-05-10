import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'adjustment_measurement_data.dart';

class AdjustmentMeasurementRepository {
  AdjustmentMeasurementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    String? tenantId,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _tenantId = _cleanTenantId(tenantId);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String? _tenantId;

  static String? _cleanTenantId(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  String get tenantId {
    final clean = _tenantId?.trim();

    if (clean == null || clean.isEmpty) {
      throw StateError(
        'tenantId não definido em AdjustmentMeasurementRepository. '
            'Selecione uma empresa antes de acessar reajustes.',
      );
    }

    return clean;
  }

  String? get currentTenantId => _cleanTenantId(_tenantId);

  bool get hasTenant => currentTenantId != null;

  void setActiveTenantId(String? value) {
    final next = _cleanTenantId(value);

    if (_tenantId == next) return;

    _tenantId = next;
  }

  String get tenantContractsCollectionPath {
    return 'tenants/$tenantId/contracts';
  }

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    return _db.collection(tenantContractsCollectionPath);
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    return _contractsCol().doc(contractId.trim());
  }

  CollectionReference<Map<String, dynamic>> _col(String contractId) {
    return _contractDoc(contractId).collection(
      AdjustmentMeasurementData.collectionName,
    );
  }

  DocumentReference<Map<String, dynamic>> _doc({
    required String contractId,
    required String adjustmentId,
  }) {
    return _col(contractId).doc(adjustmentId.trim());
  }

  String _uid() {
    return _auth.currentUser?.uid ?? '';
  }

  bool _isTenantAdjustmentPath(String path) {
    final parts = path
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length < 6) return false;

    return parts[0] == 'tenants' &&
        parts[1] == tenantId &&
        parts[2] == 'contracts' &&
        parts[4] == AdjustmentMeasurementData.collectionName;
  }

  Future<List<AdjustmentMeasurementData>> getAllAdjustmentsOfContract({
    required String uidContract,
  }) async {
    if (!hasTenant) return const <AdjustmentMeasurementData>[];

    final contractId = uidContract.trim();

    if (contractId.isEmpty) return const <AdjustmentMeasurementData>[];

    QuerySnapshot<Map<String, dynamic>> qs;

    try {
      qs = await _col(contractId).orderBy('order').get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        qs = await _col(contractId).get();
      } else {
        rethrow;
      }
    }

    final list = qs.docs.map(AdjustmentMeasurementData.fromDocument).toList();

    list.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    return list;
  }

  Future<List<AdjustmentMeasurementData>>
  getAllAdjustmentsCollectionGroup() async {
    if (!hasTenant) return const <AdjustmentMeasurementData>[];

    QuerySnapshot<Map<String, dynamic>> qs;

    try {
      qs = await _db
          .collectionGroup(AdjustmentMeasurementData.collectionName)
          .where('tenantId', isEqualTo: tenantId)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        qs = await _db
            .collectionGroup(AdjustmentMeasurementData.collectionName)
            .get();
      } else {
        rethrow;
      }
    }

    final list = qs.docs
        .where((doc) => _isTenantAdjustmentPath(doc.reference.path))
        .map(AdjustmentMeasurementData.fromDocument)
        .toList();

    list.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    return list;
  }

  Future<void> saveOrUpdateAdjustment({
    required String contractId,
    required AdjustmentMeasurementData adj,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar reajuste.');
    }

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar reajuste.');
    }

    final docRef = adj.id?.trim().isNotEmpty == true
        ? _doc(
      contractId: cleanContractId,
      adjustmentId: adj.id!.trim(),
    )
        : _col(cleanContractId).doc();

    final adjustmentId = docRef.id;
    final existing = await docRef.get();

    final data = adj
        .copyWith(
      id: adjustmentId,
      contractId: cleanContractId,
    )
        .toFirestore()
      ..addAll({
        'id': adjustmentId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'recordPath': docRef.path,
        'sourceCollectionModel': 'tenant_contract_adjustments_measurement',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      });

    final hasCreatedAt =
        existing.exists && existing.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = _uid();
    } else {
      data.remove('createdAt');
      data.remove('createdBy');
    }

    await docRef.set(data, SetOptions(merge: true));

    await _recalcularFinancialPercentage(cleanContractId);
  }

  Future<void> deleteAdjustment({
    required String contractId,
    required String adjustmentId,
  }) async {
    if (!hasTenant) return;

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) return;

    final docRef = _doc(
      contractId: cleanContractId,
      adjustmentId: cleanAdjustmentId,
    );

    final snap = await docRef.get();
    final data = snap.data();

    if (data != null) {
      final raw = data['attachments'];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final att = Attachment.fromMap(
              Map<String, dynamic>.from(item),
            );

            if (att.path.trim().isNotEmpty) {
              await deleteStorageByPath(att.path);
            }
          }
        }
      }
    }

    try {
      final folder = _storage.ref(
        'tenants/$tenantId/contracts/$cleanContractId/'
            '${AdjustmentMeasurementData.collectionName}/$cleanAdjustmentId/attachments',
      );

      final list = await folder.listAll();

      for (final item in list.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}

    await docRef.delete();

    await _recalcularFinancialPercentage(cleanContractId);
  }

  Future<void> salvarUrlPdfDaAdjustmentMeasurement({
    required String contractId,
    required String adjustmentId,
    required String url,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar PDF do reajuste.');
    }

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();
    final cleanUrl = url.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) return;

    final docRef = _doc(
      contractId: cleanContractId,
      adjustmentId: cleanAdjustmentId,
    );

    await docRef.set(
      {
        'pdfUrl': cleanUrl.isEmpty ? FieldValue.delete() : cleanUrl,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setAttachments({
    required String contractId,
    required String adjustmentId,
    required List<Attachment> attachments,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar anexos.');
    }

    final cleanContractId = contractId.trim();
    final cleanAdjustmentId = adjustmentId.trim();

    if (cleanContractId.isEmpty || cleanAdjustmentId.isEmpty) {
      throw Exception('contractId e adjustmentId são obrigatórios.');
    }

    final docRef = _doc(
      contractId: cleanContractId,
      adjustmentId: cleanAdjustmentId,
    );

    await docRef.set(
      {
        'attachments': attachments.isEmpty
            ? FieldValue.delete()
            : attachments.map((item) => item.toMap()).toList(),
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidContract': cleanContractId,
        'uidcontract': cleanContractId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );
  }

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');
  }

  String fileName(
      ContractData contract,
      AdjustmentMeasurementData adjustment, {
        PublicacaoExtratoData? extrato,
      }) {
    final contrato = _sanitize(
      extrato?.numeroContrato?.trim().isNotEmpty == true
          ? extrato!.numeroContrato!
          : 'contrato',
    );

    final ordem = (adjustment.order ?? 0).toString();
    final processo = _sanitize(adjustment.numberprocess ?? 'processo');

    return 'adjustment-$contrato-$ordem-$processo.pdf';
  }

  String pathFor({
    required ContractData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) {
    final contractId = contract.id?.trim();

    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para PDF de reajuste.');
    }

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contract.id é obrigatório para PDF de reajuste.');
    }

    return 'tenants/$tenantId/contracts/$contractId/'
        '${AdjustmentMeasurementData.collectionName}/$measurementId/'
        '${fileName(contract, adj, extrato: extrato)}';
  }

  String attachmentsDir(
      ContractData contract,
      AdjustmentMeasurementData adjustment,
      ) {
    final contractId = contract.id?.trim();
    final adjustmentId = adjustment.id?.trim();

    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para anexos de reajuste.');
    }

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contract.id é obrigatório para anexos de reajuste.');
    }

    if (adjustmentId == null || adjustmentId.isEmpty) {
      throw Exception('adjustment.id é obrigatório para anexos de reajuste.');
    }

    return 'tenants/$tenantId/contracts/$contractId/'
        '${AdjustmentMeasurementData.collectionName}/$adjustmentId/attachments';
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

  Future<(Uint8List bytes, String originalName)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo selecionado ou arquivo vazio.');
    }

    return (result.files.single.bytes!, result.files.single.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ContractData contract,
    required AdjustmentMeasurementData adjustment,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = attachmentsDir(contract, adjustment);
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final ext = _extFromName(originalName);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType:
        ext == '.pdf' ? 'application/pdf' : 'application/octet-stream',
        customMetadata: {
          'tenantId': tenantId,
          'originalName': originalName,
          'contractId': contract.id ?? '',
          'adjustmentId': adjustment.id ?? '',
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
      createdBy: _uid(),
    );
  }

  Future<void> deleteStorageByPath(String storagePath) async {
    final cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) return;

    try {
      await _storage.ref(cleanPath).delete();
    } catch (_) {}
  }

  Future<void> renameAttachmentLabel({
    required String contractId,
    required String adjustmentId,
    required List<Attachment> attachments,
  }) async {
    await setAttachments(
      contractId: contractId,
      adjustmentId: adjustmentId,
      attachments: attachments,
    );
  }

  Future<void> deleteAttachment({
    required String contractId,
    required String adjustmentId,
    required Attachment attachment,
    required List<Attachment> nextAttachments,
  }) async {
    if (attachment.path.trim().isNotEmpty) {
      await deleteStorageByPath(attachment.path);
    }

    await setAttachments(
      contractId: contractId,
      adjustmentId: adjustmentId,
      attachments: nextAttachments,
    );
  }

  double sumAdjustments(List<AdjustmentMeasurementData> items) {
    double total = 0.0;

    for (final item in items) {
      total += item.value ?? 0.0;
    }

    return total;
  }

  Future<bool> exists({
    required ContractData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      await _storage
          .ref(
        pathFor(
          contract: contract,
          measurementId: measurementId,
          adj: adj,
          extrato: extrato,
        ),
      )
          .getMetadata();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getUrl({
    required ContractData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      return await _storage
          .ref(
        pathFor(
          contract: contract,
          measurementId: measurementId,
          adj: adj,
          extrato: extrato,
        ),
      )
          .getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String> uploadWithPicker({
    required ContractData contract,
    required String adjustmentId,
    required AdjustmentMeasurementData adj,
    required void Function(double progress) onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para upload de PDF de reajuste.');
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo PDF selecionado ou arquivo vazio.');
    }

    final ref = _storage.ref(
      pathFor(
        contract: contract,
        measurementId: adjustmentId,
        adj: adj,
        extrato: extrato,
      ),
    );

    final task = ref.putData(
      result.files.single.bytes!,
      SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'tenantId': tenantId,
          'contractId': contract.id ?? '',
          'adjustmentId': adjustmentId,
        },
      ),
    );

    task.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        onProgress(event.bytesTransferred / event.totalBytes);
      }
    });

    await task;

    return ref.getDownloadURL();
  }

  Future<bool> delete({
    required ContractData contract,
    required String measurementId,
    required AdjustmentMeasurementData adj,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      await _storage
          .ref(
        pathFor(
          contract: contract,
          measurementId: measurementId,
          adj: adj,
          extrato: extrato,
        ),
      )
          .delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> salvarUrlPdfDoAdjustment({
    required String contractId,
    required String adjustmentId,
    required String url,
  }) async {
    try {
      await salvarUrlPdfDaAdjustmentMeasurement(
        contractId: contractId,
        adjustmentId: adjustmentId,
        url: url,
      );
    } catch (_) {}
  }

  Future<void> _recalcularFinancialPercentage(String contractId) async {
    if (!hasTenant) return;

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return;

    double total = 0.0;

    final reps = await _contractDoc(cleanContractId)
        .collection('reportsMeasurement')
        .get();

    for (final doc in reps.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final adjs = await _contractDoc(cleanContractId)
        .collection(AdjustmentMeasurementData.collectionName)
        .get();

    for (final doc in adjs.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final revs = await _contractDoc(cleanContractId)
        .collection('revisionsMeasurement')
        .get();

    for (final doc in revs.docs) {
      final value = doc.data()['value'];
      total += value is num ? value.toDouble() : 0.0;
    }

    final contractSnap = await _contractDoc(cleanContractId).get();
    final initialValue = contractSnap.data()?['initialContractValue'];
    final baseInicial = initialValue is num ? initialValue.toDouble() : 0.0;

    final adds = await _contractDoc(cleanContractId).collection('additives').get();

    double totalAditivos = 0.0;

    for (final doc in adds.docs) {
      final value = doc.data()['additiveValue'] ?? doc.data()['additivevalue'];
      totalAditivos += value is num ? value.toDouble() : 0.0;
    }

    final apos =
    await _contractDoc(cleanContractId).collection('apostilles').get();

    double totalApostilas = 0.0;

    for (final doc in apos.docs) {
      final value =
          doc.data()['apostilleValue'] ?? doc.data()['apostillevalue'];
      totalApostilas += value is num ? value.toDouble() : 0.0;
    }

    final totalBase = baseInicial + totalAditivos + totalApostilas;

    final percent = totalBase > 0 ? (total / totalBase) * 100.0 : 0.0;

    await _contractDoc(cleanContractId).set(
      {
        'financialPercentage': percent,
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}