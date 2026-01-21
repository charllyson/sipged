// lib/_blocs/modules/contracts/contracts/validity/validity_repository.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_storage_bloc.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/registers/register_class.dart';

class ValidityRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ValidityStorageBloc _storage;

  ValidityRepository({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    ValidityStorageBloc? storage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? ValidityStorageBloc();

  // ---------------------------------------------------------------------------
  // CONTRATOS (apoio)
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
  // CRUD de Validades
  // ---------------------------------------------------------------------------

  Future<ValidityData> salvarOuAtualizarValidade(ValidityData data) async {
    final firebaseUser = _auth.currentUser;
    final uidContract = data.uidContract;
    if (uidContract == null) {
      throw Exception("Contrato não informado");
    }

    final ref =
    _db.collection('contracts').doc(uidContract).collection('orders');
    final docRef = (data.id != null) ? ref.doc(data.id) : ref.doc();
    data.id ??= docRef.id;

    final Map<String, dynamic> json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'contractId': uidContract,
      });

    final snapshot = await docRef.get();
    final hasCreatedAt =
        snapshot.exists && (snapshot.data()?['createdAt'] != null);

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));

    // Recarrega o doc já convertido
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
  // Notificações (users/{uid}/notifications)
  // ---------------------------------------------------------------------------
  // OBS: se você já centralizou notificações no UserBloc/UserRepository,
  // pode chamar esse método de lá ou até remover daqui depois.

  Future<void> notificarUsuariosSobreValidade(
      ValidityData validade,
      String contractId,
      ) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    final List<String> uidsParaNotificar = [currentUid];

    final batch = _db.batch();
    for (final uid in uidsParaNotificar) {
      final ref =
      _db.collection('users').doc(uid).collection('notifications').doc();

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

  /// Caso ainda precise (mas ideal é centralizar em UserRepository/UserBloc).
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

        if (tipo == 'validade') {
          final originalSnap = await _db
              .collection('contracts')
              .doc(contractId)
              .collection('orders')
              .doc(idOriginal)
              .get();

          if (originalSnap.exists) {
            final original = ValidityData.fromDocument(snapshot: originalSnap);
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
  // Aditivos (apoio)
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
  // Anexos / Attachments
  // ---------------------------------------------------------------------------
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

  /// Carrega / migra anexos desta validade, retornando a lista final.
  ///
  /// 1) Se já houver `attachments` → retorna.
  /// 2) Se só tiver `pdfUrl` legado → cria Attachment único, persiste e retorna.
  /// 3) Se não tiver metadado → lista arquivos da pasta no Storage,
  ///    cria Attachments, salva e retorna.
  Future<List<Attachment>> loadAndEnsureAttachments({
    required ProcessData contract,
    required ValidityData validity,
  }) async {
    final contractId = contract.id;
    final validityId = validity.id;
    if (contractId == null || validityId == null) return const [];

    // 1) se já tem attachments no modelo em memória
    if ((validity.attachments ?? const []).isNotEmpty) {
      return List<Attachment>.from(validity.attachments!);
    }

    // 2) migração do pdfUrl legado
    if ((validity.pdfUrl ?? '').isNotEmpty) {
      final att = Attachment(
        id: 'legacy-pdf',
        label: 'Documento da validade',
        url: validity.pdfUrl!,
        path: '',
        ext: '.pdf',
        createdAt: DateTime.now(),
        createdBy: _auth.currentUser?.uid,
      );

      await setAttachments(
        contractId: contractId,
        validityId: validityId,
        attachments: [att],
      );

      validity
        ..attachments = [att]
        ..pdfUrl = null;

      return [att];
    }

    // 3) materializa arquivos existentes no Storage caso ainda não tenha meta
    final files = await _storage.listarArquivosDaValidade(
      contractId: contractId,
      validityId: validityId,
    );

    if (files.isEmpty) return const [];

    final list = files
        .map(
          (f) => Attachment(
        id: f.name,
        label:
        f.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
        url: f.url,
        path: 'contracts/$contractId/orders/$validityId/${f.name}',
        ext: RegExp(r'\.([a-z0-9]+)$', caseSensitive: false)
            .firstMatch(f.name)
            ?.group(0) ??
            '',
        createdAt: DateTime.now(),
        createdBy: _auth.currentUser?.uid,
      ),
    )
        .toList();

    await setAttachments(
      contractId: contractId,
      validityId: validityId,
      attachments: list,
    );

    validity.attachments = list;
    return list;
  }

  // ---------------------------------------------------------------------------
  // Upload / Delete PDF (com progresso) - usados pela camada de apresentação
  // ---------------------------------------------------------------------------
  Future<bool> uploadPdfWithProgress({
    required ProcessData contract,
    required ValidityData validity,
    required void Function(double) onProgress,
    required void Function(bool) onComplete,
  }) async {
    try {
      if (contract.id == null || validity.id == null) {
        onComplete(false);
        return false;
      }

      await _storage.sendPdf(
        contract: contract,
        validade: validity,
        onProgress: onProgress,
        onUploaded: (url) async {
          await _storage.salvarUrlPdfDaValidade(
            contractId: contract.id!,
            validadeId: validity.id!,
            url: url,
          );
        },
      );

      onComplete(true);
      return true;
    } catch (_) {
      onComplete(false);
      return false;
    }
  }

  Future<bool> deletePdf({
    required ProcessData contract,
    required ValidityData validity,
  }) async {
    try {
      if (contract.id == null || validity.id == null) return false;

      final ok = await _storage.delete(contract, validity);
      if (ok) {
        await _db
            .collection('contracts')
            .doc(contract.id)
            .collection('orders')
            .doc(validity.id)
            .update({'pdfUrl': FieldValue.delete()});
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pdfExists({
    required ProcessData contract,
    required ValidityData validity,
  }) {
    return _storage.verificarSePdfDeValidadeExiste(
      contract: contract,
      validade: validity,
    );
  }

  Future<String?> getPdfUrl({
    required ProcessData contract,
    required ValidityData validity,
  }) {
    return _storage.getPdfUrlDaValidade(
      contract: contract,
      validade: validity,
    );
  }

  // ---------------------------------------------------------------------------
  // Cálculos de prazo (PUROS) - não fazem I/O aqui dentro
  // ---------------------------------------------------------------------------
  int calcularDiasParalisados(List<ValidityData> validities) {
    int diasParalisados = 0;
    for (int i = 0; i < validities.length; i++) {
      final atual = validities[i];
      final tipoAtual = (atual.ordertype ?? '').toUpperCase();

      if (tipoAtual.contains('REINÍCIO') && i > 0) {
        final anterior = validities[i - 1];
        final tipoAnterior =
        (anterior.ordertype ?? '').toUpperCase();

        if (tipoAnterior.contains('PARALISA') &&
            atual.orderdate != null &&
            anterior.orderdate != null) {
          diasParalisados +=
              atual.orderdate!.difference(anterior.orderdate!).inDays;
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

    final diasValidadeInicial =
        contract.initialValidityContract ?? 0;
    final diasAditivos = additives.fold<int>(
      0,
          (soma, a) => soma + (a.additiveValidityContractDays ?? 0),
    );

    final totalDias = diasValidadeInicial + diasAditivos;
    return contract.publicationDate!.add(Duration(days: totalDias));
  }

  DateTime? calcularDataFinalExecucaoLocal({
    required ProcessData contract,
    required List<ValidityData> validities,
    required List<AdditivesData> additives,
  }) {
    final ordemInicio = validities
        .firstWhere(
          (v) =>
          ((v.ordertype ?? '').toUpperCase()).contains('INÍCIO'),
      orElse: () => ValidityData(orderdate: null),
    )
        .orderdate;

    if (ordemInicio == null) return null;

    final diasParalisados = calcularDiasParalisados(validities);
    final diasExecucaoInicial =
        contract.initialValidityExecution ?? 0;
    final diasExecucaoAditivos = additives.fold<int>(
      0,
          (soma, a) => soma + (a.additiveValidityExecutionDays ?? 0),
    );

    final total =
        diasExecucaoInicial + diasExecucaoAditivos + diasParalisados;
    return ordemInicio.add(Duration(days: total));
  }

  // ---------------------------------------------------------------------------
  // Upload genérico de arquivo (para multi-anexos) - usado pela camada superior
  // ---------------------------------------------------------------------------
  Future<(Uint8List, String)> pickFileBytes() => _storage.pickFileBytes();

  Future<Attachment> uploadAttachmentBytes({
    required ProcessData contract,
    required ValidityData validity,
    required Uint8List bytes,
    required String originalName,
    required String label,
  }) {
    return _storage.uploadAttachmentBytes(
      contract: contract,
      validity: validity,
      bytes: bytes,
      originalName: originalName,
      label: label,
    );
  }

  Future<void> deleteStorageByPath(String path) =>
      _storage.deleteStorageByPath(path);
}
