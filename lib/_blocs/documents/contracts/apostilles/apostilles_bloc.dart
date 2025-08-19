// lib/_blocs/documents/contracts/apostilles/apostilles_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../_datas/documents/contracts/apostilles/apostilles_data.dart';
import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_widgets/registers/register_class.dart';
import '../../../system/user_bloc.dart';

/// BLoC responsável por TUDO que é **Firestore** do módulo de apostilamentos.
/// (Upload/Storage foi movido para ApostillesStorageBloc.)
class ApostillesBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserBloc userBloc = UserBloc();

  ApostillesBloc();

  // ---------------------------------------------------------------------------
  // Listagem / consultas
  // ---------------------------------------------------------------------------

  Future<List<ApostillesData>> getAllApostilles() async {
    final query = await _db.collectionGroup('apostilles').get();
    return query.docs.map((doc) => ApostillesData.fromMap(doc.data())).toList();
  }

  Future<List<ApostillesData>> getAdditivesByContractIds(Set<String> contractIds) async {
    final all = await getAllApostilles();
    return all.where((a) => contractIds.contains(a.contractId)).toList();
  }

  Future<List<ApostillesData>> getAllApostillesOfContract({
    required String uidContract,
  }) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles')
        .orderBy('apostilleorder')
        .get();

    return snapshot.docs
        .map((doc) => ApostillesData.fromDocument(snapshot: doc))
        .toList();
  }

  Future<ContractData?> buscarContrato(String contractId) async {
    final snapshot = await _db.collection('contracts').doc(contractId).get();
    if (!snapshot.exists) return null;
    return ContractData.fromDocument(snapshot: snapshot);
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> saveOrUpdateApostille(ApostillesData data, String uidContract) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final ref = _db.collection('contracts').doc(uidContract).collection('apostilles');
    final docRef = data.id != null ? ref.doc(data.id) : ref.doc();
    data.id ??= docRef.id;

    final json = data.toJson()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
        'contractId': uidContract,
      });

    // Preserva createdAt/createdBy se já existir
    final snapshot = await docRef.get();
    final hasCreatedAt = snapshot.exists && snapshot.data()?['createdAt'] != null;
    if (!hasCreatedAt) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));

    // Notificação
    await notificarUsuariosSobreApostilamento(data, uidContract);
  }

  Future<void> deletarApostille(String uidContract, String uidApostille) async {
    await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles')
        .doc(uidApostille)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Notificações
  // ---------------------------------------------------------------------------

  Future<void> notificarUsuariosSobreApostilamento(
      ApostillesData apostila, String contractId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final List<String> uidsParaNotificar = [uid];
    final batch = _db.batch();

    for (final userId in uidsParaNotificar) {
      final ref = _db.collection('users').doc(userId).collection('notifications').doc();
      batch.set(ref, {
        'tipo': 'apostilamento',
        'titulo': 'Novo apostilamento nº ${apostila.apostilleOrder}',
        'contractId': contractId,
        'apostilleId': apostila.id,
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
        if (data['tipo'] != 'apostilamento') continue;

        final contractId = data['contractId'];
        final idOriginal = data['apostilleId'];

        final originalSnap = await _db
            .collection('contracts')
            .doc(contractId)
            .collection('apostilles')
            .doc(idOriginal)
            .get();

        if (originalSnap.exists) {
          final original = ApostillesData.fromDocument(snapshot: originalSnap);
          final contrato = await buscarContrato(contractId);

          registros.add(Registro(
            id: doc.id,
            tipo: 'apostilamento',
            data: data['createdAt']?.toDate() ?? DateTime.now(),
            original: original,
            contractData: contrato,
          ));
        }
      }

      return registros;
    });
  }

  // ---------------------------------------------------------------------------
  // Agregações
  // ---------------------------------------------------------------------------

  Future<double> getValorPorStatus(List<ContractData> contratos, String statusDesejado) async {
    final contratosFiltrados = contratos.where(
          (c) => (c.contractStatus ?? '').toUpperCase() == statusDesejado.toUpperCase(),
    ).toList();

    final futures = contratosFiltrados.map((contrato) async {
      final snapshot = await _db
          .collection('contracts')
          .doc(contrato.id)
          .collection('apostilles')
          .get();

      return snapshot.docs.fold<double>(0.0, (sum, doc) {
        final valor = doc.data()['apostillevalue'];
        return sum + (valor is num ? valor.toDouble() : 0.0);
      });
    });

    final resultados = await Future.wait(futures);
    return resultados.fold<double>(0.0, (a, b) => a + b);
  }

  Future<double> somarValoresApostilamentosPorStatus({
    required List<ContractData> contratos,
    required String status,
  }) async {
    double total = 0.0;

    for (final contrato in contratos) {
      if (contrato.contractStatus != status) continue;

      final apostillesSnapshot =
      await _db.collection('contracts').doc(contrato.id).collection('apostilles').get();

      for (final doc in apostillesSnapshot.docs) {
        final data = doc.data();
        final value = data['apostillevalue'] ?? 0.0;
        total += (value is int) ? value.toDouble() : (value is double ? value : 0.0);
      }
    }

    return total;
  }

  Future<double> getAllApostillesValue(String contractId) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .get();

    return snapshot.docs.fold<double>(0.0, (sum, doc) {
      final apostilles = ApostillesData.fromDocument(snapshot: doc);
      final valor = apostilles.apostilleValue ?? 0.0;
      return sum + valor;
    });
  }

  // ---------------------------------------------------------------------------
  // Migração (opcional)
  // ---------------------------------------------------------------------------

  Future<void> adicionarContractIdNasApostilas() async {
    final contratosSnapshot = await _db.collection('contracts').get();

    for (final contratoDoc in contratosSnapshot.docs) {
      final contractId = contratoDoc.id;
      final apostillesRef = contratoDoc.reference.collection('apostilles');
      final apostillesSnapshot = await apostillesRef.get();

      for (final apostilaDoc in apostillesSnapshot.docs) {
        final data = apostilaDoc.data();
        if (data.containsKey('contractId')) continue;

        await apostilaDoc.reference.update({'contractId': contractId});
        debugPrint('✅ Apostila ${apostilaDoc.id} atualizada com contractId: $contractId');
      }
    }

    debugPrint('✔️ Processo finalizado para apostilas.');
  }

  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    super.dispose();
  }
}
