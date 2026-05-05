import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
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
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _ordersCol(String contractId) {
    return _db.collection('contracts').doc(contractId).collection('orders');
  }

  DocumentReference<Map<String, dynamic>> _orderDoc({
    required String contractId,
    required String validityId,
  }) {
    return _ordersCol(contractId).doc(validityId);
  }

  // ---------------------------------------------------------------------------
  // Contratos
  // ---------------------------------------------------------------------------

  Future<List<ProcessData>> getAllContracts() async {
    final snapshot = await _db.collection('contracts').get();

    return snapshot.docs
        .map((doc) => ProcessData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<ProcessData?> getSpecificContract({required String uid}) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) return null;

    final snapshot = await _db.collection('contracts').doc(cleanUid).get();

    if (!snapshot.exists) return null;

    return ProcessData.fromDocument(snapshot: snapshot);
  }

  Future<ProcessData?> buscarContrato(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return null;

    final snapshot = await _db.collection('contracts').doc(cleanContractId).get();

    if (!snapshot.exists) return null;

    return ProcessData.fromDocument(snapshot: snapshot);
  }

  // ---------------------------------------------------------------------------
  // CRUD de vigências
  // ---------------------------------------------------------------------------

  Future<ValidityData> salvarOuAtualizarValidade(ValidityData data) async {
    final firebaseUser = _auth.currentUser;
    final uidContract = data.uidContract?.trim();

    if (uidContract == null || uidContract.isEmpty) {
      throw Exception('Contrato não informado');
    }

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
        'contractId': uidContract,
        'uidcontract': uidContract,
        'uidContract': uidContract,
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
    final contractId = uidContract.trim();
    final validityId = uidValidade.trim();

    if (contractId.isEmpty || validityId.isEmpty) return;

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
      final folder = _storage.ref('contracts/$contractId/orders/$validityId/');
      final result = await folder.listAll();

      for (final item in result.items) {
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}

    await docRef.delete();
  }

  Future<List<ValidityData>> getAllValidityOfContract({
    required String uidContract,
  }) async {
    final contractId = uidContract.trim();

    if (contractId.isEmpty) return const <ValidityData>[];

    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _ordersCol(contractId).orderBy('ordernumber').get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snapshot = await _ordersCol(contractId).get();
      } else {
        rethrow;
      }
    }

    final list = snapshot.docs
        .map((doc) => ValidityData.fromDocument(snapshot: doc))
        .toList();

    list.sort(
          (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
    );

    return list;
  }

  // ---------------------------------------------------------------------------
  // Notificações
  // ---------------------------------------------------------------------------

  Future<void> notificarUsuariosSobreValidade(
      ValidityData validade,
      String contractId,
      ) async {
    final currentUid = _auth.currentUser?.uid;

    if (currentUid == null) return;

    final ref = _db
        .collection('users')
        .doc(currentUid)
        .collection('notifications')
        .doc();

    await ref.set({
      'tipo': 'validade',
      'titulo': validade.ordertype ?? 'Vigência atualizada',
      'contractId': contractId,
      'validityId': validade.id,
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

        final tipo = data['tipo'];
        final contractId = data['contractId'];
        final validityId = data['validityId'];

        if (tipo != 'validade') continue;
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
            data: data['createdAt']?.toDate() ?? DateTime.now(),
            original: ValidityData.fromDocument(snapshot: originalSnap),
            contractData: await buscarContrato(contractId),
          ),
        );
      }

      return registros;
    });
  }

  // ---------------------------------------------------------------------------
  // Aditivos
  // ---------------------------------------------------------------------------

  Future<List<AdditivesData>> buscarAditivos(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) return const <AdditivesData>[];

    final snap = await _db
        .collection('contracts')
        .doc(cleanContractId)
        .collection('additives')
        .get();

    final list = snap.docs
        .map((doc) => AdditivesData.fromDocument(snapshot: doc))
        .toList();

    list.sort(
          (a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0),
    );

    return list;
  }

  // ---------------------------------------------------------------------------
  // Storage helpers
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

  String _storedFileName(String originalName) {
    final base = _sanitize(_baseName(originalName));
    final random = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final ext = _extFromName(originalName);

    return '$base-$random${ext.isEmpty ? ".bin" : ext}';
  }

  String _folderFor(ProcessData contract, ValidityData validity) {
    final contractId = contract.id?.trim();
    final validityId = validity.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      throw Exception('Contrato sem ID para operação de Storage.');
    }

    if (validityId == null || validityId.isEmpty) {
      throw Exception('Validade sem ID para operação de Storage.');
    }

    return 'contracts/$contractId/orders/$validityId/';
  }

  String _legacyFileName(
      ProcessData contract,
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
      ProcessData contract,
      ValidityData validity, {
        PublicacaoExtratoData? extrato,
      }) {
    return '${_folderFor(contract, validity)}${_legacyFileName(
      contract,
      validity,
      extrato: extrato,
    )}';
  }

  // ---------------------------------------------------------------------------
  // Multi-anexos
  // ---------------------------------------------------------------------------

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
    required ProcessData contract,
    required ValidityData validity,
    required Uint8List bytes,
    required String originalName,
    required String label,
    void Function(double progress)? onProgress,
  }) async {
    final dir = _folderFor(contract, validity);
    final fileName = _storedFileName(originalName);
    final ref = _storage.ref('$dir$fileName');
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
    final cleanContractId = contractId.trim();
    final cleanValidityId = validityId.trim();

    if (cleanContractId.isEmpty || cleanValidityId.isEmpty) {
      return const <({String name, String url})>[];
    }

    final folderRef = _storage.ref(
      'contracts/$cleanContractId/orders/$cleanValidityId/',
    );

    final result = await folderRef.listAll();

    final output = <({String name, String url})>[];

    for (final item in result.items) {
      try {
        final url = await item.getDownloadURL();

        output.add(
          (
          name: item.name,
          url: url,
          ),
        );
      } catch (_) {}
    }

    output.sort((a, b) => a.name.compareTo(b.name));

    return output;
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
    final cleanContractId = contractId.trim();
    final cleanValidityId = validityId.trim();

    if (cleanContractId.isEmpty || cleanValidityId.isEmpty) {
      throw Exception('contractId e validityId são obrigatórios.');
    }

    await _orderDoc(
      contractId: cleanContractId,
      validityId: cleanValidityId,
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
  }

  Future<List<Attachment>> loadAndEnsureAttachments({
    required ProcessData contract,
    required ValidityData validity,
  }) async {
    final contractId = contract.id?.trim();
    final validityId = validity.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      return const <Attachment>[];
    }

    if (validityId == null || validityId.isEmpty) {
      return const <Attachment>[];
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

      await _orderDoc(
        contractId: contractId,
        validityId: validityId,
      ).set(
        {
          'attachments': <Map<String, dynamic>>[attachment.toMap()],
          'pdfUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? '',
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
        path: 'contracts/$contractId/orders/$validityId/${file.name}',
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

  // ---------------------------------------------------------------------------
  // PDF legado
  // ---------------------------------------------------------------------------

  Future<String> uploadPdfBytes({
    required ProcessData contract,
    required ValidityData validity,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
    PublicacaoExtratoData? extrato,
  }) async {
    final ref = _storage.ref(
      _legacyPathFor(
        contract,
        validity,
        extrato: extrato,
      ),
    );

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

  Future<String> uploadPdfWithPickerAndReturnUrl({
    required ProcessData contract,
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
    required ProcessData contract,
    required ValidityData validity,
    required void Function(double) onProgress,
    required void Function(bool) onComplete,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      final contractId = contract.id?.trim();
      final validityId = validity.id?.trim();

      if (contractId == null || contractId.isEmpty) {
        onComplete(false);
        return false;
      }

      if (validityId == null || validityId.isEmpty) {
        onComplete(false);
        return false;
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
    final cleanContractId = contractId.trim();
    final cleanValidadeId = validadeId.trim();
    final cleanUrl = url.trim();

    if (cleanContractId.isEmpty || cleanValidadeId.isEmpty) {
      throw Exception('contractId e validadeId são obrigatórios.');
    }

    await _orderDoc(
      contractId: cleanContractId,
      validityId: cleanValidadeId,
    ).set(
      {
        'pdfUrl': cleanUrl.isEmpty ? FieldValue.delete() : cleanUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> deletePdf({
    required ProcessData contract,
    required ValidityData validity,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      final contractId = contract.id?.trim();
      final validityId = validity.id?.trim();

      if (contractId == null || contractId.isEmpty) return false;
      if (validityId == null || validityId.isEmpty) return false;

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

      await _orderDoc(
        contractId: contractId,
        validityId: validityId,
      ).set(
        {
          'pdfUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? '',
        },
        SetOptions(merge: true),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pdfExists({
    required ProcessData contract,
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
    required ProcessData contract,
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
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Cálculos de prazo
  // ---------------------------------------------------------------------------

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
          (soma, additive) {
        return soma + (additive.additiveValidityContractDays ?? 0);
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
          (soma, additive) {
        return soma + (additive.additiveValidityExecutionDays ?? 0);
      },
    );

    final totalDias =
        diasExecucaoInicial + diasExecucaoAditivos + diasParalisados;

    return ordemInicio.add(
      Duration(days: totalDias),
    );
  }
}