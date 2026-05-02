// lib/_blocs/modules/contracts/validity/validity_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/registers/register_class.dart';

class ValidityRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  ValidityRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // CONTRATOS
  // ---------------------------------------------------------------------------

  Future<List<ProcessData>> getAllContracts() async {
    final snapshot = await _db.collection('contracts').get();

    return snapshot.docs
        .map((doc) => ProcessData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<ProcessData?> getSpecificContract({required String uid}) async {
    final snapshot = await _db.collection('contracts').doc(uid).get();

    if (!snapshot.exists) return null;

    return ProcessData.fromDocument(snapshot: snapshot);
  }

  Future<ProcessData?> buscarContrato(String contractId) async {
    final snapshot = await _db.collection('contracts').doc(contractId).get();

    if (!snapshot.exists) return null;

    return ProcessData.fromDocument(snapshot: snapshot);
  }

  // ---------------------------------------------------------------------------
  // CRUD DE VALIDADES
  // ---------------------------------------------------------------------------

  Future<ValidityData> salvarOuAtualizarValidade(ValidityData data) async {
    final firebaseUser = _auth.currentUser;
    final uidContract = data.uidContract;

    if (uidContract == null || uidContract.isEmpty) {
      throw Exception('Contrato não informado');
    }

    final collectionRef = _db
        .collection('contracts')
        .doc(uidContract)
        .collection('orders');

    final docRef = data.id != null && data.id!.isNotEmpty
        ? collectionRef.doc(data.id)
        : collectionRef.doc();

    data.id ??= docRef.id;

    final snapshot = await docRef.get();

    final bool hasCreatedAt =
        snapshot.exists && snapshot.data()?['createdAt'] != null;

    final Map<String, dynamic> json = data.toJson()
      ..addAll({
        'id': docRef.id,
        'contractId': uidContract,
        'uidcontract': uidContract,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      });

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
    await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('orders')
        .doc(uidValidade)
        .delete();
  }

  Future<List<ValidityData>> getAllValidityOfContract({
    required String uidContract,
  }) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('orders')
        .orderBy('ordernumber')
        .get();

    return snapshot.docs
        .map((doc) => ValidityData.fromDocument(snapshot: doc))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // NOTIFICAÇÕES
  // ---------------------------------------------------------------------------

  Future<void> notificarUsuariosSobreValidade(
      ValidityData validade,
      String contractId,
      ) async {
    final currentUid = _auth.currentUser?.uid;

    if (currentUid == null) return;

    final List<String> uidsParaNotificar = <String>[currentUid];

    final batch = _db.batch();

    for (final uid in uidsParaNotificar) {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();

      batch.set(ref, {
        'tipo': 'validade',
        'titulo': validade.ordertype,
        'contractId': contractId,
        'validityId': validade.id,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

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

        final tipo = data['tipo'];
        final contractId = data['contractId'];
        final idOriginal = data['validityId'];

        if (tipo == 'validade' &&
            contractId is String &&
            idOriginal is String) {
          final originalSnap = await _db
              .collection('contracts')
              .doc(contractId)
              .collection('orders')
              .doc(idOriginal)
              .get();

          if (originalSnap.exists) {
            final original = ValidityData.fromDocument(
              snapshot: originalSnap,
            );

            registros.add(
              Registro(
                id: doc.id,
                tipo: tipo,
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

  // ---------------------------------------------------------------------------
  // ADITIVOS
  // ---------------------------------------------------------------------------

  Future<List<AdditivesData>> buscarAditivos(String contractId) async {
    final snap = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();

    return snap.docs
        .map((doc) => AdditivesData.fromDocument(snapshot: doc))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // STORAGE - HELPERS INTERNOS
  // ---------------------------------------------------------------------------

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');
  }

  String _extFromName(String name) {
    final match = RegExp(
      r'\.([a-z0-9]+)$',
      caseSensitive: false,
    ).firstMatch(name.trim());

    if (match == null) return '';

    return '.${match.group(1)!.toLowerCase()}';
  }

  String _baseName(String name) {
    String value = name.trim();

    final queryIndex = value.indexOf('?');
    if (queryIndex != -1) {
      value = value.substring(0, queryIndex);
    }

    final hashIndex = value.indexOf('#');
    if (hashIndex != -1) {
      value = value.substring(0, hashIndex);
    }

    value = value.split('/').last;

    return value.replaceAll(
      RegExp(r'\.[a-zA-Z0-9]+$'),
      '',
    );
  }

  String _storedFileName(String originalName) {
    final base = _sanitize(_baseName(originalName));

    final rnd = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');

    final ext = _extFromName(originalName);

    return '$base-$rnd${ext.isEmpty ? ".bin" : ext}';
  }

  String _folderFor(ProcessData contract, ValidityData validity) {
    final contractId = contract.id;
    final validityId = validity.id;

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
  // STORAGE - MULTI-ANEXOS
  // ---------------------------------------------------------------------------

  Future<(Uint8List, String)> pickFileBytes() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );

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

    final contentType = ext == '.pdf'
        ? 'application/pdf'
        : 'application/octet-stream';

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'originalName': originalName,
          'label': label,
        },
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });
    }

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
    final folderRef = _storage.ref(
      'contracts/$contractId/orders/$validityId/',
    );

    final result = await folderRef.listAll();

    final List<({String name, String url})> output = [];

    for (final item in result.items) {
      try {
        final url = await item.getDownloadURL();

        output.add(
          (
          name: item.name,
          url: url,
          ),
        );
      } catch (_) {
        // Ignora arquivos sem URL acessível.
      }
    }

    output.sort((a, b) => a.name.compareTo(b.name));

    return output;
  }

  Future<void> deleteStorageByPath(String path) async {
    if (path.trim().isEmpty) return;

    await _storage.ref(path).delete();
  }

  Future<void> setAttachments({
    required String contractId,
    required String validityId,
    required List<Attachment> attachments,
  }) async {
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('orders')
        .doc(validityId)
        .set({
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    }, SetOptions(merge: true));
  }

  Future<List<Attachment>> loadAndEnsureAttachments({
    required ProcessData contract,
    required ValidityData validity,
  }) async {
    final contractId = contract.id;
    final validityId = validity.id;

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

    final legacyPdfUrl = validity.pdfUrl ?? '';

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

      await setAttachments(
        contractId: contractId,
        validityId: validityId,
        attachments: <Attachment>[attachment],
      );

      validity
        ..attachments = <Attachment>[attachment]
        ..pdfUrl = null;

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
      ).firstMatch(file.name)?.group(0) ?? '';

      return Attachment(
        id: file.name,
        label: file.name.replaceAll(
          RegExp(r'\.[a-zA-Z0-9]+$'),
          '',
        ),
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
  // STORAGE - PDF LEGADO
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

    if (onProgress != null) {
      task.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });
    }

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
      final contractId = contract.id;
      final validityId = validity.id;

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
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('orders')
        .doc(validadeId)
        .update({
      'pdfUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid ?? '',
    });
  }

  Future<bool> deletePdf({
    required ProcessData contract,
    required ValidityData validity,
    PublicacaoExtratoData? extrato,
  }) async {
    try {
      final contractId = contract.id;
      final validityId = validity.id;

      if (contractId == null || contractId.isEmpty) return false;
      if (validityId == null || validityId.isEmpty) return false;

      await _storage
          .ref(
        _legacyPathFor(
          contract,
          validity,
          extrato: extrato,
        ),
      )
          .delete();

      await _db
          .collection('contracts')
          .doc(contractId)
          .collection('orders')
          .doc(validityId)
          .update({
        'pdfUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      });

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
  // CÁLCULOS DE PRAZO
  // ---------------------------------------------------------------------------

  int calcularDiasParalisados(List<ValidityData> validities) {
    int diasParalisados = 0;

    for (int i = 0; i < validities.length; i++) {
      final atual = validities[i];
      final tipoAtual = (atual.ordertype ?? '').toUpperCase();

      if (tipoAtual.contains('REINÍCIO') && i > 0) {
        final anterior = validities[i - 1];
        final tipoAnterior = (anterior.ordertype ?? '').toUpperCase();

        if (tipoAnterior.contains('PARALISA') &&
            atual.orderdate != null &&
            anterior.orderdate != null) {
          diasParalisados += atual.orderdate!
              .difference(anterior.orderdate!)
              .inDays;
        }
      }
    }

    return diasParalisados;
  }

  DateTime? calcularDataFinalContratoLocal({
    required ProcessData contract,
    required List<AdditivesData> additives,
  }) {
    if (contract.publicationDate == null) return null;

    final diasValidadeInicial = contract.initialValidityContract ?? 0;

    final diasAditivos = additives.fold<int>(
      0,
          (soma, additive) {
        return soma + (additive.additiveValidityContractDays ?? 0);
      },
    );

    final totalDias = diasValidadeInicial + diasAditivos;

    return contract.publicationDate!.add(
      Duration(days: totalDias),
    );
  }

  DateTime? calcularDataFinalExecucaoLocal({
    required ProcessData contract,
    required List<ValidityData> validities,
    required List<AdditivesData> additives,
  }) {
    final ordemInicio = validities
        .firstWhere(
          (validity) {
        return ((validity.ordertype ?? '').toUpperCase())
            .contains('INÍCIO');
      },
      orElse: () => ValidityData(orderdate: null),
    )
        .orderdate;

    if (ordemInicio == null) return null;

    final diasParalisados = calcularDiasParalisados(validities);

    final diasExecucaoInicial = contract.initialValidityExecution ?? 0;

    final diasExecucaoAditivos = additives.fold<int>(
      0,
          (soma, additive) {
        return soma + (additive.additiveValidityExecutionDays ?? 0);
      },
    );

    final totalDias = diasExecucaoInicial +
        diasExecucaoAditivos +
        diasParalisados;

    return ordemInicio.add(
      Duration(days: totalDias),
    );
  }
}