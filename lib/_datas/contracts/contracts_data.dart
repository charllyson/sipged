// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class ContractData extends ChangeNotifier {
  ///Informações do contrato
  String? id;
  String? managerId;
  String? contractNumber;
  String? mainContractHighway;
  String? restriction;
  String? contractServices;
  String? contractManagerArtNumber;
  String? summarySubjectContract;
  String? regionOfState;
  String? managerPhoneNumber;
  String? contractCompanyLeader;
  String? generalNumber;
  String? contractBiddingProcessNumber;
  String? automaticNumberSiafe;
  double? physicalPercentage;
  String? regionalManager;
  String? contractStatus;
  String? contractObjectDescription;
  String? contractType;
  String? contractCompaniesInvolved;
  String? urlContractPdf;
  String? cnoNumber;

  int? cnpjNumber;
  int? initialValidityExecutionDays;
  int? initialValidityContractDays;
  int? cpfContractManager;

  bool? existContract;

  DateTime? initialvalidityexecutiondate;
  DateTime? initialvaliditycontractdate;
  DateTime? datapublicacaodoe;
  double? valorinicialdocontrato;
  double? financialpercentage;
  double? contractextkm;

  Map<String, Map<String, bool>> permissionContractId = {};

  ContractData({
    this.id,
    this.managerId,
    this.summarySubjectContract,
    this.contractNumber,
    this.mainContractHighway,
    this.restriction,
    this.contractServices,
    this.contractManagerArtNumber,
    this.contractextkm,
    this.regionOfState,
    this.managerPhoneNumber,
    this.contractCompanyLeader,
    this.generalNumber,
    this.contractBiddingProcessNumber,
    this.automaticNumberSiafe,
    this.physicalPercentage,
    this.regionalManager,
    this.contractStatus,
    this.contractObjectDescription,
    this.contractType,
    this.contractCompaniesInvolved,
    this.urlContractPdf,
    this.initialValidityExecutionDays,
    this.initialValidityContractDays,
    this.cpfContractManager,
    this.cnoNumber,
    this.cnpjNumber,
    this.existContract,
    this.initialvalidityexecutiondate,
    this.datapublicacaodoe,
    this.valorinicialdocontrato,
    this.initialvaliditycontractdate,
    this.financialpercentage,
    this.permissionContractId = const {},
});

  ///Recuperando informações no banco de dados
  factory ContractData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Contrato não encontrado");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Os dados do contrato estão vazios");
    }

    return ContractData(
      id: snapshot.id,
      contractNumber: data['contractnumber']?.toString(),
      summarySubjectContract: data['summarysubjectcontract']?.toString(),
      contractBiddingProcessNumber: data['contractbiddingprocessnumber']?.toString(),
      managerId: data['managerid']?.toString(),
      mainContractHighway: data['maincontracthighway']?.toString(),
      restriction: data['restriction']?.toString(),
      contractServices: data['services']?.toString(),
      contractManagerArtNumber: data['contractmanagerartnumber']?.toString(),
      regionOfState: data['regionofstate']?.toString(),
      managerPhoneNumber: data['managerphonenumber']?.toString(),
      contractCompanyLeader: data['companyleader']?.toString(),
      generalNumber: data['generalnumber']?.toString(),
      automaticNumberSiafe: data['automaticnumbersiafe']?.toString(),
      regionalManager: data['regionalmanager']?.toString(),
      contractStatus: data['contractstatus']?.toString(),
      contractObjectDescription: data['objectcontractdescription']?.toString(),
      contractType: data['contracttype']?.toString(),
      contractCompaniesInvolved: data['companiesinvolved']?.toString(),
      urlContractPdf: data['urlpdf']?.toString(),
      cnoNumber: data['cnonumber']?.toString(),
      initialvalidityexecutiondate: (data['initialvalidityexecutiondate'] as Timestamp?)?.toDate(),
      datapublicacaodoe: (data['datapublicacaodoe'] as Timestamp?)?.toDate(),
      initialvaliditycontractdate: (data['initialvaliditycontractdate'] as Timestamp?)?.toDate(),
      valorinicialdocontrato: (data['valorinicialdocontrato'] as num?)?.toDouble() ?? 0.0,
      physicalPercentage: (data['fisicalpercentage'] as num?)?.toDouble() ?? 0.0,
      financialpercentage: (data['financialpercentage'] as num?)?.toDouble() ?? 0.0,
      contractextkm: (data['extkm'] as num?)?.toDouble() ?? 0.0,
      cnpjNumber: (data['cnpjnumber'] as num?)?.toInt(),
      cpfContractManager: (data['cpfcontractmanager'] as num?)?.toInt(),
      initialValidityExecutionDays: (data['initialvalidityexecutiondays'] as num?)?.toInt(),
      initialValidityContractDays: (data['initialvaliditycontractdays'] as num?)?.toInt(),
      existContract: data['existecontrato'] as bool? ?? false,
      permissionContractId: (data['permissionContractId'] as Map<String, dynamic>?)?.map(
            (userId, perm) => MapEntry(
          userId,
          Map<String, bool>.from(perm as Map),
        ),
      ) ?? {},
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'contractnumber': contractNumber,
      'summarysubjectcontract': summarySubjectContract,
      'contractbiddingprocessnumber': contractBiddingProcessNumber,
      'managerid': managerId,
      'maincontracthighway': mainContractHighway,
      'restriction': restriction,
      'services': contractServices,
      'contractmanagerartnumber': contractManagerArtNumber,
      'regionofstate': regionOfState,
      'managerphonenumber': managerPhoneNumber,
      'companyleader': contractCompanyLeader,
      'generalnumber': generalNumber,
      'automaticnumbersiafe': automaticNumberSiafe,
      'regionalmanager': regionalManager,
      'contractstatus': contractStatus,
      'objectcontractdescription': contractObjectDescription,
      'contracttype': contractType,
      'companiesinvolved': contractCompaniesInvolved,
      'urlpdf': urlContractPdf,
      'cnonumber': cnoNumber,
      'initialvalidityexecutiondate': initialvalidityexecutiondate,
      'datapublicacaodoe': datapublicacaodoe,
      'initialvaliditycontractdate': initialvaliditycontractdate,
      'valorinicialdocontrato': valorinicialdocontrato,
      'fisicalpercentage': physicalPercentage,
      'financialpercentage': financialpercentage,
      'extkm': contractextkm,
      'cnpjnumber': cnpjNumber,
      'cpfcontractmanager': cpfContractManager,
      'initialvalidityexecutiondays': initialValidityExecutionDays,
      'initialvaliditycontractdays': initialValidityContractDays,
      'existecontrato': existContract,
      'permissionContractId': permissionContractId,
    };
  }


  // Atualiza as permissões do usuário para um contrato específico usando o ID do documento
  void updateContractPermissions(String contractDocId, String permissionType, bool value) {
    if (permissionContractId[contractDocId] == null) {
      permissionContractId[contractDocId] = {};
    }
    permissionContractId[contractDocId]![permissionType] = value;
  }
}
