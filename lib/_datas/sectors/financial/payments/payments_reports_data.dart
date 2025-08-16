import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class PaymentsReportData extends ChangeNotifier {
  /// Informações de medições
  String? contractId;

  String? idPaymentReport;
  int? orderPaymentReport;
  String? processPaymentReport;
  String? statePaymentReport;
  String? observationPaymentReport;
  double? valuePaymentReport;
  String? orderBankPaymentReport;
  String? electronicTicketPaymentReport;
  String? fontPaymentReport;
  DateTime? datePaymentReport;
  double? taxPaymentReport;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  PaymentsReportData({
    this.contractId,
    this.idPaymentReport,
    this.orderPaymentReport,
    this.processPaymentReport,
    this.statePaymentReport,
    this.observationPaymentReport,
    this.valuePaymentReport,
    this.orderBankPaymentReport,
    this.electronicTicketPaymentReport,
    this.fontPaymentReport,
    this.datePaymentReport,
    this.taxPaymentReport,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  /// Recuperando informações no banco de dados
  factory PaymentsReportData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Pagamento não encontrado");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Os dados do pagamento estão vazios");
    }

    final contractId = snapshot.reference.parent.parent?.id;

    final payment = PaymentsReportData.fromJson(data);
    payment.idPaymentReport = snapshot.id;
    payment.contractId = contractId;
    return payment;
  }

  /// Salvando no Firebase
  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'idPaymentReport': idPaymentReport,
      'orderPaymentReport': orderPaymentReport ?? 0,
      'processPaymentReport': processPaymentReport ?? '',
      'statePaymentReport': statePaymentReport ?? '',
      'observationPaymentReport': observationPaymentReport ?? '',
      'valuePaymentReport': valuePaymentReport ?? 0.0,
      'orderBankPaymentReport': orderBankPaymentReport ?? '',
      'electronicTicketPaymentReport': electronicTicketPaymentReport ?? '',
      'fontPaymentReport': fontPaymentReport ?? '',
      'datePaymentReport': datePaymentReport != null ? Timestamp.fromDate(datePaymentReport!) : null,
      'taxPaymentReport': taxPaymentReport ?? 0.0,
    };
  }

  /// Conversão padrão (usado com Firestore doc.data())
  factory PaymentsReportData.fromJson(Map<String, dynamic> json) {
    return PaymentsReportData(
      contractId: json['contractId'],
      idPaymentReport: json['idPaymentReport'] ?? '',
      orderPaymentReport: json['orderPaymentReport'] ?? 0,
      processPaymentReport: json['processPaymentReport'] ?? '',
      statePaymentReport: json['statePaymentReport'] ?? '',
      observationPaymentReport: json['observationPaymentReport'] ?? '',
      valuePaymentReport: (json['valuePaymentReport'] is num)
          ? (json['valuePaymentReport'] as num).toDouble()
          : double.tryParse(json['valuePaymentReport']?.toString() ?? '') ?? 0.0,
      orderBankPaymentReport: json['orderBankPaymentReport'] ?? '',
      electronicTicketPaymentReport: json['electronicTicketPaymentReport'] ?? '',
      fontPaymentReport: json['fontPaymentReport'] ?? '',
      datePaymentReport: (json['datePaymentReport'] as Timestamp?)?.toDate(),
      taxPaymentReport: (json['taxPaymentReport'] is num)
          ? (json['taxPaymentReport'] as num).toDouble()
          : double.tryParse(json['taxPaymentReport']?.toString() ?? '') ?? 0.0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] ?? '',
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: json['updatedBy'] ?? '',
      deletedAt: (json['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: json['deletedBy'] ?? '',
    );
  }

  /// Conversão auxiliar com tipos variados (map usado no importador Excel, por exemplo)
  factory PaymentsReportData.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return PaymentsReportData(
      contractId: map['contractId'],
      idPaymentReport: map['idPaymentReport'] ?? '',
      orderPaymentReport: map['orderPaymentReport'] ?? 0,
      processPaymentReport: map['processPaymentReport'] ?? '',
      statePaymentReport: map['statePaymentReport'] ?? '',
      observationPaymentReport: map['observationPaymentReport'] ?? '',
      valuePaymentReport: parseDouble(map['valuePaymentReport']) ?? 0.0,
      orderBankPaymentReport: map['orderBankPaymentReport'] ?? '',
      electronicTicketPaymentReport: map['electronicTicketPaymentReport'] ?? '',
      fontPaymentReport: map['fontPaymentReport'] ?? '',
      datePaymentReport: parseDate(map['datePaymentReport']),
      taxPaymentReport: parseDouble(map['taxPaymentReport']) ?? 0.0,
      createdAt: parseDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
    );
  }
}
