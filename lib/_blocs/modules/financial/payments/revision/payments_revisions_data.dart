import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class PaymentsRevisionsData extends ChangeNotifier {
  String? contractId;

  String? idRevisionPayment;
  String? processPaymentRevision;
  int? orderPaymentRevision;
  String? statePaymentRevision;
  String? observationPaymentRevision;
  double? valuePaymentRevision;
  String? orderBankPaymentRevision;
  String? electronicTicketPaymentRevision;
  String? fontPaymentRevision;
  DateTime? datePaymentRevision;
  double? taxPaymentRevision;

  // Legado: um único PDF
  String? pdfUrl;

  // 🆕 Multi-anexos
  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  PaymentsRevisionsData({
    this.contractId,
    this.idRevisionPayment,
    this.processPaymentRevision,
    this.orderPaymentRevision,
    this.statePaymentRevision,
    this.observationPaymentRevision,
    this.valuePaymentRevision,
    this.orderBankPaymentRevision,
    this.electronicTicketPaymentRevision,
    this.fontPaymentRevision,
    this.datePaymentRevision,
    this.taxPaymentRevision,
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory PaymentsRevisionsData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception("Pagamento de revisão não encontrado");
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Os dados do pagamento da revisão estão vazios");

    final contractId = snapshot.reference.parent.parent?.id;
    final revision = PaymentsRevisionsData.fromJson(data);
    revision.idRevisionPayment = snapshot.id;
    revision.contractId = contractId;
    return revision;
  }

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'idRevisionPayment': idRevisionPayment ?? '',
      'orderPaymentRevision': orderPaymentRevision ?? 0,
      'statePaymentRevision': statePaymentRevision ?? '',
      'observationPaymentRevision': observationPaymentRevision ?? '',
      'orderBankPaymentRevision': orderBankPaymentRevision ?? '',
      'datePaymentRevision': datePaymentRevision != null ? Timestamp.fromDate(datePaymentRevision!) : null,
      'numberProcessPaymentRevision': processPaymentRevision ?? '',
      'valuePaymentRevision': valuePaymentRevision ?? 0.0,
      'electronicTicketPaymentRevision': electronicTicketPaymentRevision ?? '',
      'fontPaymentRevision': fontPaymentRevision ?? '',
      'taxPaymentRevision': taxPaymentRevision ?? 0.0,
      // Legado
      'pdfUrl': pdfUrl,
      // 🆕 Multi-anexos
      'attachments': (attachments ?? const <Attachment>[]).map((a) => a.toMap()).toList(),
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
    };
  }

  factory PaymentsRevisionsData.fromJson(Map<String, dynamic> json) {
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

    return PaymentsRevisionsData(
      idRevisionPayment: json['idRevisionPayment'] ?? '',
      orderPaymentRevision: json['orderPaymentRevision'] ?? 0,
      statePaymentRevision: json['statePaymentRevision'] ?? '',
      observationPaymentRevision: json['observationPaymentRevision'] ?? '',
      orderBankPaymentRevision: json['orderBankPaymentRevision'] ?? '',
      datePaymentRevision: parseDate(json['datePaymentRevision']),
      processPaymentRevision: json['numberProcessPaymentRevision'] ?? '',
      valuePaymentRevision: parseDouble(json['valuePaymentRevision']),
      electronicTicketPaymentRevision: json['electronicTicketPaymentRevision'] ?? '',
      fontPaymentRevision: json['fontPaymentRevision'] ?? '',
      taxPaymentRevision: parseDouble(json['taxPaymentRevision']),
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

  factory PaymentsRevisionsData.fromMap(Map<String, dynamic> map) {
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

    List<Attachment>? parseAtts(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map<String, dynamic>>()
            .map((m) => Attachment.fromMap(m))
            .toList();
      }
      return null;
    }

    return PaymentsRevisionsData(
      contractId: map['contractId'],
      idRevisionPayment: map['idRevisionPayment'] ?? '',
      orderPaymentRevision: map['orderPaymentRevision'] ?? 0,
      datePaymentRevision: parseDate(map['datePaymentRevision']),
      statePaymentRevision: map['statePaymentRevision'] ?? '',
      observationPaymentRevision: map['observationPaymentRevision'] ?? '',
      orderBankPaymentRevision: map['orderBankPaymentRevision'] ?? '',
      processPaymentRevision: map['numberProcessPaymentRevision'] ?? '',
      valuePaymentRevision: parseDouble(map['valuePaymentRevision']) ?? 0.0,
      electronicTicketPaymentRevision: map['electronicTicketPaymentRevision'] ?? '',
      fontPaymentRevision: map['fontPaymentRevision'] ?? '',
      taxPaymentRevision: parseDouble(map['taxPaymentRevision']) ?? 0.0,
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
