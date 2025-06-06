import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_datas/apostilles/apostilles_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import '../../_datas/contracts/contracts_data.dart';

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
        final title = _normalize(c.summarysubjectcontract ?? '');
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

  Future<void> salvarOuAtualizarContrato(ContractData data) async {
    _loadingController.add(true);

    try {
      final Map<String, dynamic> contractMap = {
        'managerid': data.managerid,
        'contractnumber': data.contractnumber,
        'maincontracthighway': data.maincontracthighway,
        'restriction': data.restriction,
        'services': data.contractservices,
        'contractmanagerartnumber': data.contractmanagerartnumber,
        'summarysubjectcontract': data.summarysubjectcontract,
        'regionofstate': data.regionofstate,
        'managerphonenumber': data.managerphonenumber,
        'companyleader': data.contractcompanyleader,
        'generalnumber': data.generalnumber,
        'contractbiddingprocessnumber': data.contractbiddingprocessnumber,
        'automaticnumbersiafe': data.automaticnumbersiafe,
        'fisicalpercentage': data.fisicalpercentage,
        'regionalmanager': data.regionalmanager,
        'contractstatus': data.contractstatus,
        'objectcontractdescription': data.contractobjectdescription,
        'contracttype': data.contracttype,
        'companiesinvolved': data.contractcompaniesinvolved,
        'urlpdf': data.urlpdf,
        'cnonumber': data.cnonumber,
        'initialvalidityexecutiondays': data.initialvalidityexecutiondays,
        'initialvaliditycontractdays': data.initialvaliditycontractdays,
        'cpfcontractmanager': data.cpfcontractmanager,
        'cnpjnumber': data.cnpjnumber,
        'existecontrato': data.existecontrato,
        'initialvalidityexecutiondate': data.initialvalidityexecutiondate,
        'datapublicacaodoe': data.datapublicacaodoe,
        'valorinicialdocontrato': data.valorinicialdocontrato,
        'initialvaliditycontractdate': data.initialvaliditycontractdate,
        'financialpercentage': data.financialpercentage,
        'extkm': data.contractextkm,
      };

      final contractsRef = _db.collection('contracts');

      if (data.uid != null && data.uid!.isNotEmpty) {
        // Atualiza
        await contractsRef.doc(data.uid).update(contractMap);
      } else {
        // Cria novo e recupera o uid gerado
        final newDoc = await contractsRef.add(contractMap);
        data.uid = newDoc.id;
      }

      _createdController.add(true);
    } catch (e) {
      _createdController.add(false);
      rethrow;
    } finally {
      _loadingController.add(false);
    }
  }


  @override
  void dispose() {
    super.dispose();
    _loadingController.close();
    _createdController.close();
  }
}
