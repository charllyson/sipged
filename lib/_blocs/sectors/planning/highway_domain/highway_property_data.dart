import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RightWayPropertyData extends ChangeNotifier {
  String? id;
  String? contractId;

  // Identificação
  String? ownerName;           // Proprietário / Posseiro
  String? cpfCnpj;             // CPF/CNPJ
  String? propertyType;        // URBANO | RURAL
  String? status;              // A NEGOCIAR | INDENIZADO | JUDICIALIZADO

  // Registro/Localização
  String? registryNumber;      // Nº Matrícula
  String? registryOffice;      // Cartório
  String? address;             // Logradouro/Descrição
  String? city;
  String? state;               // UF

  // Processos e datas
  String? processNumber;       // nº processo administrativo/judicial
  DateTime? notificationDate;  // data de notificação
  DateTime? inspectionDate;    // data de vistoria
  DateTime? agreementDate;     // data do acordo/indenização

  // Áreas (m²)
  double? totalArea;
  double? affectedArea;

  // Valores (R$)
  double? indemnityValue;

  // Contatos e observações
  String? phone;
  String? email;
  String? notes;

  // Auditoria
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  RightWayPropertyData({
    this.id,
    this.contractId,
    this.ownerName,
    this.cpfCnpj,
    this.propertyType,
    this.status,
    this.registryNumber,
    this.registryOffice,
    this.address,
    this.city,
    this.state,
    this.processNumber,
    this.notificationDate,
    this.inspectionDate,
    this.agreementDate,
    this.totalArea,
    this.affectedArea,
    this.indemnityValue,
    this.phone,
    this.email,
    this.notes,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory RightWayPropertyData.fromDocument(DocumentSnapshot snap) {
    final d = snap.data() as Map<String, dynamic>? ?? const {};
    DateTime? _ts(dynamic v) => (v is Timestamp) ? v.toDate() : null;
    double? _num(dynamic v) => (v is num) ? v.toDouble() : (v is String ? double.tryParse(v.replaceAll(',', '.')) : null);

    return RightWayPropertyData(
      id: snap.id,
      contractId: d['contractId'],
      ownerName: d['ownerName'],
      cpfCnpj: d['cpfCnpj'],
      propertyType: d['propertyType'],
      status: d['status'],
      registryNumber: d['registryNumber'],
      registryOffice: d['registryOffice'],
      address: d['address'],
      city: d['city'],
      state: d['state'],
      processNumber: d['processNumber'],
      notificationDate: _ts(d['notificationDate']),
      inspectionDate: _ts(d['inspectionDate']),
      agreementDate: _ts(d['agreementDate']),
      totalArea: _num(d['totalArea']),
      affectedArea: _num(d['affectedArea']),
      indemnityValue: _num(d['indemnityValue']),
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
    'registryNumber': registryNumber,
    'registryOffice': registryOffice,
    'address': address,
    'city': city,
    'state': state,
    'processNumber': processNumber,
    'notificationDate': notificationDate,
    'inspectionDate': inspectionDate,
    'agreementDate': agreementDate,
    'totalArea': totalArea,
    'affectedArea': affectedArea,
    'indemnityValue': indemnityValue,
    'phone': phone,
    'email': email,
    'notes': notes,
  };
}
