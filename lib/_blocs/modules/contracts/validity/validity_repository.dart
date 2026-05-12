// lib/_blocs/modules/contracts/validity/validity_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/registers/register_class.dart';

class ValidityRepository {
  ValidityRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    required String tenantId,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _activeTenantId = _cleanRequiredTenantId(
          tenantId,
          context: 'ValidityRepository.constructor',
        );

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String _activeTenantId;

  static String _cleanRequiredTenantId(
      String value, {
        required String context,
      }) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError('tenantId é obrigatório em $context.');
    }

    return clean;
  }

  void setActiveTenantId(String tenantId) {
    _activeTenantId = _cleanRequiredTenantId(
      tenantId,
      context: 'ValidityRepository.setActiveTenantId',
    );
  }

  String _requireTenantId() {
    return _cleanRequiredTenantId(
      _activeTenantId,
      context: 'ValidityRepository._requireTenantId',
    );
  }

  CollectionReference<Map<String, dynamic>> _contractsCol() {
    final tenantId = _requireTenantId();

    return _db.collection('tenants').doc(tenantId).collection('contracts');
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório.');
    }

    return _contractsCol().doc(cleanContractId);
  }

  CollectionReference<Map<String, dynamic>> _ordersCol(String contractId) {
    return _contractDoc(contractId).collection(ValidityData.collectionName);
  }

  DocumentReference<Map<String, dynamic>> _orderDoc({
    required String contractId,
    required String validityId,
  }) {
    final cleanValidityId = validityId.trim();

    if (cleanValidityId.isEmpty) {
      throw Exception('validityId é obrigatório.');
    }

    return _ordersCol(contractId).doc(cleanValidityId);
  }

  CollectionReference<Map<String, dynamic>> _additivesCol(String contractId) {
    return _contractDoc(contractId).collection('additives');
  }

  String _uid() {
    return _auth.currentUser?.uid ?? '';
  }

  ContractData _fallbackContract(String contractId) {
    return ContractData(
      id: contractId.trim(),
      permissionContractId: const <String, Map<String, bool>>{},
      participantsInfo: const <String, Map<String, dynamic>>{},
    );
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
          final parsed = DateTime(year, month, day);

          if (parsed.day == day &&
              parsed.month == month &&
              parsed.year == year) {
            return parsed;
          }
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

  Future<List<ContractData>> getAllContracts() async {
    _requireTenantId();

    final snapshot = await _contractsCol().get();

    return snapshot.docs.map((doc) {
      if (!doc.exists) {
        return _fallbackContract(doc.id);
      }

      return ContractData.fromDocument(snapshot: doc);
    }).toList();
  }

  Future<ContractData?> getSpecificContract({required String uid}) async {
    _requireTenantId();

    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      throw Exception('contractId é obrigatório para buscar contrato.');
    }

    final snapshot = await _contractDoc(cleanUid).get();

    if (snapshot.exists) {
      return ContractData.fromDocument(snapshot: snapshot);
    }

    final ordersSnap = await _ordersCol(cleanUid).limit(1).get();

    if (ordersSnap.docs.isNotEmpty) {
      return _fallbackContract(cleanUid);
    }

    return _fallbackContract(cleanUid);
  }

  Future<ContractData?> buscarContrato(String contractId) async {
    _requireTenantId();

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para buscar contrato.');
    }

    final snapshot = await _contractDoc(cleanContractId).get();

    if (snapshot.exists) {
      return ContractData.fromDocument(snapshot: snapshot);
    }

    final ordersSnap = await _ordersCol(cleanContractId).limit(1).get();

    if (ordersSnap.docs.isNotEmpty) {
      return _fallbackContract(cleanContractId);
    }

    return _fallbackContract(cleanContractId);
  }

  Future<ValidityData> salvarOuAtualizarValidade(ValidityData data) async {
    final tenantId = _requireTenantId();
    final firebaseUser = _auth.currentUser;
    final uidContract = data.uidContract?.trim();

    if (uidContract == null || uidContract.isEmpty) {
      throw Exception('Contrato não informado');
    }

    final contractRef = _contractDoc(uidContract);

    await contractRef.set(
      <String, dynamic>{
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );

    final collectionRef = _ordersCol(uidContract);

    final docRef = data.id != null && data.id!.trim().isNotEmpty
        ? collectionRef.doc(data.id!.trim())
        : collectionRef.doc();

    final validityId = docRef.id;

    data.id = validityId;
    data.uidContract = uidContract;

    final snapshot = await docRef.get();

    final json = data.toJson()
      ..addAll({
        'id': validityId,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': uidContract,
        'uidcontract': uidContract,
        'uidContract': uidContract,
        'recordPath': docRef.path,
        'sourceCollectionModel': 'tenant_contract_orders',
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

    final updatedSnap = await docRef.get();

    return ValidityData.fromDocument(snapshot: updatedSnap);
  }

  Future<void> deletarValidade(String uidContract, String uidValidade) async {
    final tenantId = _requireTenantId();
    final contractId = uidContract.trim();
    final validityId = uidValidade.trim();

    if (contractId.isEmpty || validityId.isEmpty) {
      throw Exception('contractId e validityId são obrigatórios.');
    }

    final docRef = _orderDoc(
      contractId: contractId,
      validityId: validityId,
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
        'tenants/$tenantId/contracts/$contractId/orders/$validityId/',
      );

      final result = await folder.listAll();

      for (final item in result.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}

    await docRef.delete();

    await _contractDoc(contractId).set(
      <String, dynamic>{
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<ValidityData>> getAllValidityOfContract({
    required String uidContract,
  }) async {
    _requireTenantId();

    final contractId = uidContract.trim();

    if (contractId.isEmpty) {
      throw Exception('contractId é obrigatório para carregar vigências.');
    }

    final snapshot = await _ordersCol(contractId).orderBy('ordernumber').get();

    final list = snapshot.docs
        .map((doc) => ValidityData.fromDocument(snapshot: doc))
        .toList();

    list.sort(
          (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
    );

    return list;
  }

  Future<void> notificarUsuariosSobreValidade(
      ValidityData validade,
      String contractId,
      ) async {
    final tenantId = _requireTenantId();
    final currentUid = _auth.currentUser?.uid;

    if (currentUid == null) return;

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para notificar vigência.');
    }

    final ref = _db
        .collection('users')
        .doc(currentUid)
        .collection('notifications')
        .doc();

    await ref.set({
      'tipo': 'validade',
      'titulo': validade.ordertype ?? 'Vigência atualizada',
      'tenantId': tenantId,
      'companyId': tenantId,
      'contractId': cleanContractId,
      'validityId': validade.id,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  Stream<List<Registro>> getNotificacoesRecentesStream(String uid) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      throw Exception('uid é obrigatório para carregar notificações.');
    }

    return _db
        .collection('users')
        .doc(cleanUid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((snapshot) async {
      final tenantId = _requireTenantId();
      final registros = <Registro>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final tipo = data['tipo'];
        final contractId = data['contractId'];
        final validityId = data['validityId'];

        if (tipo != 'validade') continue;
        if (data['tenantId']?.toString() != tenantId) continue;
        if (contractId is! String || validityId is! String) continue;

        final originalSnap = await _orderDoc(
          contractId: contractId,
          validityId: validityId,
        ).get();

        if (!originalSnap.exists) continue;

        registros.add(
          Registro(
            id: doc.id,
            tipo: tipo.toString(),
            data: _toDateSafe(data['createdAt']) ?? DateTime.now(),
            original: ValidityData.fromDocument(snapshot: originalSnap),
            contractData: await buscarContrato(contractId),
          ),
        );
      }

      return registros;
    });
  }

  Future<List<AdditivesData>> buscarAditivos(String contractId) async {
    _requireTenantId();

    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      throw Exception('contractId é obrigatório para buscar aditivos.');
    }

    final snap = await _additivesCol(cleanContractId)
        .orderBy('additiveorder')
        .get();

    final list = snap.docs
        .map((doc) => AdditivesData.fromDocument(snapshot: doc))
        .toList();

    list.sort(
          (a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0),
    );

    return list;
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

  String _storedFileName(String originalName) {
    final base = _sanitize(_baseName(originalName));
    final random = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final ext = _extFromName(originalName);

    return '$base-$random${ext.isEmpty ? ".bin" : ext}';
  }

  String _folderFor(ContractData contract, ValidityData validity) {
    final tenantId = _requireTenantId();
    final contractId = contract.id?.trim();
    final validityId = validity.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato sem ID para operação de Storage.');
    }

    if (validityId == null || validityId.isEmpty) {
      throw Exception('Validade sem ID para operação de Storage.');
    }

    return 'tenants/$tenantId/contracts/$contractId/orders/$validityId/';
  }

  String _legacyFileName(
      ContractData contract,
      ValidityData validity, {
        PublicacaoExtratoData? extrato,
      }) {
    final contrato = _sanitize(
      extrato?.numeroContrato?.trim().isNotEmpty == true
          ? extrato!.numeroContrato!
          : 'contrato',
    );

    final ordem = (validity.orderNumber ?? 0).toString().padLeft(3, '0');

    final tipo = _sanitize(
      validity.ordertype?.trim().isNotEmpty == true
          ? validity.ordertype!
          : 'tipo',
    );

    return '$contrato-$ordem-$tipo.pdf';
  }

  String _legacyPathFor(
      ContractData contract,
      ValidityData validity, {
        PublicacaoExtratoData? extrato,
      }) {
    return '${_folderFor(contract, validity)}${_legacyFileName(
      contract,
      validity,
      extrato: extrato,
    )}';
  }

  Future<(Uint8List, String)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null || result.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado.');
    }

    final file = result.files.single;

    if (file.bytes == null || file.bytes!.isEmpty) {
      throw Exception('Arquivo vazio ou inválido.');
    }

    return (file.bytes!, file.name);
  }

  Future<Attachment> uploadAttachmentBytes({
    required ContractData contract,
    required ValidityData validity,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final tenantId = _requireTenantId();
    final dir = _folderFor(contract, validity);
    final fileName = _storedFileName(originalName);
    final ref = _storage.ref('$dir$fileName');
    final ext = _extFromName(originalName);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType:
        ext == '.pdf' ? 'application/pdf' : 'application/octet-stream',
        customMetadata: {
          'tenantId': tenantId,
          'companyId': tenantId,
          'originalName': originalName,
          'label': label,
          'contractId': contract.id ?? '',
          'validityId': validity.id ?? '',
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
    final metadata = await ref.getMetadata();

    return Attachment(
      id: ref.name,
      label: label.trim().isEmpty ? _baseName(originalName) : label.trim(),
      url: url,
      path: ref.fullPath,
      ext: ext,
      size: metadata.size?.toInt(),
      createdAt: DateTime.now(),
      createdBy: _auth.currentUser?.uid,
    );
  }

  Future<List<({String name, String url})>> listarArquivosDaValidade({
    required String contractId,
    required String validityId,
  }) async {
    final tenantId = _requireTenantId();
    final cleanContractId = contractId.trim();
    final cleanValidityId = validityId.trim();

    if (cleanContractId.isEmpty || cleanValidityId.isEmpty) {
      throw Exception('contractId e validityId são obrigatórios.');
    }

    final folderRef = _storage.ref(
      'tenants/$tenantId/contracts/$cleanContractId/orders/$cleanValidityId/',
    );

    final output = <({String name, String url})>[];

    final result = await folderRef.listAll();

    for (final item in result.items) {
      final url = await item.getDownloadURL();

      output.add(
        (
        name: item.name,
        url: url,
        ),
      );
    }

    final unique = <String, ({String name, String url})>{};

    for (final item in output) {
      unique[item.url] = item;
    }

    final list = unique.values.toList();

    list.sort((a, b) => a.name.compareTo(b.name));

    return list;
  }

  Future<void> deleteStorageByPath(String path) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) return;

    try {
      await _storage.ref(cleanPath).delete();
    } catch (_) {}
  }

  Future<void> setAttachments({
    required String contractId,
    required String validityId,
    required List<Attachment> attachments,
  }) async {
    final tenantId = _requireTenantId();
    final cleanContractId = contractId.trim();
    final cleanValidityId = validityId.trim();

    if (cleanContractId.isEmpty || cleanValidityId.isEmpty) {
      throw Exception('contractId e validityId são obrigatórios.');
    }

    final docRef = _orderDoc(
      contractId: cleanContractId,
      validityId: cleanValidityId,
    );

    await _contractDoc(cleanContractId).set(
      <String, dynamic>{
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );

    await docRef.set(
      {
        'attachments': attachments.isEmpty
            ? FieldValue.delete()
            : attachments.map((item) => item.toMap()).toList(),
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidcontract': cleanContractId,
        'uidContract': cleanContractId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<Attachment>> loadAndEnsureAttachments({
    required ContractData contract,
    required ValidityData validity,
  }) async {
    final tenantId = _requireTenantId();
    final contractId = contract.id?.trim();
    final validityId = validity.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para carregar anexos.');
    }

    if (validityId == null || validityId.isEmpty) {
      throw Exception('validityId é obrigatório para carregar anexos.');
    }

    final currentAttachments = validity.attachments ?? const <Attachment>[];

    if (currentAttachments.isNotEmpty) {
      return List<Attachment>.from(currentAttachments);
    }

    final legacyPdfUrl = validity.pdfUrl?.trim() ?? '';

    if (legacyPdfUrl.isNotEmpty) {
      final attachment = Attachment(
        id: 'legacy-pdf',
        label: 'Documento da validade',
        url: legacyPdfUrl,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: _auth.currentUser?.uid,
      );

      final orderRef = _orderDoc(
        contractId: contractId,
        validityId: validityId,
      );

      await orderRef.set(
        {
          'attachments': <Map<String, dynamic>>[attachment.toMap()],
          'pdfUrl': FieldValue.delete(),
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': contractId,
          'uidcontract': contractId,
          'uidContract': contractId,
          'recordPath': orderRef.path,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _uid(),
        },
        SetOptions(merge: true),
      );

      validity.attachments = <Attachment>[attachment];
      validity.pdfUrl = null;

      return <Attachment>[attachment];
    }

    final files = await listarArquivosDaValidade(
      contractId: contractId,
      validityId: validityId,
    );

    if (files.isEmpty) {
      return const <Attachment>[];
    }

    final list = files.map((file) {
      final ext = RegExp(
        r'\.([a-z0-9]+)$',
        caseSensitive: false,
      ).firstMatch(file.name)?.group(0) ??
          '';

      return Attachment(
        id: file.name,
        label: file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
        url: file.url,
        path:
        'tenants/$tenantId/contracts/$contractId/orders/$validityId/${file.name}',
        ext: ext,
        createdAt: DateTime.now(),
        createdBy: _auth.currentUser?.uid,
      );
    }).toList();

    await setAttachments(
      contractId: contractId,
      validityId: validityId,
      attachments: list,
    );

    validity.attachments = list;

    return list;
  }

  Future<String> uploadPdfBytes({
    required ContractData contract,
    required ValidityData validity,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    final tenantId = _requireTenantId();

    final ref = _storage.ref(
      _legacyPathFor(
        contract,
        validity,
        extrato: extrato,
      ),
    );

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': contract.id ?? '',
          'validityId': validity.id ?? '',
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

  Future<String> uploadPdfWithPickerAndReturnUrl({
    required ContractData contract,
    required ValidityData validity,
    required void Function(double progress) onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('Nenhum arquivo PDF selecionado.');
    }

    final file = result.files.single;

    if (file.bytes == null || file.bytes!.isEmpty) {
      throw Exception('Arquivo PDF vazio ou inválido.');
    }

    return uploadPdfBytes(
      contract: contract,
      validity: validity,
      bytes: file.bytes!,
      onProgress: onProgress,
      extrato: extrato,
    );
  }

  Future<bool> uploadPdfWithProgress({
    required ContractData contract,
    required ValidityData validity,
    required void Function(double) onProgress,
    required void Function(bool) onComplete,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      final contractId = contract.id?.trim();
      final validityId = validity.id?.trim();

      if (contractId == null || contractId.isEmpty) {
        throw Exception('contractId é obrigatório para upload de PDF.');
      }

      if (validityId == null || validityId.isEmpty) {
        throw Exception('validityId é obrigatório para upload de PDF.');
      }

      final url = await uploadPdfWithPickerAndReturnUrl(
        contract: contract,
        validity: validity,
        onProgress: onProgress,
        extrato: extrato,
      );

      await salvarUrlPdfDaValidade(
        contractId: contractId,
        validadeId: validityId,
        url: url,
      );

      onComplete(true);

      return true;
    } catch (_) {
      onComplete(false);
      return false;
    }
  }

  Future<void> salvarUrlPdfDaValidade({
    required String contractId,
    required String validadeId,
    required String url,
  }) async {
    final tenantId = _requireTenantId();
    final cleanContractId = contractId.trim();
    final cleanValidadeId = validadeId.trim();
    final cleanUrl = url.trim();

    if (cleanContractId.isEmpty || cleanValidadeId.isEmpty) {
      throw Exception('contractId e validadeId são obrigatórios.');
    }

    final docRef = _orderDoc(
      contractId: cleanContractId,
      validityId: cleanValidadeId,
    );

    await _contractDoc(cleanContractId).set(
      <String, dynamic>{
        'tenantId': tenantId,
        'companyId': tenantId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );

    await docRef.set(
      {
        'pdfUrl': cleanUrl.isEmpty ? FieldValue.delete() : cleanUrl,
        'tenantId': tenantId,
        'companyId': tenantId,
        'contractId': cleanContractId,
        'uidcontract': cleanContractId,
        'uidContract': cleanContractId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> deletePdf({
    required ContractData contract,
    required ValidityData validity,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      final tenantId = _requireTenantId();
      final contractId = contract.id?.trim();
      final validityId = validity.id?.trim();

      if (contractId == null || contractId.isEmpty) {
        throw Exception('contractId é obrigatório para excluir PDF.');
      }

      if (validityId == null || validityId.isEmpty) {
        throw Exception('validityId é obrigatório para excluir PDF.');
      }

      try {
        await _storage
            .ref(
          _legacyPathFor(
            contract,
            validity,
            extrato: extrato,
          ),
        )
            .delete();
      } catch (_) {}

      final docRef = _orderDoc(
        contractId: contractId,
        validityId: validityId,
      );

      await docRef.set(
        {
          'pdfUrl': FieldValue.delete(),
          'tenantId': tenantId,
          'companyId': tenantId,
          'contractId': contractId,
          'uidcontract': contractId,
          'uidContract': contractId,
          'recordPath': docRef.path,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _uid(),
        },
        SetOptions(merge: true),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pdfExists({
    required ContractData contract,
    required ValidityData validity,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      await _storage
          .ref(
        _legacyPathFor(
          contract,
          validity,
          extrato: extrato,
        ),
      )
          .getMetadata();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrl({
    required ContractData contract,
    required ValidityData validity,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      return await _storage
          .ref(
        _legacyPathFor(
          contract,
          validity,
          extrato: extrato,
        ),
      )
          .getDownloadURL();
    } catch (_) {}

    final contractId = contract.id?.trim();
    final validityId = validity.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('contractId é obrigatório para obter PDF.');
    }

    if (validityId == null || validityId.isEmpty) {
      throw Exception('validityId é obrigatório para obter PDF.');
    }

    final snap = await _orderDoc(
      contractId: contractId,
      validityId: validityId,
    ).get();

    final data = snap.data();

    return _stringOrNull(data?['pdfUrl']);
  }

  int calcularDiasParalisados(List<ValidityData> validities) {
    final sorted = List<ValidityData>.from(validities)
      ..sort(
            (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
      );

    int diasParalisados = 0;

    for (int i = 0; i < sorted.length; i++) {
      final atual = sorted[i];
      final tipoAtual = (atual.ordertype ?? '').toUpperCase();

      if (!tipoAtual.contains('REINÍCIO') || i <= 0) continue;

      final anterior = sorted[i - 1];
      final tipoAnterior = (anterior.ordertype ?? '').toUpperCase();

      if (!tipoAnterior.contains('PARALISA')) continue;
      if (atual.orderdate == null || anterior.orderdate == null) continue;

      final diff = atual.orderdate!.difference(anterior.orderdate!).inDays;

      if (diff > 0) {
        diasParalisados += diff;
      }
    }

    return diasParalisados;
  }

  int _toIntFromText(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) return 0;

    return int.tryParse(text.replaceAll(RegExp(r'[^\d-]'), '')) ?? 0;
  }

  DateTime? calcularDataFinalContratoLocal({
    required PublicacaoExtratoData? publicacao,
    required TrData? tr,
    required List<AdditivesData> additives,
  }) {
    final dataPublicacao = publicacao?.dataPublicacao;

    if (dataPublicacao == null) return null;

    final vigenciaDias = _toIntFromText(tr?.vigenciaDias);

    final diasAditivos = additives.fold<int>(
      0,
          (total, additive) {
        return total + (additive.additiveValidityContractDays ?? 0);
      },
    );

    final totalDiasContrato = vigenciaDias + diasAditivos;

    return dataPublicacao.add(
      Duration(days: totalDiasContrato),
    );
  }

  DateTime? calcularDataFinalExecucaoLocal({
    required TrData? tr,
    required List<ValidityData> validities,
    required List<AdditivesData> additives,
  }) {
    final sorted = List<ValidityData>.from(validities)
      ..sort(
            (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
      );

    final ordemInicio = sorted
        .firstWhere(
          (validity) {
        return (validity.ordertype ?? '').toUpperCase().contains('INÍCIO');
      },
      orElse: () => ValidityData(orderdate: null),
    )
        .orderdate;

    if (ordemInicio == null) return null;

    final diasParalisados = calcularDiasParalisados(sorted);
    final diasExecucaoInicial = _toIntFromText(tr?.prazoExecucaoDias);

    final diasExecucaoAditivos = additives.fold<int>(
      0,
          (total, additive) {
        return total + (additive.additiveValidityExecutionDays ?? 0);
      },
    );

    final totalDias =
        diasExecucaoInicial + diasExecucaoAditivos + diasParalisados;

    return ordemInicio.add(
      Duration(days: totalDias),
    );
  }
}