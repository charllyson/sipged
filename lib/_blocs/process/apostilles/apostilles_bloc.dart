// ==============================
// lib/_blocs/process/contracts/apostilles/apostilles_bloc.dart
// ==============================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_blocs/process/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/registers/register_class.dart';

// 🔹 NOVO: ler status (DFD.identificacao.statusContrato)
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

class ApostillesBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DfdRepository _dfdRepo;

  ApostillesBloc({DfdRepository? dfdRepository})
      : _dfdRepo = dfdRepository ?? DfdRepository();

  // ---------------------------------------------------------------------------
  // Cache de STATUS do DFD por contrato
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Listagem / consultas
  // ---------------------------------------------------------------------------

  Future<List<ApostillesData>> getAllApostilles() async {
    final query = await _db.collectionGroup('apostilles').get();
    return query.docs.map((doc) => ApostillesData.fromMap(doc.data(), id: doc.id)).toList();
  }

  // (nome mantido por compatibilidade)
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

  Future<ProcessData?> buscarContrato(String contractId) async {
    final snapshot = await _db.collection('contracts').doc(contractId).get();
    if (!snapshot.exists) return null;
    return ProcessData.fromDocument(snapshot: snapshot);
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

  // -----------------------------
  // Anexos com rótulo (lista completa)
  // -----------------------------
  Future<void> setAttachments({
    required String contractId,
    required String apostilleId,
    required List<Attachment> attachments,
  }) async {
    await _db
        .collection('contracts')
        .doc(contractId)
        .collection('apostilles')
        .doc(apostilleId)
        .set({
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
    }, SetOptions(merge: true));
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
  // Agregações (usando STATUS do DFD)
  // ---------------------------------------------------------------------------

  Future<double> getValorPorStatus(
      List<ProcessData> contratos,
      String statusDesejado,
      ) async {
    if (contratos.isEmpty) return 0.0;

    // carrega os statuses do DFD para os contratos
    await _ensureStatusesForContracts(contratos);

    final alvo = statusDesejado.trim().toUpperCase();

    // filtra IDs cujo status (DFD) coincide
    final idsFiltrados = <String>{
      for (final c in contratos)
        if (_idToString(c.id) != null)
          if ((_getDfdStatusForId(_idToString(c.id)) ?? '').toUpperCase() == alvo)
            _idToString(c.id)!,
    };

    if (idsFiltrados.isEmpty) return 0.0;

    final futures = idsFiltrados.map((contractId) async {
      final snapshot = await _db
          .collection('contracts')
          .doc(contractId)
          .collection('apostilles')
          .get();

      return snapshot.docs.fold<double>(0.0, (sum, doc) {
        final data = doc.data();
        final raw = data['apostilleValue'] ?? data['apostillevalue'];
        num? n;
        if (raw is num) {
          n = raw;
        } else if (raw is String) {
          n = num.tryParse(raw);
        }
        return sum + (n?.toDouble() ?? 0.0);
      });
    });

    final resultados = await Future.wait(futures);
    return resultados.fold<double>(0.0, (a, b) => a + b);
  }

  Future<double> somarValoresApostilamentosPorStatus({
    required List<ProcessData> contratos,
    required String status,
  }) async {
    if (contratos.isEmpty) return 0.0;

    // carrega os statuses do DFD para os contratos
    await _ensureStatusesForContracts(contratos);

    final alvo = status.trim().toUpperCase();
    double total = 0.0;

    final ids = <String>[
      for (final c in contratos)
        if (_idToString(c.id) != null)
          if ((_getDfdStatusForId(_idToString(c.id)) ?? '').toUpperCase() == alvo)
            _idToString(c.id)!,
    ];

    for (final contractId in ids) {
      final apostillesSnapshot =
      await _db.collection('contracts').doc(contractId).collection('apostilles').get();

      for (final doc in apostillesSnapshot.docs) {
        final data = doc.data();
        final raw = data['apostilleValue'] ?? data['apostillevalue'];
        num? n;
        if (raw is num) {
          n = raw;
        } else if (raw is String) {
          n = num.tryParse(raw);
        }
        total += (n?.toDouble() ?? 0.0);
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

  @override
  void dispose() {
    super.dispose();
  }
}
