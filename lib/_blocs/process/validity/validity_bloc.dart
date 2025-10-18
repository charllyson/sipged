// ==============================
// lib/_blocs/process/contracts/validity/validity_bloc.dart
// ==============================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/process/additives/additive_data.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/validity/validity_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/registers/register_class.dart';

/// BLoC responsável por TUDO que é **Firestore** do módulo de validades.
/// (Upload/Storage foi movido para ValidityStorageBloc.)
class ValidityBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ValidityBloc();

  // ---------------------------------------------------------------------------
  // CONTRATOS (apoio)
  // ---------------------------------------------------------------------------

  Future<List<ContractData>> getAllContracts() async {
    final snapshot = await _db.collection('contracts').get();
    return snapshot.docs.map((doc) => ContractData.fromDocument(snapshot: doc)).toList();
  }

  Future<ContractData?> getSpecificContract({required String uid}) async {
    final snapshot = await _db.collection('contracts').doc(uid).get();
    if (!snapshot.exists) return null;
    return ContractData.fromDocument(snapshot: snapshot);
  }

  Future<ContractData?> buscarContrato(String contractId) async {
    final snapshot = await _db.collection('contracts').doc(contractId).get();
    if (!snapshot.exists) return null;
    return ContractData.fromDocument(snapshot: snapshot);
  }

  // ---------------------------------------------------------------------------
  // CRUD de Validades
  // ---------------------------------------------------------------------------

  Future<void> salvarOuAtualizarValidade(ValidityData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final uidContract = data.uidContract;
    if (uidContract == null) {
      throw Exception("Contrato não informado");
    }

    final ref = _db.collection('contracts').doc(uidContract).collection('orders');
    final docRef = (data.id != null) ? ref.doc(data.id) : ref.doc();
    data.id ??= docRef.id;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'contractId': uidContract,
      });

    final snapshot = await docRef.get();
    final hasCreatedAt = snapshot.exists && snapshot.data()?['createdAt'] != null;

    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));
    await notificarUsuariosSobreValidade(data, uidContract);
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

    return snapshot.docs.map((doc) => ValidityData.fromDocument(snapshot: doc)).toList();
  }

  // ---------------------------------------------------------------------------
  // Notificações (users/{uid}/notifications)
  // ---------------------------------------------------------------------------

  Future<void> notificarUsuariosSobreValidade(
      ValidityData validade, String contractId) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final List<String> uidsParaNotificar = [currentUid];

    final batch = _db.batch();
    for (final uid in uidsParaNotificar) {
      final ref = _db.collection('users').doc(uid).collection('notifications').doc();

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
  // Cálculos de prazo (contrato e execução)
  // ---------------------------------------------------------------------------

  Future<DateTime?> calcularDataFinalContrato({
    required ContractData contract,
  }) async {
    if (contract.id == null || contract.publicationDateDoe == null) return null;

    final additives = await _buscarAditivos(contract.id!);

    final diasValidadeInicial = contract.initialValidityContractDays ?? 0;
    final diasAditivos = additives.fold<int>(
      0, (soma, a) => soma + (a.additiveValidityContractDays ?? 0),
    );

    final totalDias = diasValidadeInicial + diasAditivos;
    return contract.publicationDateDoe!.add(Duration(days: totalDias));
  }

  Future<DateTime?> calcularDataFinalExecucao({
    required ContractData contract,
  }) async {
    if (contract.id == null) return null;

    final additives = await _buscarAditivos(contract.id!);
    final validities = await getAllValidityOfContract(uidContract: contract.id!);

    final ordemInicio = validities.firstWhere(
          (v) => (v.ordertype?.toUpperCase() ?? '').contains('INÍCIO'),
      orElse: () => ValidityData(orderdate: null),
    ).orderdate;

    if (ordemInicio == null) return null;

    final diasParalisados = calcularDiasParalisados(validities);
    final diasExecucaoInicial = contract.initialValidityExecutionDays ?? 0;
    final diasExecucaoAditivos = additives.fold<int>(
      0, (soma, a) => soma + (a.additiveValidityExecutionDays ?? 0),
    );

    final totalDiasExecucao =
        diasExecucaoInicial + diasExecucaoAditivos + diasParalisados;

    return ordemInicio.add(Duration(days: totalDiasExecucao));
  }

  int calcularDiasParalisados(List<ValidityData> validities) {
    int diasParalisados = 0;
    for (int i = 0; i < validities.length; i++) {
      final atual = validities[i];
      if ((atual.ordertype?.toUpperCase() ?? '').contains('REINÍCIO') && i > 0) {
        final anterior = validities[i - 1];
        if ((anterior.ordertype?.toUpperCase() ?? '').contains('PARALISA') &&
            atual.orderdate != null &&
            anterior.orderdate != null) {
          diasParalisados += atual.orderdate!.difference(anterior.orderdate!).inDays;
        }
      }
    }
    return diasParalisados;
  }

  Future<List<AdditiveData>> _buscarAditivos(String contractId) async {
    final snap = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .get();

    return snap.docs.map((doc) => AdditiveData.fromDocument(snapshot: doc)).toList();
  }

  // ---------------------------------------------------------------------------
  // 🆕 Anexos com rótulo (lista completa)
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
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
