import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

// ⬇️ mesmo Attachment usado nos outros módulos
import 'package:siged/_widgets/list/files/attachment.dart';

class PaymentsReportData extends ChangeNotifier {
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

  // Legado (um único PDF)
  String? pdfUrl;

  // 🆕 Multi-anexos
  List<Attachment>? attachments;

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
    this.pdfUrl,
    this.attachments, // 🆕
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory PaymentsReportData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception("Pagamento não encontrado");
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Os dados do pagamento estão vazios");

    final contractId = snapshot.reference.parent.parent?.id;
    final payment = PaymentsReportData.fromJson(data);
    payment.idPaymentReport = snapshot.id;
    payment.contractId = contractId;
    return payment;
  }

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

      // Legado
      'pdfUrl': pdfUrl,

      // 🆕 Multi-anexos
      'attachments': (attachments ?? const <Attachment>[])
          .map((a) => a.toMap())
          .toList(),
    };
  }

  factory PaymentsReportData.fromJson(Map<String, dynamic> json) {
    List<Attachment>? parseAtts(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map<String, dynamic>>()
            .map((m) => Attachment.fromMap(m))
            .toList();
      }
      return null;
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    DateTime? parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return PaymentsReportData(
      contractId: json['contractId'],
      idPaymentReport: json['idPaymentReport'] ?? '',
      orderPaymentReport: json['orderPaymentReport'] ?? 0,
      processPaymentReport: json['processPaymentReport'] ?? '',
      statePaymentReport: json['statePaymentReport'] ?? '',
      observationPaymentReport: json['observationPaymentReport'] ?? '',
      valuePaymentReport: parseDouble(json['valuePaymentReport']),
      orderBankPaymentReport: json['orderBankPaymentReport'] ?? '',
      electronicTicketPaymentReport: json['electronicTicketPaymentReport'] ?? '',
      fontPaymentReport: json['fontPaymentReport'] ?? '',
      datePaymentReport: parseDate(json['datePaymentReport']),
      taxPaymentReport: parseDouble(json['taxPaymentReport']),
      pdfUrl: json['pdfUrl'] as String?,
      attachments: parseAtts(json['attachments']),
      createdAt: parseDate(json['createdAt']),
      createdBy: json['createdBy'] ?? '',
      updatedAt: parseDate(json['updatedAt']),
      updatedBy: json['updatedBy'] ?? '',
      deletedAt: parseDate(json['deletedAt']),
      deletedBy: json['deletedBy'] ?? '',
    );
  }

  factory PaymentsReportData.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    double? parseDouble(val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    List<Attachment>? parseAtts(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map<String, dynamic>>()
            .map((m) => Attachment.fromMap(m))
            .toList();
      }
      return null;
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
      pdfUrl: map['pdfUrl'] as String?,
      attachments: parseAtts(map['attachments']),
      createdAt: parseDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
    );
  }
}
