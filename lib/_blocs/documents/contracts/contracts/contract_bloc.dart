import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_rules.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/formats/format_field.dart';

/// BLoC responsável por TUDO que é **Firestore** do módulo de contratos.
/// (Upload/Storage foi movido para ContractStorageBloc.)
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

  // -------------------- CRUD / Metadados --------------------

  /// Cria ou atualiza um contrato no Firestore.
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

  /// Lê um contrato por ID.
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

  /// Exclui um contrato (documento) no Firestore.
  Future<void> deleteContract(String contractId) async {
    await _db.collection('contracts').doc(contractId).delete();
  }

  // -------------------- Listagem / Filtro / Busca --------------------

  /// Busca (com cache) com filtro opcional por status e query (em memória).
  Future<List<ContractData>> getAllContracts({
    String? statusFilter,
    String? searchQuery,
  }) async {
    if (_cachedContracts != null) {
      return _filterCached(_cachedContracts!, statusFilter, searchQuery);
    }

    Query query = _db.collection('contracts');
    if (statusFilter != null && statusFilter.isNotEmpty) {
      // Atenção ao nome do campo no Firestore:
      // use o mesmo que você usa para gravar (contractstatus/contractStatus).
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.limit(500).get();
    final contracts = snapshot.docs
        .map((e) => ContractData.fromDocument(snapshot: e))
        .toList();
    _cachedContracts = contracts;

    return _filterCached(contracts, statusFilter, searchQuery);
  }

  /// Retorna um contrato específico pelo ID
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
      list = list
          .where((c) => (c.contractStatus ?? '').toUpperCase() == f)
          .toList();
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

  /// Filtro por permissões do usuário.
  Future<List<ContractData>> getFilteredContracts({
    required UserData currentUser,
    String? statusFilter,
    String? searchQuery,
  }) async {
    final uid = currentUser.id!;
    final perfil = currentUser.baseProfile?.toLowerCase();

    final todos = await getAllContracts(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

    // Perfis com acesso amplo
    if (perfil == 'administrador' || perfil == 'colaborador') {
      return todos;
    }

    // Leitor → precisa de read=true no mapa de permissões
    final contratosPermitidos = todos.where((contract) {
      final permMap = contract.permissionContractId;
      if (!permMap.containsKey(uid)) return false;

      final perms = permMap[uid];
      if (perms == null) return false;

      if (perfil == 'colaborador') {
        return perms['edit'] == true ||
            perms['read'] == true ||
            perms['delete'] == true;
      }
      if (perfil == 'leitor') {
        return perms['read'] == true;
      }
      return false;
    }).toList();

    return contratosPermitidos;
  }

  // -------------------- Permissões --------------------

  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType, // ex: 'read' | 'edit' | 'delete'
    required bool value,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId.$permissionType': value,
      });
    } catch (e) {
      debugPrint('Erro ao atualizar permissões do usuário para contrato: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> saveContractPermissions(ContractData contractData) async {
    if (contractData.id == null) return;
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractData.id).update({
        'permissionContractId': contractData.permissionContractId,
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
      final empresa =
      (c.companyLeader ?? 'NÃO INFORMADO').trim().toUpperCase();
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
