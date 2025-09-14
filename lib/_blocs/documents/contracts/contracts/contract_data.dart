import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContractData extends ChangeNotifier {
  /// Informações do contrato
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
  String? companyLeader;
  String? generalNumber;
  String? contractNumberProcess;
  String? automaticNumberSiafe;
  String? regionalManager;
  String? contractStatus;
  String? contractObjectDescription;

  /// Tipo de contrato (seu campo antigo)
  String? contractType;

  /// NOVO: Tipo de obra (e.g.: Rodoviária, Saneamento, etc.)
  String? workType;

  String? contractCompaniesInvolved;
  String? urlContractPdf;
  String? cnoNumber;
  int? cnpjNumber;
  int? cpfContractManager;
  bool? existContract;
  double? initialValueContract;
  double? contractExtKm;

  double? financialPercentage;
  double? physicalPercentage;

  /// Datas de validade do contrato
  DateTime? publicationDateDoe;
  int? initialValidityExecutionDays;
  int? initialValidityContractDays;

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
    this.companyLeader,
    this.generalNumber,
    this.contractNumberProcess,
    this.automaticNumberSiafe,
    this.physicalPercentage,
    this.regionalManager,
    this.contractStatus,
    this.contractObjectDescription,
    this.contractType,
    this.workType, // <- novo
    this.contractCompaniesInvolved,
    this.urlContractPdf,
    this.initialValidityExecutionDays,
    this.initialValidityContractDays,
    this.cpfContractManager,
    this.cnoNumber,
    this.cnpjNumber,
    this.existContract,
    this.publicationDateDoe,
    this.financialPercentage,
    this.initialValueContract,
    this.permissionContractId = const {},
  });

  factory ContractData.empty() {
    return ContractData(
      id: null, // ← importante!
      managerId: '',
      contractNumber: '',
      mainContractHighway: '',
      restriction: '',
      contractServices: '',
      contractManagerArtNumber: '',
      summarySubjectContract: '',
      regionOfState: '',
      managerPhoneNumber: '',
      companyLeader: '',
      generalNumber: '',
      contractNumberProcess: '',
      automaticNumberSiafe: '',
      regionalManager: '',
      contractStatus: '',
      contractObjectDescription: '',
      contractType: '',
      workType: '', // <- novo default
      contractCompaniesInvolved: '',
      urlContractPdf: '',
      cnoNumber: '',
      cnpjNumber: 0,
      cpfContractManager: 0,
      existContract: false,
      initialValueContract: 0.0,
      contractExtKm: 0.0,
      financialPercentage: 0.0,
      physicalPercentage: 0.0,
      publicationDateDoe: DateTime(2000),
      initialValidityContractDays: 0,
      initialValidityExecutionDays: 0,
      permissionContractId: {},
    );
  }

  /// Recuperando informações no banco de dados
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
      companyLeader: data['companyleader']?.toString(),
      generalNumber: data['generalnumber']?.toString(),
      automaticNumberSiafe: data['automaticnumbersiafe']?.toString(),
      regionalManager: data['regionalmanager']?.toString(),
      contractStatus: data['contractstatus']?.toString(),
      contractObjectDescription: data['objectcontractdescription']?.toString(),
      contractType: data['contracttype']?.toString(),
      workType: data['worktype']?.toString(), // <- novo
      contractCompaniesInvolved: data['companiesinvolved']?.toString(),
      urlContractPdf: data['urlpdf']?.toString(),
      cnoNumber: data['cnonumber']?.toString(),
      publicationDateDoe: (data['datapublicacaodoe'] as Timestamp?)?.toDate(),
      initialValueContract:
      (data['valorinicialdocontrato'] as num?)?.toDouble() ?? 0.0,
      physicalPercentage:
      (data['fisicalpercentage'] as num?)?.toDouble() ?? 0.0,
      financialPercentage:
      (data['financialpercentage'] as num?)?.toDouble() ?? 0.0,
      contractExtKm: (data['extkm'] as num?)?.toDouble() ?? 0.0,
      cnpjNumber: (data['cnpjnumber'] as num?)?.toInt(),
      cpfContractManager: (data['cpfcontractmanager'] as num?)?.toInt(),
      initialValidityExecutionDays:
      (data['initialvalidityexecutiondays'] as num?)?.toInt(),
      initialValidityContractDays:
      (data['initialvaliditycontractdays'] as num?)?.toInt(),
      existContract: data['existecontrato'] as bool? ?? false,
      permissionContractId:
      (data['permissionContractId'] as Map<String, dynamic>?)?.map(
            (userId, perm) =>
            MapEntry(userId, Map<String, bool>.from(perm as Map)),
      ) ??
          {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (contractNumber != null) 'contractnumber': contractNumber,
      if (contractType != null) 'contracttype': contractType,
      if (workType != null) 'worktype': workType, // <- novo
      if (contractServices != null) 'services': contractServices,
      if (mainContractHighway != null) 'maincontracthighway': mainContractHighway,
      if (summarySubjectContract != null) 'summarysubjectcontract': summarySubjectContract,
      if (contractNumberProcess != null) 'contractbiddingprocessnumber': contractNumberProcess,
      if (regionOfState != null) 'regionofstate': regionOfState,
      if (contractStatus != null) 'contractstatus': contractStatus,
      if (companyLeader != null) 'companyleader': companyLeader,
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
      if (initialValueContract != null) 'valorinicialdocontrato': initialValueContract,
      if (publicationDateDoe != null) 'datapublicacaodoe': publicationDateDoe,
      if (initialValidityExecutionDays != null) 'initialvalidityexecutiondays': initialValidityExecutionDays,
      if (initialValidityContractDays != null) 'initialvaliditycontractdays': initialValidityContractDays,
      if (existContract != null) 'existecontrato': existContract,
      if (permissionContractId.isNotEmpty) 'permissionContractId': permissionContractId,
    };
  }

  factory ContractData.fromJson(Map<String, dynamic> json, {String? id}) {
    return ContractData()
      ..id = id
      ..summarySubjectContract = json['summarysubjectcontract']
      ..contractNumber = json['contractnumber']
      ..contractStatus = json['contractstatus']
      ..contractType = json['contracttype']
      ..workType = json['worktype'] // <- novo
      ..contractServices = json['services']
      ..mainContractHighway = json['maincontracthighway']
      ..contractNumberProcess = json['contractbiddingprocessnumber']
      ..regionOfState = json['regionofstate']
      ..companyLeader = json['companyleader']
      ..contractCompaniesInvolved = json['companiesinvolved']
      ..automaticNumberSiafe = json['automaticnumbersiafe']
      ..contractObjectDescription = json['objectcontractdescription']
      ..managerPhoneNumber = json['managerphonenumber']
      ..contractManagerArtNumber = json['contractmanagerartnumber']
      ..regionalManager = json['regionalmanager']
      ..managerId = json['managerid']
      ..cnoNumber = json['cnonumber']
      ..cnpjNumber = (json['cnpjnumber'] as num?)?.toInt()
      ..cpfContractManager = (json['cpfcontractmanager'] as num?)?.toInt()
      ..contractExtKm = (json['extkm'] as num?)?.toDouble()
      ..financialPercentage = (json['financialpercentage'] as num?)?.toDouble()
      ..physicalPercentage = (json['fisicalpercentage'] as num?)?.toDouble()
      ..initialValueContract = (json['valorinicialdocontrato'] as num?)?.toDouble()
      ..publicationDateDoe = (json['datapublicacaodoe'] as Timestamp?)?.toDate()
      ..initialValidityExecutionDays = (json['initialvalidityexecutiondays'] as num?)?.toInt()
      ..initialValidityContractDays = (json['initialvaliditycontractdays'] as num?)?.toInt()
      ..existContract = json['existecontrato'] as bool? ?? false
      ..permissionContractId = (json['permissionContractId'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Map<String, bool>.from(value)),
      ) ?? {};
  }

  // Atualiza as permissões do usuário para um contrato específico usando o ID do documento
  void updateContractPermissions(
      String contractDocId,
      String permissionType,
      bool value,
      ) {
    if (permissionContractId[contractDocId] == null) {
      permissionContractId[contractDocId] = {};
    }
    permissionContractId[contractDocId]![permissionType] = value;
  }
}
