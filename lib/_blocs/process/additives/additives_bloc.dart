// lib/_blocs/process/additives/additives_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_blocs/process/additives/additive_data.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/registers/register_class.dart';

// NOVO: status/labels vindos do DFD
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

class AdditivesBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DfdRepository _dfdRepo;

  AdditivesBloc({DfdRepository? dfdRepository})
      : _dfdRepo = dfdRepository ?? DfdRepository();

  // -----------------------------
  // Cache de status do DFD por contrato
  // -----------------------------
  final Map<String, String> _statusByContract = {};

  Future<void> _ensureStatusesForContracts(Iterable<ProcessData> contratos) async {
    final futures = <Future<void>>[];
    for (final c in contratos) {
      final id = _idToString(c.id);
      if (id == null || _statusByContract.containsKey(id)) continue;
      futures.add(() async {
        final leve = await _dfdRepo.readLightFields(id);
        final s = (leve.status ?? '').trim();
        if (s.isNotEmpty) _statusByContract[id] = s;
      }());
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  String? _getDfdStatusForId(String? contractId) {
    if (contractId == null) return null;
    final v = _statusByContract[contractId];
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  String? _idToString(Object? id) {
    if (id == null) return null;
    try {
      // se for um objeto com .id
      final dyn = id as dynamic;
      final hasIdProp = (() {
        try {
          return (dyn as dynamic).id is String;
        } catch (_) {
          return false;
        }
      })();
      if (hasIdProp) return (dyn as dynamic).id as String;
    } catch (_) {}
    return id.toString();
  }

  // -----------------------------
  // Listagens / consultas
  // -----------------------------
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

  Future<ProcessData?> buscarContrato(String contractId) async {
    final snap = await _db.collection('contracts').doc(contractId).get();
    if (!snap.exists) return null;
    return ProcessData.fromDocument(snapshot: snap);
  }

  // -----------------------------
  // Agregações (usando STATUS do DFD)
  // -----------------------------
  Future<double> getValorPorStatus(
      List<ProcessData> contratos,
      String statusDesejado,
      ) async {
    if (contratos.isEmpty) return 0.0;

    // garante cache de status do DFD
    await _ensureStatusesForContracts(contratos);

    final alvo = statusDesejado.trim().toUpperCase();

    // filtra pelos contratos cujo status (DFD) coincide
    final idsFiltrados = <String>{
      for (final c in contratos)
        if (_idToString(c.id) != null)
          if ((_getDfdStatusForId(_idToString(c.id)) ?? '').toUpperCase() == alvo)
            _idToString(c.id)!,
    };

    if (idsFiltrados.isEmpty) return 0.0;

    // soma valores dos aditivos dos contratos filtrados
    final totais = await Future.wait(idsFiltrados.map((contractId) async {
      try {
        final snap = await _db
            .collection('contracts')
            .doc(contractId)
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
        return 0.0;
      }
    }));

    return totais.fold<double>(0.0, (a, b) => a + b);
  }

  Future<double> somarValoresAditivosPorStatus({
    required List<ProcessData> contratos,
    required String status,
  }) async {
    if (contratos.isEmpty) return 0.0;

    // garante cache de status do DFD
    await _ensureStatusesForContracts(contratos);

    final alvo = status.trim().toUpperCase();
    double total = 0.0;

    // filtra pelos contratos cujo status (DFD) coincide
    final ids = <String>[
      for (final c in contratos)
        if (_idToString(c.id) != null)
          if ((_getDfdStatusForId(_idToString(c.id)) ?? '').toUpperCase() == alvo)
            _idToString(c.id)!,
    ];

    for (final contractId in ids) {
      final s = await _db
          .collection('contracts')
          .doc(contractId)
          .collection('additives')
          .get();

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

  // -----------------------------
  // CRUD aditivo
  // -----------------------------
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
    await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('additives')
        .doc(uidAditivo)
        .delete();
  }

  // -----------------------------
  // Attachments no doc do aditivo
  // -----------------------------
  Future<void> setAttachments({
    required String contractId,
    required String additiveId,
    required List<Attachment> attachments,
  }) async {
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('additives')
        .doc(additiveId)
        .set({
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
    }, SetOptions(merge: true));
  }

  // -----------------------------
  // Agregações (utilitários)
  // -----------------------------
  Future<double> getAllAdditivesValue(String contractId) async {
    final s = await _db.collection('contracts').doc(contractId).collection('additives').get();
    return s.docs.fold<double>(0.0, (sum, d) {
      final a = AdditiveData.fromDocument(snapshot: d);
      return sum + (a.additiveValue ?? 0.0);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
