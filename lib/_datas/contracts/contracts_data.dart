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
  String? contractNumberProcess;
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
  int? cpfContractManager;
  bool? existContract;
  double? initialContractValue;
  double? financialPercentage;
  double? contractExtKm;
  int? initialValidityExecutionDays;
  int? initialValidityContractDays;

  ///Datas de validade do contrato
  DateTime? initialValidityExecutionDate;
  DateTime? finalValidityExecutionDate;
  DateTime? initialValidityContractDate;
  DateTime? finalValidityContractDate;
  DateTime? dateDeliveryWork;
  DateTime? publicationDateDoe;


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
    this.contractExtKm,
    this.regionOfState,
    this.managerPhoneNumber,
    this.contractCompanyLeader,
    this.generalNumber,
    this.contractNumberProcess,
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
    this.initialValidityExecutionDate,
    this.publicationDateDoe,
    this.financialPercentage,
    this.initialContractValue,
    this.initialValidityContractDate,
    this.finalValidityExecutionDate,
    this.finalValidityContractDate,
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
      contractNumberProcess: data['contractbiddingprocessnumber']?.toString(),
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
      initialValidityExecutionDate: (data['initialvalidityexecutiondate'] as Timestamp?)?.toDate(),
      publicationDateDoe: (data['datapublicacaodoe'] as Timestamp?)?.toDate(),
      initialValidityContractDate: (data['initialvaliditycontractdate'] as Timestamp?)?.toDate(),
      initialContractValue: (data['valorinicialdocontrato'] as num?)?.toDouble() ?? 0.0,
      physicalPercentage: (data['fisicalpercentage'] as num?)?.toDouble() ?? 0.0,
      financialPercentage: (data['financialpercentage'] as num?)?.toDouble() ?? 0.0,
      contractExtKm: (data['extkm'] as num?)?.toDouble() ?? 0.0,
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
      if (contractNumber != null) 'contractnumber': contractNumber,
      if (contractType != null) 'contracttype': contractType,
      if (contractServices != null) 'services': contractServices,
      if (mainContractHighway != null) 'maincontracthighway': mainContractHighway,
      if (summarySubjectContract != null) 'summarysubjectcontract': summarySubjectContract,
      if (contractNumberProcess != null) 'contractbiddingprocessnumber': contractNumberProcess,
      if (regionOfState != null) 'regionofstate': regionOfState,
      if (contractStatus != null) 'contractstatus': contractStatus,
      if (contractCompanyLeader != null) 'companyleader': contractCompanyLeader,
      if (contractCompaniesInvolved != null) 'companiesinvolved': contractCompaniesInvolved,
      if (automaticNumberSiafe != null) 'automaticnumbersiafe': automaticNumberSiafe,
      if (contractObjectDescription != null) 'objectcontractdescription': contractObjectDescription,
      if (managerPhoneNumber != null) 'managerphonenumber': managerPhoneNumber,
      if (contractManagerArtNumber != null) 'contractmanagerartnumber': contractManagerArtNumber,
      if (regionalManager != null) 'regionalmanager': regionalManager,
      if (managerId != null) 'managerid': managerId,
      if (cnoNumber != null) 'cnonumber': cnoNumber,
      if (cnpjNumber != null) 'cnpjnumber': cnpjNumber,
      if (cpfContractManager != null) 'cpfcontractmanager': cpfContractManager,
      if (contractExtKm != null) 'extkm': contractExtKm,
      if (financialPercentage != null) 'financialpercentage': financialPercentage,
      if (physicalPercentage != null) 'fisicalpercentage': physicalPercentage,
      if (initialContractValue != null) 'valorinicialdocontrato': initialContractValue,
      if (publicationDateDoe != null) 'datapublicacaodoe': publicationDateDoe,
      if (initialValidityExecutionDate != null) 'initialvalidityexecutiondate': initialValidityExecutionDate,
      if (initialValidityContractDate != null) 'initialvaliditycontractdate': initialValidityContractDate,
      if (finalValidityExecutionDate != null) 'finalvalidityexecutiondate': finalValidityExecutionDate,
      if (finalValidityContractDate != null) 'finalvaliditycontractdate': finalValidityContractDate,
      if (initialValidityExecutionDays != null) 'initialvalidityexecutiondays': initialValidityExecutionDays,
      if (initialValidityContractDays != null) 'initialvaliditycontractdays': initialValidityContractDays,
      if (existContract != null) 'existecontrato': existContract,
      if (permissionContractId.isNotEmpty) 'permissionContractId': permissionContractId,
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
