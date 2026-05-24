// lib/_blocs/modules/financial/payments/revision/revision_paid_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'revision_paid_data.dart';

class RevisionPaidRepository {
  RevisionPaidRepository({
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

    if (clean == null || clean.isEmpty) return null;

    return clean;
  }

  String get tenantId {
    final clean = _tenantId?.trim();

    if (clean == null || clean.isEmpty) {
      throw StateError(
        'tenantId não definido em RevisionPaidRepository. '
            'Selecione uma empresa antes de acessar pagamentos de revisão.',
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

  String get paymentsCollectionPath {
    return 'tenants/$tenantId/financial/payments/revision';
  }

  CollectionReference<Map<String, dynamic>> _paymentsCol() {
    return _db.collection(paymentsCollectionPath);
  }

  DocumentReference<Map<String, dynamic>> _paymentDoc({
    required String paymentId,
  }) {
    final cleanPaymentId = paymentId.trim();

    if (cleanPaymentId.isEmpty) {
      throw Exception('paymentId é obrigatório.');
    }

    return _paymentsCol().doc(cleanPaymentId);
  }

  String _uid() {
    return _auth.currentUser?.uid ?? '';
  }

  double _roundMoney(double value) {
    if (!value.isFinite) return 0.0;

    final rounded = (value * 100).roundToDouble() / 100;

    if (rounded == 0.0) return 0.0;

    return rounded;
  }

  bool _moneyGreaterThan(double left, double right) {
    return _roundMoney(left) > _roundMoney(right);
  }

  double _safePositive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return _roundMoney(v);
  }

  double totalPaymentValue(RevisionPaidData payment) {
    return _roundMoney(
      _safePositive(payment.paymentValue) +
          _safePositive(payment.inssPaymentValue) +
          _safePositive(payment.irpfPaymentValue) +
          _safePositive(payment.issPaymentValue),
    );
  }

  double mainPaymentValue(RevisionPaidData payment) {
    return _roundMoney(_safePositive(payment.paymentValue));
  }

  double retentionsValue(RevisionPaidData payment) {
    return _roundMoney(
      _safePositive(payment.inssPaymentValue) +
          _safePositive(payment.irpfPaymentValue) +
          _safePositive(payment.issPaymentValue),
    );
  }

  bool _sameText(String? a, String? b) {
    return (a ?? '').trim() == (b ?? '').trim();
  }

  bool _belongsToRevision({
    required RevisionPaidData payment,
    required String contractId,
    required String revisionId,
  }) {
    return _sameText(payment.contractId, contractId) &&
        _sameText(payment.revisionId, revisionId);
  }

  bool _belongsToContract({
    required RevisionPaidData payment,
    required String contractId,
  }) {
    return _sameText(payment.contractId, contractId);
  }

  void _sortByPaymentDateAndSource(List<RevisionPaidData> output) {
    output.sort((a, b) {
      final dateA = a.paymentDate ?? DateTime(1900);
      final dateB = b.paymentDate ?? DateTime(1900);

      final dateCompare = dateA.compareTo(dateB);

      if (dateCompare != 0) return dateCompare;

      final sourceA = a.fundingSourceLabel ?? '';
      final sourceB = b.fundingSourceLabel ?? '';

      return sourceA.toLowerCase().compareTo(sourceB.toLowerCase());
    });
  }

  void _sortByRevisionOrderAndDate(List<RevisionPaidData> output) {
    output.sort((a, b) {
      final orderA = a.revisionOrder ?? 0;
      final orderB = b.revisionOrder ?? 0;

      final orderCompare = orderA.compareTo(orderB);

      if (orderCompare != 0) return orderCompare;

      final dateA = a.paymentDate ?? DateTime(1900);
      final dateB = b.paymentDate ?? DateTime(1900);

      final dateCompare = dateA.compareTo(dateB);

      if (dateCompare != 0) return dateCompare;

      final sourceA = a.fundingSourceLabel ?? '';
      final sourceB = b.fundingSourceLabel ?? '';

      return sourceA.toLowerCase().compareTo(sourceB.toLowerCase());
    });
  }

  Future<List<RevisionPaidData>> getPaymentsByRevision({
    required String contractId,
    required String revisionId,
  }) async {
    if (!hasTenant) return const <RevisionPaidData>[];

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();

    if (cleanContractId.isEmpty || cleanRevisionId.isEmpty) {
      return const <RevisionPaidData>[];
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _paymentsCol()
          .where('contractId', isEqualTo: cleanContractId)
          .where('revisionId', isEqualTo: cleanRevisionId)
          .orderBy('paymentDate')
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snapshot = await _paymentsCol()
            .where('contractId', isEqualTo: cleanContractId)
            .where('revisionId', isEqualTo: cleanRevisionId)
            .get();
      } else {
        rethrow;
      }
    }

    final output = snapshot.docs
        .map(RevisionPaidData.fromDocument)
        .where(
          (payment) => _belongsToRevision(
        payment: payment,
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
      ),
    )
        .map(
          (payment) => payment.copyWith(
        contractId: cleanContractId,
        revisionId: cleanRevisionId,
      ),
    )
        .toList();

    _sortByPaymentDateAndSource(output);

    return output;
  }

  Future<List<RevisionPaidData>> getPaymentsByContract({
    required String contractId,
  }) async {
    if (!hasTenant) return const <RevisionPaidData>[];

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return const <RevisionPaidData>[];
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _paymentsCol()
          .where('contractId', isEqualTo: cleanContractId)
          .orderBy('revisionOrder')
          .orderBy('paymentDate')
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snapshot = await _paymentsCol()
            .where('contractId', isEqualTo: cleanContractId)
            .get();
      } else {
        rethrow;
      }
    }

    final output = snapshot.docs
        .map(RevisionPaidData.fromDocument)
        .where(
          (payment) => _belongsToContract(
        payment: payment,
        contractId: cleanContractId,
      ),
    )
        .map(
          (payment) => payment.copyWith(
        contractId: cleanContractId,
      ),
    )
        .toList();

    _sortByRevisionOrderAndDate(output);

    return output;
  }

  Future<void> saveOrUpdatePayment(
      RevisionPaidData data, {
        required double revisionValue,
      }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar pagamento.');
    }

    final contractId = data.contractId?.trim() ?? '';
    final revisionId = data.revisionId?.trim() ?? '';

    if (contractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar pagamento.');
    }

    if (revisionId.isEmpty) {
      throw Exception('revisionId é obrigatório para salvar pagamento.');
    }

    final ref = _paymentsCol();

    final docRef = data.id != null && data.id!.trim().isNotEmpty
        ? ref.doc(data.id!.trim())
        : ref.doc();

    data.id = docRef.id;
    data.contractId = contractId;
    data.revisionId = revisionId;

    await _assertPaymentLimit(
      contractId: contractId,
      revisionId: revisionId,
      editingPaymentId: docRef.id,
      newPaymentValue: totalPaymentValue(data),
      revisionValue: revisionValue,
    );

    final existing = await docRef.get();

    final payload = data.toFirestore()
      ..addAll({
        'id': docRef.id,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': contractId,
        'revisionId': revisionId,
        'uidContract': contractId,
        'uidcontract': contractId,
        'recordPath': docRef.path,
        'sourceCollectionModel': 'tenant_financial_payments_revision',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      });

    _applyNullableFieldDeletes(
      payload: payload,
      data: data,
    );

    final hasCreatedAt =
        existing.exists && existing.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['createdBy'] = _uid();
    } else {
      payload.remove('createdAt');
      payload.remove('createdBy');
    }

    await docRef.set(payload, SetOptions(merge: true));
  }

  void _applyNullableFieldDeletes({
    required Map<String, dynamic> payload,
    required RevisionPaidData data,
  }) {
    if (data.revisionOrder == null) {
      payload['revisionOrder'] = FieldValue.delete();
    }

    if (data.fundingSourceId == null || data.fundingSourceId!.trim().isEmpty) {
      payload['fundingSourceId'] = FieldValue.delete();
    }

    if (data.fundingSourceLabel == null ||
        data.fundingSourceLabel!.trim().isEmpty) {
      payload['fundingSourceLabel'] = FieldValue.delete();
    }

    if (data.paymentDate == null) {
      payload['paymentDate'] = FieldValue.delete();
    }

    if (data.paymentValue == null) {
      payload['paymentValue'] = FieldValue.delete();
    }

    if (data.inssPaymentDate == null) {
      payload['inssPaymentDate'] = FieldValue.delete();
    }

    if (data.inssPaymentValue == null) {
      payload['inssPaymentValue'] = FieldValue.delete();
    }

    if (data.irpfPaymentDate == null) {
      payload['irpfPaymentDate'] = FieldValue.delete();
    }

    if (data.irpfPaymentValue == null) {
      payload['irpfPaymentValue'] = FieldValue.delete();
    }

    if (data.issPaymentDate == null) {
      payload['issPaymentDate'] = FieldValue.delete();
    }

    if (data.issPaymentValue == null) {
      payload['issPaymentValue'] = FieldValue.delete();
    }

    if (data.note == null || data.note!.trim().isEmpty) {
      payload['note'] = FieldValue.delete();
    }

    if (data.attachments == null || data.attachments!.isEmpty) {
      payload['attachments'] = FieldValue.delete();
    }
  }

  Future<void> deletePayment({
    required String contractId,
    required String revisionId,
    required String paymentId,
  }) async {
    if (!hasTenant) return;

    final cleanPaymentId = paymentId.trim();

    if (cleanPaymentId.isEmpty) return;

    final deleteTasks = <Future<void>>[];

    try {
      final folder = _storage.ref(
        'tenants/$tenantId/financial/payments/revision/$cleanPaymentId/files',
      );

      final list = await folder.listAll();

      for (final item in list.items) {
        deleteTasks.add(
          item.delete().catchError((_) {}),
        );
      }
    } catch (_) {}

    if (deleteTasks.isNotEmpty) {
      await Future.wait(deleteTasks);
    }

    await _paymentDoc(paymentId: cleanPaymentId).delete();
  }

  Future<void> _assertPaymentLimit({
    required String contractId,
    required String revisionId,
    required String editingPaymentId,
    required double newPaymentValue,
    required double revisionValue,
  }) async {
    final cleanRevisionValue = _roundMoney(revisionValue);

    if (cleanRevisionValue <= 0) {
      throw Exception(
        'O valor da revisão precisa ser maior que zero para registrar pagamento.',
      );
    }

    final payments = await getPaymentsByRevision(
      contractId: contractId,
      revisionId: revisionId,
    );

    final cleanEditingPaymentId = editingPaymentId.trim();

    final totalWithoutCurrent = payments.fold<double>(
      0.0,
          (total, item) {
        final itemId = (item.id ?? '').trim();

        if (itemId == cleanEditingPaymentId) {
          return total;
        }

        return _roundMoney(total + totalPaymentValue(item));
      },
    );

    final cleanNewPaymentValue = _roundMoney(newPaymentValue);
    final nextTotal = _roundMoney(totalWithoutCurrent + cleanNewPaymentValue);

    if (_moneyGreaterThan(nextTotal, cleanRevisionValue)) {
      final remaining = _roundMoney(cleanRevisionValue - totalWithoutCurrent);

      throw Exception(
        'O total pago não pode ultrapassar o valor da revisão.\n'
            'Valor da revisão: ${cleanRevisionValue.toStringAsFixed(2)}\n'
            'Já pago nesta revisão: ${totalWithoutCurrent.toStringAsFixed(2)}\n'
            'Saldo disponível: ${remaining.toStringAsFixed(2)}\n'
            'Novo pagamento informado: ${cleanNewPaymentValue.toStringAsFixed(2)}\n'
            'Total após salvar: ${nextTotal.toStringAsFixed(2)}',
      );
    }
  }

  double sumPayments(
      List<RevisionPaidData> payments, {
        bool includeRetentions = false,
      }) {
    return payments.fold<double>(
      0.0,
          (total, item) {
        return _roundMoney(
          total +
              (includeRetentions
                  ? totalPaymentValue(item)
                  : mainPaymentValue(item)),
        );
      },
    );
  }

  double sumRetentions(List<RevisionPaidData> payments) {
    return payments.fold<double>(
      0.0,
          (total, item) => _roundMoney(total + retentionsValue(item)),
    );
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

  String _storageFilePath({
    required String paymentId,
    required String attachmentId,
    required String ext,
  }) {
    final cleanExt = ext.startsWith('.') ? ext : '.$ext';

    return 'tenants/$tenantId/'
        'financial/payments/revision/$paymentId/files/'
        '$attachmentId$cleanExt';
  }

  Reference _storageRef(String path) {
    return _storage.ref(path);
  }

  Future<Attachment> pickAndUploadAttachment({
    required String contractId,
    required String revisionId,
    required String paymentId,
    void Function(double progress)? onProgress,
    String? forcedLabel,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para anexar arquivo.');
    }

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para anexar arquivo.');
    }

    if (cleanRevisionId.isEmpty) {
      throw Exception('revisionId é obrigatório para anexar arquivo.');
    }

    if (cleanPaymentId.isEmpty) {
      throw Exception('paymentId é obrigatório para anexar arquivo.');
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
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

    final attachmentId = _paymentsCol().doc().id;

    final path = _storageFilePath(
      paymentId: cleanPaymentId,
      attachmentId: attachmentId,
      ext: ext,
    );

    final ref = _storageRef(path);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType:
        ext == '.pdf' ? 'application/pdf' : 'application/octet-stream',
        customMetadata: {
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'revisionId': cleanRevisionId,
          'paymentId': cleanPaymentId,
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
      createdAt: DateTime.now(),
      createdBy: _uid(),
    );

    await _addAttachmentToPaymentDoc(
      contractId: cleanContractId,
      revisionId: cleanRevisionId,
      paymentId: cleanPaymentId,
      attachment: attachment,
    );

    return attachment;
  }

  Future<void> _addAttachmentToPaymentDoc({
    required String contractId,
    required String revisionId,
    required String paymentId,
    required Attachment attachment,
  }) async {
    if (!hasTenant) return;

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanRevisionId.isEmpty ||
        cleanPaymentId.isEmpty) {
      return;
    }

    final docRef = _paymentDoc(paymentId: cleanPaymentId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
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

      transaction.set(
        docRef,
        {
          'attachments': list,
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'revisionId': cleanRevisionId,
          'uidContract': cleanContractId,
          'uidcontract': cleanContractId,
          'recordPath': docRef.path,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _uid(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> deleteAttachment({
    required String contractId,
    required String revisionId,
    required String paymentId,
    required Attachment attachment,
  }) async {
    if (!hasTenant) return;

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanRevisionId.isEmpty ||
        cleanPaymentId.isEmpty) {
      return;
    }

    final docRef = _paymentDoc(paymentId: cleanPaymentId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
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

      transaction.set(
        docRef,
        {
          'attachments': list.isEmpty ? FieldValue.delete() : list,
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'revisionId': cleanRevisionId,
          'uidContract': cleanContractId,
          'uidcontract': cleanContractId,
          'recordPath': docRef.path,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _uid(),
        },
        SetOptions(merge: true),
      );
    });

    final path = attachment.path.trim();

    if (path.isNotEmpty) {
      try {
        await _storageRef(path).delete();
      } catch (_) {}
    }
  }

  Future<void> renameAttachmentLabel({
    required String contractId,
    required String revisionId,
    required String paymentId,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    if (!hasTenant) return;

    final cleanContractId = contractId.trim();
    final cleanRevisionId = revisionId.trim();
    final cleanPaymentId = paymentId.trim();

    if (cleanContractId.isEmpty ||
        cleanRevisionId.isEmpty ||
        cleanPaymentId.isEmpty) {
      return;
    }

    final docRef = _paymentDoc(paymentId: cleanPaymentId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
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

      var replaced = false;

      for (int index = 0; index < list.length; index++) {
        final id = list[index]['id']?.toString() ?? '';

        if (id == oldItem.id) {
          list[index] = newItem.toMap();
          replaced = true;
          break;
        }
      }

      if (!replaced) {
        return;
      }

      transaction.set(
        docRef,
        {
          'attachments': list.isEmpty ? FieldValue.delete() : list,
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': cleanContractId,
          'revisionId': cleanRevisionId,
          'uidContract': cleanContractId,
          'uidcontract': cleanContractId,
          'recordPath': docRef.path,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _uid(),
        },
        SetOptions(merge: true),
      );
    });
  }
}