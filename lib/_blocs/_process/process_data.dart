import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// usa o mesmo modelo já existente no projeto
import 'package:siged/_widgets/list/files/attachment.dart';

class ProcessData extends ChangeNotifier {
  /// Identificação e metadados
  String? id;

  String? status;
  String? numberProcess;
  String? summarySubject;
  String? mainHighway;
  String? region;
  String? workType;
  String? services;
  double? ext;

  String? contractNumber;
  String? companyLeader;
  String? contractCompaniesInvolved;
  String? urlContractPdf;
  double? initialValueContract;

  DateTime? publicationDate;
  int? initialValidityExecution;
  int? initialValidityContract;

  /// 🆕 Lista de anexos com rótulo persistido no Firestore
  List<Attachment>? attachments;

  /// ACL por contrato
  Map<String, Map<String, bool>> permissionContractId = {};
  /// Metadados por participante
  Map<String, Map<String, dynamic>> participantsInfo = {};


  ProcessData({
    this.id,
    this.summarySubject,
    this.contractNumber,
    this.mainHighway,
    this.services,
    this.ext,
    this.region,
    this.companyLeader,
    this.numberProcess,
    this.status,
    this.workType,
    this.contractCompaniesInvolved,
    this.urlContractPdf,
    this.initialValidityExecution,
    this.initialValidityContract,
    this.publicationDate,
    this.initialValueContract,
    this.permissionContractId = const {},
    Map<String, Map<String, dynamic>>? participantsInfo,
    this.attachments,
  }) : participantsInfo = participantsInfo ?? {};

  factory ProcessData.empty() {
    return ProcessData(
      id: null,
      contractNumber: '',
      mainHighway: '',
      services: '',
      summarySubject: '',
      region: '',
      companyLeader: '',
      numberProcess: '',
      status: '',
      workType: '',
      contractCompaniesInvolved: '',
      urlContractPdf: '',
      initialValueContract: 0.0,
      ext: 0.0,
      publicationDate: DateTime(2000),
      initialValidityContract: 0,
      initialValidityExecution: 0,
      permissionContractId: {},
      participantsInfo: {},
      attachments: const <Attachment>[],
    );
  }

  static List<Attachment>? _toAttachments(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return null;
  }

  /// Recuperando informações no banco de dados
  factory ProcessData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Contrato não encontrado");
    }
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Os dados do contrato estão vazios");
    }

    return ProcessData(
      id: snapshot.id,
      contractNumber: data['contractnumber']?.toString(),
      summarySubject: data['summarysubjectcontract']?.toString(),
      numberProcess: data['contractbiddingprocessnumber']?.toString(),
      mainHighway: data['maincontracthighway']?.toString(),
      services: data['services']?.toString(),
      region: data['regionofstate']?.toString(),
      companyLeader: data['companyleader']?.toString(),
      status: data['contractstatus']?.toString(),
      workType: data['worktype']?.toString(),
      contractCompaniesInvolved: data['companiesinvolved']?.toString(),

      // 👇 lê novo ou legado
      urlContractPdf: (data['urlContractPdf'] ?? data['urlpdf'])?.toString(),

      publicationDate: (data['datapublicacaodoe'] as Timestamp?)?.toDate(),
      initialValueContract:
      (data['valorinicialdocontrato'] as num?)?.toDouble() ?? 0.0,
      ext: (data['extkm'] as num?)?.toDouble() ?? 0.0,
      initialValidityExecution:
      (data['initialvalidityexecutiondays'] as num?)?.toInt(),
      initialValidityContract:
      (data['initialvaliditycontractdays'] as num?)?.toInt(),
      permissionContractId:
      (data['permissionContractId'] as Map<String, dynamic>?)?.map(
            (userId, perm) =>
            MapEntry(userId, Map<String, bool>.from(perm as Map)),
      ) ??
          {},
      participantsInfo:
      (data['participantsInfo'] as Map<String, dynamic>?)?.map(
            (uid, meta) =>
            MapEntry(uid, Map<String, dynamic>.from(meta as Map)),
      ) ??
          {},
      attachments: _toAttachments(data['attachments']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (contractNumber != null) 'contractnumber': contractNumber,
      if (workType != null) 'worktype': workType,
      if (services != null) 'services': services,
      if (mainHighway != null) 'maincontracthighway': mainHighway,
      if (summarySubject != null) 'summarysubjectcontract': summarySubject,
      if (numberProcess != null) 'contractbiddingprocessnumber': numberProcess,
      if (region != null) 'regionofstate': region,
      if (status != null) 'contractstatus': status,
      if (companyLeader != null) 'companyleader': companyLeader,
      if (contractCompaniesInvolved != null) 'companiesinvolved': contractCompaniesInvolved,
      if (ext != null) 'extkm': ext,
      if (initialValueContract != null) 'valorinicialdocontrato': initialValueContract,
      if (publicationDate != null) 'datapublicacaodoe': publicationDate,
      if (initialValidityExecution != null) 'initialvalidityexecutiondays': initialValidityExecution,
      if (initialValidityContract != null) 'initialvaliditycontractdays': initialValidityContract,
      if (permissionContractId.isNotEmpty) 'permissionContractId': permissionContractId,
      if (participantsInfo.isNotEmpty) 'participantsInfo': participantsInfo,
      if (urlContractPdf != null && urlContractPdf!.isNotEmpty) 'urlContractPdf': urlContractPdf,
      if (attachments != null) 'attachments': attachments!.map((e) => e.toMap()).toList(),
    };
  }

  factory ProcessData.fromJson(Map<String, dynamic> json, {String? id}) {
    List<Attachment>? _readAtt(dynamic v) =>
        (v is List) ? v.map((e) => Attachment.fromMap(Map<String,dynamic>.from(e))).toList() : null;

    return ProcessData()
      ..id = id
      ..summarySubject = json['summarysubjectcontract']
      ..contractNumber = json['contractnumber']
      ..status = json['contractstatus']
      ..workType = json['worktype']
      ..services = json['services']
      ..mainHighway = json['maincontracthighway']
      ..numberProcess = json['contractbiddingprocessnumber']
      ..region = json['regionofstate']
      ..companyLeader = json['companyleader']
      ..contractCompaniesInvolved = json['companiesinvolved']
      ..ext = (json['extkm'] as num?)?.toDouble()
      ..initialValueContract = (json['valorinicialdocontrato'] as num?)?.toDouble()
      ..publicationDate = (json['datapublicacaodoe'] as Timestamp?)?.toDate()
      ..initialValidityExecution = (json['initialvalidityexecutiondays'] as num?)?.toInt()
      ..initialValidityContract = (json['initialvaliditycontractdays'] as num?)?.toInt()
      ..permissionContractId = (json['permissionContractId'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Map<String, bool>.from(value)),
      ) ?? {}
      ..participantsInfo = (json['participantsInfo'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))) ??
          {}
      ..urlContractPdf = (json['urlContractPdf'] ?? json['urlpdf']) as String?
      ..attachments = _readAtt(json['attachments']);
  }

  // Atualiza as permissões do usuário para um contrato específico usando o ID do documento
  void updateContractPermissions(String contractDocId, String permissionType, bool value) {
    if (permissionContractId[contractDocId] == null) {
      permissionContractId[contractDocId] = {};
    }
    permissionContractId[contractDocId]![permissionType] = value;
  }

  // ---- Helpers locais de participantes (inalterados) ----
  void upsertParticipantLocal(
      String uid, {
        bool read = true,
        bool edit = false,
        bool delete = false,
        Map<String, dynamic>? meta,
      }) {
    permissionContractId[uid] = {'read': read, 'edit': edit, 'delete': delete};
    if (meta != null) {
      final m = Map<String, dynamic>.from(participantsInfo[uid] ?? {});
      m.addAll(meta);
      participantsInfo[uid] = m;
    }
    notifyListeners();
  }

  void removeParticipantLocal(String uid) {
    permissionContractId.remove(uid);
    participantsInfo.remove(uid);
    notifyListeners();
  }
}
