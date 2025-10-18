import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:siged/_blocs/process/contracts/contract_rules.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/formats/format_field.dart';

// ✅ papel global + checagens centralizadas
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;

class ContractBloc extends BlocBase {
  ContractBloc();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  List<ContractData>? _cachedContracts;

  // -------------------- Helpers internos --------------------
  Map<String, bool> _norm(Map<String, bool>? m) => perms.normalizePermMap(m);

  // -------------------- CRUD / Metadados --------------------

  Future<ContractData> salvarOuAtualizarContrato(ContractData contrato) async {
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

  Future<ContractData?> getContractById(String id) async {
    try {
      final doc = await _db.collection('contracts').doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return ContractData.fromJson(data)..id = doc.id;
    } catch (e) {
      debugPrint('Erro ao buscar contrato por ID: $e');
      return null;
    }
  }

  Future<void> deleteContract(String contractId) async {
    await _db.collection('contracts').doc(contractId).delete();
  }

  // -------------------- Listagem / Filtro / Busca --------------------

  Future<List<ContractData>> getAllContracts({
    String? statusFilter,
    String? searchQuery,
  }) async {
    if (_cachedContracts != null) {
      return _filterCached(_cachedContracts!, statusFilter, searchQuery);
    }

    Query query = _db.collection('contracts');
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.limit(500).get();
    final contracts =
    snapshot.docs.map((e) => ContractData.fromDocument(snapshot: e)).toList();
    _cachedContracts = contracts;

    return _filterCached(contracts, statusFilter, searchQuery);
  }

  Future<ContractData?> getSpecificContract({required String uidContract}) async {
    final doc = await _db.collection('contracts').doc(uidContract).get();
    if (!doc.exists) return null;
    return ContractData.fromDocument(snapshot: doc);
  }

  List<ContractData> _filterCached(
      List<ContractData> src,
      String? statusFilter,
      String? searchQuery,
      ) {
    var list = src;

    if (statusFilter != null && statusFilter.isNotEmpty) {
      final f = statusFilter.toUpperCase();
      list = list.where((c) => (c.contractStatus ?? '').toUpperCase() == f).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = normalize(searchQuery);
      list = list
          .where((c) =>
      normalize(c.summarySubjectContract ?? '').contains(q) ||
          normalize(c.contractNumber ?? '').contains(q) ||
          normalize(c.contractNumberProcess ?? '').contains(q))
          .toList();
    }

    return list;
  }

  /// Filtro por permissões do usuário (papel global + ACL por contrato).
  Future<List<ContractData>> getFilteredContracts({
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

  Future<void> saveContractPermissions(ContractData contractData) async {
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

  Future<Map<String, double>> getValoresTotaisPorStatus(
      List<ContractData> contratos) async {
    final Map<String, double> totais = {
      for (final tipo in ContractRules.statusTypes) tipo.toUpperCase(): 0.0,
    };
    for (final c in contratos) {
      final status = c.contractStatus?.toUpperCase();
      if (status != null && totais.containsKey(status)) {
        totais[status] = (totais[status]! + (c.initialValueContract ?? 0));
      }
    }
    return totais;
  }

  Future<Map<String, double>> getValoresPorRegiao(
      List<ContractData> contratos) async {
    final Map<String, double> valores = {
      for (var r in ContractRules.regions) r: 0.0
    };
    for (final c in contratos) {
      final regiaoStr = c.regionOfState?.toUpperCase() ?? '';
      final valor = c.initialValueContract ?? 0;
      for (var r in ContractRules.regions) {
        if (regiaoStr.contains(r)) {
          valores[r] = (valores[r]! + valor);
        }
      }
    }
    return valores;
  }

  Future<Map<String, double>> getValoresPorEmpresa({
    required List<ContractData> contratos,
    String? selectedRegion,
    required List<String> empresas,
  }) async {
    final Map<String, double> mapa = {for (var e in empresas) e: 0.0};

    for (final c in contratos) {
      final empresa = (c.companyLeader ?? 'NÃO INFORMADO').trim().toUpperCase();
      final pertenceRegiao = selectedRegion == null ||
          (c.regionOfState?.toUpperCase().contains(
            selectedRegion.toUpperCase(),
          ) ??
              false);

      if (pertenceRegiao && mapa.containsKey(empresa)) {
        mapa[empresa] = (mapa[empresa]! + (c.initialValueContract ?? 0));
      }
    }
    return mapa;
  }

  Future<double> getValorPorStatus(
      List<ContractData> contratos, String statusDesejado) async {
    double total = 0.0;
    for (final contrato in contratos) {
      final status = contrato.contractStatus?.toUpperCase();
      if (status == statusDesejado.toUpperCase()) {
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

extension ContractParticipants on ContractBloc {
  // depois
  Future<void> addParticipant({
    required String contractId,
    required String userId,
    Map<String, bool>? permMap,
    Map<String, dynamic> meta = const {},
  }) async {
    try {
      _loadingController.add(true);
      final init = _norm(permMap ?? perms.initialDocPerms()); // ✅ usa o alias do import
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId': init,
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

  /// Papel é global; aqui apenas armazenamos o rótulo para exibição no documento.
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
}
