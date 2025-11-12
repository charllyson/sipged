import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/formats/format_field.dart';

// ✅ papel global + checagens centralizadas
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

class ProcessBloc extends BlocBase {
  ProcessBloc();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 DFD (status por contrato)
  final DfdRepository _dfdRepo = DfdRepository();
  final Map<String, String> _dfdStatusByContractId = {};

  // -------------------- Streams de estado --------------------
  final _createdController = BehaviorSubject<bool>();
  final _loadingController = BehaviorSubject<bool>();

  Stream<bool> get outLoading => _loadingController.stream;
  Stream<bool> get outCreated => _createdController.stream;

  // Pesquisa em memória
  final BehaviorSubject<String> _searchSubject =
  BehaviorSubject<String>.seeded('');
  Stream<String> get searchStream => _searchSubject.stream;
  Function(String) get setSearch => _searchSubject.sink.add;
  String get currentSearch => _searchSubject.value;
  void clearSearch() => _searchSubject.add('');

  // Cache simples de contratos (última consulta)
  List<ProcessData>? _cachedContracts;

  // -------------------- Helpers internos --------------------
  Map<String, bool> _norm(Map<String, bool>? m) => perms.normalizePermMap(m);

  Future<void> _ensureDfdStatusForIds(Iterable<String> ids) async {
    final futures = <Future<void>>[];

    for (final id in ids) {
      if (id.isEmpty) continue;
      if (_dfdStatusByContractId.containsKey(id)) continue;

      futures.add(() async {
        try {
          final light = await _dfdRepo.readLightFields(id);
          final s = (light.status ?? '').trim();
          if (s.isNotEmpty) {
            _dfdStatusByContractId[id] = s;
          }
        } catch (e) {
          debugPrint('Erro ao ler status leve do DFD ($id): $e');
        }
      }());
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  String _dfdStatusFor(ProcessData c) {
    final id = c.id;
    if (id == null || id.isEmpty) return '';
    return (_dfdStatusByContractId[id] ?? '').toUpperCase();
  }

  // -------------------- CRUD / Metadados --------------------

  Future<ProcessData> salvarOuAtualizarContrato(ProcessData contrato) async {
    if (contrato.id != null) {
      await _db.collection('contracts').doc(contrato.id).update(
        contrato.toMap()
          ..addAll({
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
          }),
      );
    } else {
      final docRef = await _db.collection('contracts').add(
        contrato.toMap()
          ..addAll({
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
          }),
      );
      contrato.id = docRef.id;
    }
    return contrato;
  }

  Future<ProcessData?> getContractById(String id) async {
    try {
      final doc = await _db.collection('contracts').doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return ProcessData.fromJson(data)..id = doc.id;
    } catch (e) {
      debugPrint('Erro ao buscar contrato por ID: $e');
      return null;
    }
  }

  Future<void> deleteContract(String contractId) async {
    await _db.collection('contracts').doc(contractId).delete();
  }

  // -------------------- Listagem / Filtro / Busca --------------------

  Future<List<ProcessData>> getAllContracts({
    String? statusFilter, // 🔸 ainda usado no WHERE do contrato (campo contractstatus)
    String? searchQuery,
  }) async {
    if (_cachedContracts != null) {
      return _filterCached(_cachedContracts!, statusFilter, searchQuery);
    }

    Query query = _db.collection('contracts');
    if (statusFilter != null && statusFilter.isNotEmpty) {
      // 🔹 Filtro de contrato (campo contractstatus) — legado/apoio
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.limit(500).get();
    final contracts =
    snapshot.docs.map((e) => ProcessData.fromDocument(snapshot: e)).toList();
    _cachedContracts = contracts;

    return _filterCached(contracts, statusFilter, searchQuery);
  }

  Future<ProcessData?> getSpecificContract({required String uidContract}) async {
    final doc = await _db.collection('contracts').doc(uidContract).get();
    if (!doc.exists) return null;
    return ProcessData.fromDocument(snapshot: doc);
  }

  /// Filtro em memória AGORA só por busca textual.
  /// Qualquer filtro por status visual deve usar o status do DFD em outro ponto.
  List<ProcessData> _filterCached(
      List<ProcessData> src,
      String? statusFilter,
      String? searchQuery,
      ) {
    var list = src;

    // 🔸 NÃO usamos mais (c.status) aqui.
    // O filtro por status no Firestore (contractstatus) já foi aplicado no getAllContracts.

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = normalize(searchQuery);
      list = list
          .where((c) =>
      normalize(c.summarySubject ?? '').contains(q) ||
          normalize(c.contractNumber ?? '').contains(q))
          .toList();
    }

    return list;
  }

  /// Filtro por permissões do usuário (papel global + ACL por contrato).
  Future<List<ProcessData>> getFilteredContracts({
    required UserData currentUser,
    String? statusFilter,
    String? searchQuery,
  }) async {
    final uid = currentUser.id ?? '';
    final all = await getAllContracts(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

    // Admin global vê tudo
    if (roles.roleForUser(currentUser) == roles.BaseRole.ADMINISTRADOR) {
      return all;
    }

    // Caso contrário, respeita a ACL do contrato (permissionContractId)
    final permitted = all.where((contract) {
      final map = contract.permissionContractId;
      final userPerms = map[uid];
      if (userPerms == null) return false;

      // leitura já dá visibilidade; demais também
      return userPerms['read'] == true ||
          userPerms['create'] == true ||
          userPerms['edit'] == true ||
          userPerms['delete'] == true ||
          userPerms['approve'] == true;
    }).toList();

    return permitted;
  }

  // -------------------- Permissões (ACL por documento) --------------------

  /// Atualiza UMA chave (campo aninhado) sem perder as demais.
  /// Observação: isto não garante as 5 chaves presentes no doc; use setParticipantPerms
  /// para gravar o bloco normalizado.
  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType, // 'read' | 'create' | 'edit' | 'delete' | 'approve'
    required bool value,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId.$permissionType': value,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao atualizar permissões do usuário para contrato: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  /// Sobrescreve o bloco do usuário com as 5 chaves normalizadas.
  Future<void> setParticipantPerms({
    required String contractId,
    required String userId,
    required Map<String, bool> perms,
  }) async {
    try {
      _loadingController.add(true);
      final normalized = _norm(perms);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  /// Papel agora é **global**. Aqui gravamos apenas o rótulo em `participantsInfo`
  /// para exibição, **sem** resetar a ACL do documento.
  Future<void> setParticipantRole({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'participantsInfo.$userId.role': role,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> saveContractPermissions(ProcessData contractData) async {
    if (contractData.id == null) return;
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractData.id).update({
        'permissionContractId': contractData.permissionContractId.map(
              (k, v) => MapEntry(k, _norm(v)),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar permissões: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  // -------------------- Agregações / Relatórios --------------------
  //
  // 🔥 A partir daqui, status é SEMPRE o do DFD (não usamos mais ProcessData.status).

  Future<Map<String, double>> getValoresTotaisPorStatus(
      List<ProcessData> contratos,
      ) async {
    // Mapa base com todos os status conhecidos do DFD
    final Map<String, double> totais = {
      for (final tipo in DfdData.statusTypes) tipo.toUpperCase(): 0.0,
    };

    final ids = contratos.map((c) => c.id).whereType<String>().toSet();
    await _ensureDfdStatusForIds(ids);

    for (final c in contratos) {
      final st = _dfdStatusFor(c); // status vindo do DFD
      if (st.isEmpty) continue;

      if (!totais.containsKey(st)) {
        // caso apareça um status novo ainda não mapeado em statusTypes
        totais[st] = 0.0;
      }

      totais[st] = (totais[st]! + (c.initialValueContract ?? 0.0));
    }

    return totais;
  }

  Future<double> getValorPorStatus(
      List<ProcessData> contratos,
      String statusDesejado,
      ) async {
    double total = 0.0;
    final alvo = statusDesejado.toUpperCase();

    final ids = contratos.map((c) => c.id).whereType<String>().toSet();
    await _ensureDfdStatusForIds(ids);

    for (final contrato in contratos) {
      final st = _dfdStatusFor(contrato); // status do DFD
      if (st == alvo) {
        total += contrato.initialValueContract ?? 0.0;
      }
    }

    return total;
  }

  // -------------------- Dispose --------------------
  @override
  void dispose() {
    _searchSubject.close();
    _loadingController.close();
    _createdController.close();
    super.dispose();
  }
}

/// Helpers relacionados a participantes do contrato
extension ContractParticipants on ProcessBloc {
  /// Adiciona participante com permissões iniciais normalizadas
  Future<void> addParticipant({
    required String contractId,
    required String userId,
    Map<String, bool>? permMap,
    Map<String, dynamic> meta = const {},
  }) async {
    try {
      _loadingController.add(true);

      // usa o normalizador centralizado + perms iniciais
      final initPerms = _norm(permMap ?? perms.initialDocPerms());

      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId': initPerms,
        if (meta.isNotEmpty) 'participantsInfo.$userId': meta,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> removeParticipant({
    required String contractId,
    required String userId,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId': FieldValue.delete(),
        'participantsInfo.$userId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> updateParticipantMeta({
    required String contractId,
    required String userId,
    required Map<String, dynamic> meta,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'participantsInfo.$userId': meta,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } finally {
      _loadingController.add(false);
    }
  }

  /// Versões "helper" opcionais, se quiser chamar via extensão
  Future<void> setParticipantPermsExt({
    required String contractId,
    required String userId,
    required Map<String, bool> permsMap,
  }) async {
    await setParticipantPerms(
      contractId: contractId,
      userId: userId,
      perms: permsMap,
    );
  }

  Future<void> setParticipantRoleExt({
    required String contractId,
    required String userId,
    required String role,
  }) async {
    await setParticipantRole(
      contractId: contractId,
      userId: userId,
      role: role,
    );
  }
}
