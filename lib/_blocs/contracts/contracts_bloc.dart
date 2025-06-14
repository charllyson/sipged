import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_datas/apostilles/apostilles_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import '../../_datas/contracts/contracts_data.dart';
import '../../_datas/user/user_data.dart';

class ContractsBloc extends BlocBase {
  late ContractData? contractsData;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _createdController = BehaviorSubject<bool>();
  final _loadingController = BehaviorSubject<bool>();

  Stream<bool> get outLoading => _loadingController.stream;
  Stream<bool> get outCreated => _createdController.stream;

  ContractsBloc();

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]', caseSensitive: false), 'a')
        .replaceAll(RegExp(r'[éèêë]', caseSensitive: false), 'e')
        .replaceAll(RegExp(r'[íìîï]', caseSensitive: false), 'i')
        .replaceAll(RegExp(r'[óòôõö]', caseSensitive: false), 'o')
        .replaceAll(RegExp(r'[úùûü]', caseSensitive: false), 'u')
        .replaceAll(RegExp(r'[ç]', caseSensitive: false), 'c');
  }

  Future<void> deleteContract(String contractId) async {
    await FirebaseFirestore.instance
        .collection('contracts')
        .doc(contractId)
        .delete();
  }
  ///Recuperando todos os contratos
  Future<List<ContractData>> getAllContracts({
    String? statusFilter,
    String? searchQuery,
  }) async {
    Query query = _db.collection('contracts');


    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.get();
    final contracts = snapshot.docs.map((e) => ContractData.fromDocument(snapshot: e)).toList();

    // Filtro local pelo campo "summarysubjectcontract"
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryNormalized = _normalize(searchQuery);
      return contracts.where((c) {
        final title = _normalize(c.summarySubjectContract ?? '');
        return title.contains(queryNormalized);
      }).toList();
    }

    return contracts;
  }



  Future<void> salvarOuAtualizarValidade(ValidityData validade) async {
    final uidContract = validade.uidContract;
    if (uidContract == null) {
      throw Exception("Contrato não informado");
    }

    final data = {
      'orderdate': validade.orderdate,
      'ordernumber': validade.ordernumber,
      'ordertype': validade.ordertype,
    };

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('orders');

    if (validade.uid != null) {
      // Atualizar
      await ref.doc(validade.uid).update(data);
    } else {
      // Criar novo
      await ref.add(data);
    }
  }

  Future<void> deletarValidade(String uidContract, String uidValidade) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('orders')
          .doc(uidValidade)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar validade: $e');
    }
  }


  ///valor de todos os contratos
  Future<double> getAllContractsfilterStatus(String statusContract) async {
    double soma = 0.0;

    try {
      final snapshot = await _db.collection('contracts')
          .where('contractstatus', isEqualTo: statusContract)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final valor = data['valorinicialdocontrato'];

        // Verifica se é número (int ou double)
        if (valor is num) {
          soma += valor.toDouble();
        } else if (valor is String) {
          // Tenta converter string para double, caso venha assim
          final parsed = double.tryParse(valor.replaceAll(',', '.'));
          if (parsed != null) {
            soma += parsed;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao calcular total dos contratos: $e');
      }
    }

    return soma;
  }


  Future<ContractData> getSpecificContract({required String uidContract}) async {
    final snapshot = await FirebaseFirestore.instance.collection('contracts').doc(uidContract).get();
    return ContractData.fromDocument(snapshot: snapshot);
  }

  Future<List<AdditiveData>> getAllAdditivesOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('additives')
        .orderBy('additiveorder')
        .get();

    final list = snapshot.docs.map((doc) {
      return AdditiveData.fromDocument(snapshot: doc);
    }).toList();
    return list;
  }

  ///
  Future<List<ApostillesData>> getAllApostillesOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles')
        .orderBy('apostilleorder')
        .get();

    final list = snapshot.docs.map((doc) {
      return ApostillesData.fromDocument(snapshot: doc);
    }).toList();

    return list;
  }

  Future<List<ValidityData>> getAllValidityOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('orders')
        .orderBy('ordernumber')
        .get();

    final list = snapshot.docs.map((doc) {
      return ValidityData.fromDocument(snapshot: doc);
    }).toList();

    return list;
  }

  Future<void> salvarOuAtualizarAditivo(AdditiveData data, String uidContract) async {
    final Map<String, dynamic> newData = {
      'additivenumberprocess': data.additivenumberprocess,
      'additiveorder': data.additiveorder,
      'additivevaliditycontractdata': data.additivevaliditycontractdata,
      'additivedata': data.additivedata,
      'additivevalue': data.additivevalue,
      'typeOfAdditive': data.typeOfAdditive, // ✅ Adicionado
    };

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('additives');

    if (data.uid != null) {
      await ref.doc(data.uid).update(newData);
    } else {
      await ref.add(newData);
    }
  }

  Future<void> deletarAditivo(String uidContract, String uidAditivo) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('additives')
          .doc(uidAditivo)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar aditivo: $e');
    }
  }

  Future<void> deletarApostille(String uidContract, String uidApostille) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('apostilles')
          .doc(uidApostille)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar apostilamento: $e');
    }
  }


  Future<void> saveOrUpdateApostille(ApostillesData data, String uidContract) async {
    final Map<String, dynamic> newData = {

      'apostillenumberprocess': data.apostillenumberprocess,
      'apostilleorder': data.apostilleorder,
      'apostilledata': data.apostilledata,
      'apostillevalue': data.apostillevalue,
    };

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles');

    if (data.uid != null) {
      await ref.doc(data.uid).update(newData);
    } else {
      await ref.add(newData);
    }
  }

  Future<void> salvarOuAtualizarContrato(ContractData data) async {
    _loadingController.add(true);

    try {
      final Map<String, dynamic> contractMap = {
        'managerid': data.managerId,
        'contractnumber': data.contractNumber,
        'maincontracthighway': data.mainContractHighway,
        'restriction': data.restriction,
        'services': data.contractServices,
        'contractmanagerartnumber': data.contractManagerArtNumber,
        'summarysubjectcontract': data.summarySubjectContract,
        'regionofstate': data.regionOfState,
        'managerphonenumber': data.managerPhoneNumber,
        'companyleader': data.contractCompanyLeader,
        'generalnumber': data.generalNumber,
        'contractbiddingprocessnumber': data.contractBiddingProcessNumber,
        'automaticnumbersiafe': data.automaticNumberSiafe,
        'fisicalpercentage': data.physicalPercentage,
        'regionalmanager': data.regionalManager,
        'contractstatus': data.contractStatus,
        'objectcontractdescription': data.contractObjectDescription,
        'contracttype': data.contractType,
        'companiesinvolved': data.contractCompaniesInvolved,
        'urlpdf': data.urlContractPdf,
        'cnonumber': data.cnoNumber,
        'initialvalidityexecutiondays': data.initialValidityExecutionDays,
        'initialvaliditycontractdays': data.initialValidityContractDays,
        'cpfcontractmanager': data.cpfContractManager,
        'cnpjnumber': data.cnpjNumber,
        'existecontrato': data.existContract,
        'initialvalidityexecutiondate': data.initialvalidityexecutiondate,
        'datapublicacaodoe': data.datapublicacaodoe,
        'valorinicialdocontrato': data.valorinicialdocontrato,
        'initialvaliditycontractdate': data.initialvaliditycontractdate,
        'financialpercentage': data.financialpercentage,
        'extkm': data.contractextkm,
      };

      final contractsRef = _db.collection('contracts');

      if (data.id != null && data.id!.isNotEmpty) {
        // Atualiza
        await contractsRef.doc(data.id).update(contractMap);
      } else {
        // Cria novo e recupera o uid gerado
        final newDoc = await contractsRef.add(contractMap);
        data.id = newDoc.id;
      }

      _createdController.add(true);
    } catch (e) {
      _createdController.add(false);
      rethrow;
    } finally {
      _loadingController.add(false);
    }
  }

  // Função para atualizar as permissões do usuário no Firestore
  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType, // ex: 'read', 'edit', 'delete'
    required bool value,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId.$permissionType': value,
      });
    } catch (e) {
      print('Erro ao atualizar permissões do usuário para contrato: $e');
    } finally {
      _loadingController.add(false);
    }
  }


  // Carrega as permissões do usuário a partir do Firestore
  Future<ContractData?> getContractPermissions(String id) async {
    try {
      final docSnapshot = await _db.collection('contracts').doc(id).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return ContractData(
          id: id,
          permissionContractId: Map<String, Map<String, bool>>.from(data['permissionContractId'] ?? {}),
        );
      }
    } catch (e) {
      print('Erro ao carregar permissões: $e');
    }
    return null;
  }

  // Função para salvar as permissões no Firestore
  Future<void> saveContractPermissions(ContractData contractData) async {
    if (contractData.id == null) return;

    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractData.id).update({
        'permissionContractId': contractData.permissionContractId,
      });
    } catch (e) {
      print('Erro ao salvar permissões: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  bool canDeleteContract({
    required UserData userData,
    required ContractData contract,
  }) {
    final profile = userData.baseProfile?.toLowerCase();

    // ✅ Administrador pode apagar qualquer contrato
    if (profile == 'administrador') return true;

    // 👇 Para os demais, verificar permissão específica no contrato
    final perms = contract.permissionContractId[userData.id];
    return perms != null && perms['delete'] == true;
  }


  Future<List<ContractData>> getFilteredContracts({
    required UserData currentUser,
    String? statusFilter,
    String? searchQuery,
  }) async {
    final uid = currentUser.id!;
    final perfil = currentUser.baseProfile?.toLowerCase();

    if (perfil == 'administrador') {
      return await getAllContracts(
        statusFilter: statusFilter,
        searchQuery: searchQuery,
      );
    }

    final contratosGestor = await getContractsWhereUserIsManager(
      uid: uid,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

    final contratosFiscal = await getContractsWhereUserIsRegionalManager(
      uid: uid,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

    final contratosComPermissao = await getAllContracts(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

    final contratosPermitidos = contratosComPermissao.where((contract) {
      final permMap = contract.permissionContractId;
      if (permMap == null || !permMap.containsKey(uid)) return false;

      final perms = permMap[uid];
      if (perms == null) return false;

      if (perfil == 'colaborador') {
        return perms['edit'] == true || perms['read'] == true;
      }
      if (perfil == 'leitor') {
        return perms['read'] == true;
      }
      return false;
    });

    final todosContratos = {
      ...contratosGestor,
      ...contratosFiscal,
      ...contratosPermitidos,
    };

    return todosContratos.toList();
  }


  /// Busca usuários com permissão para um contrato específico
  Future<List<Map<String, dynamic>>> buscarUsuariosComPermissao(
      String contractId, {
        bool incluirComPermissaoDeLeitura = true,
        bool incluirComPermissaoDeEdicao = true,
      }) async {
    final contratoSnapshot =
    await FirebaseFirestore.instance.collection('contracts').doc(contractId).get();

    final contractData = contratoSnapshot.data();
    if (contractData == null || contractData['permissionContractId'] == null) return [];

    final Map<String, dynamic> permissoes = Map<String, dynamic>.from(
        contractData['permissionContractId'] as Map);

    final List<String> uidsPermitidos = [];

    permissoes.forEach((uid, permissoesDoUsuario) {
      final p = Map<String, dynamic>.from(permissoesDoUsuario);
      final podeLer = p['read'] == true;
      final podeEditar = p['edit'] == true;

      if ((incluirComPermissaoDeLeitura && podeLer) ||
          (incluirComPermissaoDeEdicao && podeEditar)) {
        uidsPermitidos.add(uid);
      }
    });

    // Busca apenas os usuários com uid permitido
    final usuariosSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: uidsPermitidos.take(10).toList()) // limita para segurança
        .get();

    return usuariosSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'name': data['name'],
        'email': data['email'],
      };
    }).toList();
  }

  Future<List<ContractData>> getContractsWhereUserIsManager({
    required String uid,
    String? statusFilter,
    String? searchQuery,
  }) async {
    Query query = _db.collection('contracts');

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.get();
    final contracts = snapshot.docs
        .map((e) => ContractData.fromDocument(snapshot: e))
        .where((c) => c.managerId == uid)
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final normalizedQuery = _normalize(searchQuery);
      return contracts.where((c) {
        final title = _normalize(c.summarySubjectContract ?? '');
        return title.contains(normalizedQuery);
      }).toList();
    }

    return contracts;
  }

  Future<List<ContractData>> getContractsWhereUserIsRegionalManager({
    required String uid,
    String? statusFilter,
    String? searchQuery,
  }) async {
    Query query = _db.collection('contracts');

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.get();
    final contracts = snapshot.docs
        .map((e) => ContractData.fromDocument(snapshot: e))
        .where((c) => c.regionalManager == uid)
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final normalizedQuery = _normalize(searchQuery);
      return contracts.where((c) {
        final title = _normalize(c.summarySubjectContract ?? '');
        return title.contains(normalizedQuery);
      }).toList();
    }

    return contracts;
  }



  @override
  void dispose() {
    super.dispose();
    _loadingController.close();
    _createdController.close();
  }
}
