import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisged/_datas/documents/contracts/additive/additive_data.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_widgets/registers/register_class.dart';

class AdditivesBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AdditivesBloc();

  // -------- Queries/Agregações (somente dados) --------
  Future<List<AdditiveData>> getAdditivesByContractIds(Set<String> contractIds) async {
    final all = await getAllAdditives();
    return all.where((a) => contractIds.contains(a.contractId)).toList();
  }

  Future<List<AdditiveData>> getAllAdditives() async {
    final contratosSnapshot = await _db.collection('contracts').get();
    final List<AdditiveData> out = [];
    for (final c in contratosSnapshot.docs) {
      final snap = await c.reference.collection('additives').get();
      for (final doc in snap.docs) {
        out.add(AdditiveData.fromDocument(snapshot: doc));
      }
    }
    return out;
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
        if (data['tipo'] == 'aditivo') {
          final contractId = data['contractId'];
          final additiveId = data['additiveId'];

          final originalSnap = await _db
              .collection('contracts')
              .doc(contractId)
              .collection('additives')
              .doc(additiveId)
              .get();

          if (originalSnap.exists) {
            final original = AdditiveData.fromDocument(snapshot: originalSnap);
            registros.add(Registro(
              id: doc.id,
              tipo: 'aditivo',
              data: data['createdAt']?.toDate() ?? DateTime.now(),
              original: original,
              contractData: await buscarContrato(contractId),
            ));
          }
        }
      }
      return registros;
    });
  }

  Future<ContractData?> buscarContrato(String contractId) async {
    final snap = await _db.collection('contracts').doc(contractId).get();
    if (!snap.exists) return null;
    return ContractData.fromDocument(snapshot: snap);
  }

  /// Soma os valores de aditivos dos contratos cujo status == [statusDesejado].
  /// Aceita tanto o campo 'additivevalue' quanto 'additiveValue' no Firestore.
  Future<double> getValorPorStatus(
      List<ContractData> contratos,
      String statusDesejado,
      ) async {
    if (contratos.isEmpty) return 0.0;

    final alvo = statusDesejado.toUpperCase();
    final filtrados = contratos
        .where((c) =>
    (c.id?.isNotEmpty ?? false) &&
        ((c.contractStatus ?? '').toUpperCase() == alvo))
        .toList();

    if (filtrados.isEmpty) return 0.0;

    final totais = await Future.wait(filtrados.map((c) async {
      try {
        final snap = await _db
            .collection('contracts')
            .doc(c.id)
            .collection('additives')
            .get();

        return snap.docs.fold<double>(0.0, (sum, doc) {
          final data = doc.data();
          final raw = data['additivevalue'] ?? data['additiveValue'];
          num? n;
          if (raw is num) {
            n = raw;
          } else if (raw is String) {
            n = num.tryParse(raw);
          }
          return sum + (n?.toDouble() ?? 0.0);
        });
      } catch (_) {
        // Em caso de erro ao ler um contrato, ignora e considera 0
        return 0.0;
      }
    }));

    return totais.fold<double>(0.0, (a, b) => a + b);
  }


  Future<double> somarValoresAditivosPorStatus({
    required List<ContractData> contratos,
    required String status,
  }) async {
    double total = 0.0;
    final filtrados = contratos.where((c) => c.contractStatus == status).toList();
    for (final c in filtrados) {
      final s = await _db.collection('contracts').doc(c.id).collection('additives').get();
      for (final d in s.docs) {
        final a = AdditiveData.fromDocument(snapshot: d);
        total += (a.additiveValue ?? 0.0);
      }
    }
    return total;
  }

  Future<List<AdditiveData>> getAllAdditivesOfContract({required String uidContract}) async {
    final s = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('additives')
        .orderBy('additiveorder')
        .get();
    return s.docs.map((d) => AdditiveData.fromDocument(snapshot: d)).toList();
  }

  Future<void> salvarOuAtualizarAditivo(AdditiveData data, String uidContract) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final ref = _db.collection('contracts').doc(uidContract).collection('additives');
    final docRef = data.id != null ? ref.doc(data.id) : ref.doc();
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
    await _notificarUsuariosSobreAditivo(data, uidContract);
  }

  Future<void> _notificarUsuariosSobreAditivo(AdditiveData aditivo, String contractId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = _db.batch();
    final ref = _db.collection('users').doc(uid).collection('notifications').doc();
    batch.set(ref, {
      'tipo': 'aditivo',
      'titulo': 'Novo aditivo nº ${aditivo.additiveOrder}',
      'contractId': contractId,
      'additiveId': aditivo.id,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
    await batch.commit();
  }

  Future<void> deleteAdditive(String uidContract, String uidAditivo) async {
    await _db.collection('contracts').doc(uidContract).collection('additives').doc(uidAditivo).delete();
  }

  Future<double> getAllAdditivesValue(String contractId) async {
    final s = await _db.collection('contracts').doc(contractId).collection('additives').get();
    return s.docs.fold<double>(0.0, (sum, d) {
      final a = AdditiveData.fromDocument(snapshot: d);
      return sum + (a.additiveValue ?? 0.0);
    });
  }
}
