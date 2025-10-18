// lib/_blocs/sectors/planning/laneRegularization/lane_regularization_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LaneRegularizationData extends ChangeNotifier {
  String? id;
  String? contractId;

  // Identificação do imóvel/proprietário
  String? ownerName;           // Proprietário / Posseiro
  String? cpfCnpj;             // CPF/CNPJ
  String? propertyType;        // URBANO | RURAL
  String? status;              // A NEGOCIAR | INDENIZADO | JUDICIALIZADO
  String? currentStage;        // ETAPA ATUAL (pipeline)
  String? negotiationStatus;   // Em negociação | Acordo fechado | Sem acordo
  String? indemnityType;       // Amigável | Judicial
  String? useOfLand;           // Residencial | Comercial | Rural | Misto
  bool?   hasImprovements;     // Benfeitorias (sim/não)
  String? improvementsSummary; // resumo breve das benfeitorias

  // Registro/Localização
  String? registryNumber;      // Nº Matrícula
  String? registryOffice;      // Cartório
  String? address;             // Logradouro/Descrição
  String? city;
  String? state;               // UF

  // Geometria / Rodovia
  String? roadId;              // ID da rodovia no seu banco (opcional)
  String? roadName;            // Ex.: AL-101
  String? segmentId;           // Trecho/Segmento (se houver)
  double? kmStart;             // km inicial do impacto
  double? kmEnd;               // km final do impacto
  String? laneSide;            // Lado: ESQ | DIR | CENTRAL
  double? corridorWidthM;      // largura projetada da faixa de domínio/obras
  double? centroidLat;
  double? centroidLng;
  double? geoAreaComputed;     // área calculada do polígono (m²), se houver

  // Processos e marcos legais
  String? processNumber;       // nº processo administrativo/judicial
  String? dupNumber;           // nº do Decreto de Utilidade Pública (DUP)
  DateTime? dupDate;
  String? doPublication;       // nº DO/Seção/Página
  DateTime? doPublicationDate;
  String? notificationAR;      // nº do AR dos Correios (Aviso de Recebimento)

  // Datas operacionais
  DateTime? notificationDate;  // notificação
  DateTime? inspectionDate;    // vistoria técnica
  DateTime? appraisalDate;     // data do laudo de avaliação
  DateTime? agreementDate;     // acordo/indenização
  DateTime? paymentDate;       // pagamento efetivo
  DateTime? possessionDate;    // imissão de posse
  DateTime? evictionDate;      // desocupação
  DateTime? registryUpdateDate;// averbação/baixa no registro

  // Avaliação
  String? appraisalNumber;     // nº do laudo
  String? appraiserName;       // nome do perito/empresa
  String? appraisalMethod;     // NBR 14653 / método adotado
  double? appraisalValue;      // valor avaliado (R$)

  // Áreas (m²)
  double? totalArea;           // área do imóvel
  double? affectedArea;        // área atingida

  // Valores (R$)
  double? indemnityValue;      // valor pactuado/indenização
  double? ownerCounterValue;   // contraproposta do proprietário
  double? govProposalValue;    // proposta do órgão

  // Pagamento / Conta
  String? paymentForm;         // TED | Depósito judicial | RPV | Precatório
  String? bankName;
  String? bankAgency;
  String? bankAccount;
  String? pixKey;

  // Rural (quando aplicável)
  bool?   isRural;
  String? carNumber;           // CAR
  String? ccirNumber;          // CCIR
  String? nirfNumber;          // NIRF
  String? incraSncr;           // SNCR

  // Judicial
  bool?   isJudicial;
  String? courtName;           // Vara/Comarca
  String? caseNumber;          // nº do processo
  String? rpvOrPrecatorio;     // RPV | Precatório
  double? depositInCourtValue; // valor depositado em juízo

  // Social / Reassentamento
  bool?   resettlementRequired;
  int?    familyCount;
  String? socialNotes;

  // Contatos e observações
  String? phone;
  String? email;
  String? notes;

  // Auditoria
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  LaneRegularizationData({
    this.id, this.contractId,
    this.ownerName, this.cpfCnpj, this.propertyType, this.status,
    this.currentStage, this.negotiationStatus, this.indemnityType,
    this.useOfLand, this.hasImprovements, this.improvementsSummary,
    this.registryNumber, this.registryOffice, this.address, this.city, this.state,
    this.roadId, this.roadName, this.segmentId, this.kmStart, this.kmEnd, this.laneSide,
    this.corridorWidthM, this.centroidLat, this.centroidLng, this.geoAreaComputed,
    this.processNumber, this.dupNumber, this.dupDate, this.doPublication, this.doPublicationDate, this.notificationAR,
    this.notificationDate, this.inspectionDate, this.appraisalDate, this.agreementDate, this.paymentDate, this.possessionDate, this.evictionDate, this.registryUpdateDate,
    this.appraisalNumber, this.appraiserName, this.appraisalMethod, this.appraisalValue,
    this.totalArea, this.affectedArea, this.indemnityValue,
    this.ownerCounterValue, this.govProposalValue,
    this.paymentForm, this.bankName, this.bankAgency, this.bankAccount, this.pixKey,
    this.isRural, this.carNumber, this.ccirNumber, this.nirfNumber, this.incraSncr,
    this.isJudicial, this.courtName, this.caseNumber, this.rpvOrPrecatorio, this.depositInCourtValue,
    this.resettlementRequired, this.familyCount, this.socialNotes,
    this.phone, this.email, this.notes,
    this.createdAt, this.createdBy, this.updatedAt, this.updatedBy,
  });

  static List<String> typeItems = ['URBANO', 'RURAL'];
  static List<String> statusItems = ['A NEGOCIAR', 'INDENIZADO', 'JUDICIALIZADO'];
  static List<String> stageItems = [
    'CADASTRO', 'DUP/NOTIFICAÇÃO', 'VISTORIA/LAUDO',
    'NEGOCIAÇÃO', 'ACORDO', 'PAGAMENTO', 'POSSE/DESOCUPAÇÃO',
    'BAIXA CARTORIAL', 'CONCLUÍDO', 'JUDICIAL'
  ];
  static List<String> negotiationItems = ['Em negociação', 'Acordo fechado', 'Sem acordo'];
  static List<String> indemnityTypeItems = ['Amigável', 'Judicial'];
  static List<String> paymentFormItems = ['TED', 'Depósito judicial', 'RPV', 'Precatório'];
  static List<String> laneSideItems = ['ESQ', 'DIR', 'CENTRAL'];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LaneRegularizationData &&
              id != null && other.id != null && id == other.id;

  @override
  int get hashCode => (id ?? '').hashCode;

  factory LaneRegularizationData.fromDocument(DocumentSnapshot snap) {
    final d = snap.data() as Map<String, dynamic>? ?? const {};
    DateTime? _ts(dynamic v) => (v is Timestamp) ? v.toDate() : null;
    double? _num(dynamic v) => (v is num)
        ? v.toDouble()
        : (v is String ? double.tryParse(v.replaceAll(',', '.')) : null);

    return LaneRegularizationData(
      id: snap.id,
      contractId: d['contractId'],
      ownerName: d['ownerName'],
      cpfCnpj: d['cpfCnpj'],
      propertyType: d['propertyType'],
      status: d['status'],
      currentStage: d['currentStage'],
      negotiationStatus: d['negotiationStatus'],
      indemnityType: d['indemnityType'],
      useOfLand: d['useOfLand'],
      hasImprovements: d['hasImprovements'],
      improvementsSummary: d['improvementsSummary'],
      registryNumber: d['registryNumber'],
      registryOffice: d['registryOffice'],
      address: d['address'],
      city: d['city'],
      state: d['state'],
      roadId: d['roadId'],
      roadName: d['roadName'],
      segmentId: d['segmentId'],
      kmStart: _num(d['kmStart']),
      kmEnd: _num(d['kmEnd']),
      laneSide: d['laneSide'],
      corridorWidthM: _num(d['corridorWidthM']),
      centroidLat: _num(d['centroidLat']),
      centroidLng: _num(d['centroidLng']),
      geoAreaComputed: _num(d['geoAreaComputed']),
      processNumber: d['processNumber'],
      dupNumber: d['dupNumber'],
      dupDate: _ts(d['dupDate']),
      doPublication: d['doPublication'],
      doPublicationDate: _ts(d['doPublicationDate']),
      notificationAR: d['notificationAR'],
      notificationDate: _ts(d['notificationDate']),
      inspectionDate: _ts(d['inspectionDate']),
      appraisalDate: _ts(d['appraisalDate']),
      agreementDate: _ts(d['agreementDate']),
      paymentDate: _ts(d['paymentDate']),
      possessionDate: _ts(d['possessionDate']),
      evictionDate: _ts(d['evictionDate']),
      registryUpdateDate: _ts(d['registryUpdateDate']),
      appraisalNumber: d['appraisalNumber'],
      appraiserName: d['appraiserName'],
      appraisalMethod: d['appraisalMethod'],
      appraisalValue: _num(d['appraisalValue']),
      totalArea: _num(d['totalArea']),
      affectedArea: _num(d['affectedArea']),
      indemnityValue: _num(d['indemnityValue']),
      ownerCounterValue: _num(d['ownerCounterValue']),
      govProposalValue: _num(d['govProposalValue']),
      paymentForm: d['paymentForm'],
      bankName: d['bankName'],
      bankAgency: d['bankAgency'],
      bankAccount: d['bankAccount'],
      pixKey: d['pixKey'],
      isRural: d['isRural'],
      carNumber: d['carNumber'],
      ccirNumber: d['ccirNumber'],
      nirfNumber: d['nirfNumber'],
      incraSncr: d['incraSncr'],
      isJudicial: d['isJudicial'],
      courtName: d['courtName'],
      caseNumber: d['caseNumber'],
      rpvOrPrecatorio: d['rpvOrPrecatorio'],
      depositInCourtValue: _num(d['depositInCourtValue']),
      resettlementRequired: d['resettlementRequired'],
      familyCount: (d['familyCount'] is int) ? d['familyCount'] : (d['familyCount'] is num ? (d['familyCount'] as num).toInt() : null),
      socialNotes: d['socialNotes'],
      phone: d['phone'],
      email: d['email'],
      notes: d['notes'],
      createdAt: _ts(d['createdAt']),
      createdBy: d['createdBy'],
      updatedAt: _ts(d['updatedAt']),
      updatedBy: d['updatedBy'],
    );
  }

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'ownerName': ownerName,
    'cpfCnpj': cpfCnpj,
    'propertyType': propertyType,
    'status': status,
    'currentStage': currentStage,
    'negotiationStatus': negotiationStatus,
    'indemnityType': indemnityType,
    'useOfLand': useOfLand,
    'hasImprovements': hasImprovements,
    'improvementsSummary': improvementsSummary,
    'registryNumber': registryNumber,
    'registryOffice': registryOffice,
    'address': address,
    'city': city,
    'state': state,
    'roadId': roadId,
    'roadName': roadName,
    'segmentId': segmentId,
    'kmStart': kmStart,
    'kmEnd': kmEnd,
    'laneSide': laneSide,
    'corridorWidthM': corridorWidthM,
    'centroidLat': centroidLat,
    'centroidLng': centroidLng,
    'geoAreaComputed': geoAreaComputed,
    'processNumber': processNumber,
    'dupNumber': dupNumber,
    'dupDate': dupDate,
    'doPublication': doPublication,
    'doPublicationDate': doPublicationDate,
    'notificationAR': notificationAR,
    'notificationDate': notificationDate,
    'inspectionDate': inspectionDate,
    'appraisalDate': appraisalDate,
    'agreementDate': agreementDate,
    'paymentDate': paymentDate,
    'possessionDate': possessionDate,
    'evictionDate': evictionDate,
    'registryUpdateDate': registryUpdateDate,
    'appraisalNumber': appraisalNumber,
    'appraiserName': appraiserName,
    'appraisalMethod': appraisalMethod,
    'appraisalValue': appraisalValue,
    'totalArea': totalArea,
    'affectedArea': affectedArea,
    'indemnityValue': indemnityValue,
    'ownerCounterValue': ownerCounterValue,
    'govProposalValue': govProposalValue,
    'paymentForm': paymentForm,
    'bankName': bankName,
    'bankAgency': bankAgency,
    'bankAccount': bankAccount,
    'pixKey': pixKey,
    'isRural': isRural,
    'carNumber': carNumber,
    'ccirNumber': ccirNumber,
    'nirfNumber': nirfNumber,
    'incraSncr': incraSncr,
    'isJudicial': isJudicial,
    'courtName': courtName,
    'caseNumber': caseNumber,
    'rpvOrPrecatorio': rpvOrPrecatorio,
    'depositInCourtValue': depositInCourtValue,
    'resettlementRequired': resettlementRequired,
    'familyCount': familyCount,
    'socialNotes': socialNotes,
    'phone': phone,
    'email': email,
    'notes': notes,
  };
}
