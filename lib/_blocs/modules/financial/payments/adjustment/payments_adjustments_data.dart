import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class PaymentsAdjustmentsData extends ChangeNotifier {
  String? contractId;

  String? idPaymentAdjustment;
  int? orderPaymentAdjustment;
  String? processPaymentAdjustment;
  String? statePaymentAdjustment;
  String? observationPaymentAdjustment;
  double? valuePaymentAdjustment;
  String? orderBankPaymentAdjustment;
  String? electronicTicketPaymentAdjustment;
  String? fontPaymentAdjustment;
  DateTime? datePaymentAdjustment;
  double? taxPaymentAdjustment;

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

  PaymentsAdjustmentsData({
    this.contractId,
    this.idPaymentAdjustment,
    this.processPaymentAdjustment,
    this.orderPaymentAdjustment,
    this.statePaymentAdjustment,
    this.observationPaymentAdjustment,
    this.valuePaymentAdjustment,
    this.orderBankPaymentAdjustment,
    this.electronicTicketPaymentAdjustment,
    this.fontPaymentAdjustment,
    this.datePaymentAdjustment,
    this.taxPaymentAdjustment,
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory PaymentsAdjustmentsData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception("Ajuste não encontrado");
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Os dados do ajuste estão vazios");

    final contractId = snapshot.reference.parent.parent?.id;
    final adjustment = PaymentsAdjustmentsData.fromJson(data);
    adjustment.idPaymentAdjustment = snapshot.id;
    adjustment.contractId = contractId;
    return adjustment;
  }

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'idPaymentAdjustment': idPaymentAdjustment ?? '',
      'orderPaymentAdjustment': orderPaymentAdjustment ?? 0,
      'processPaymentAdjustment': processPaymentAdjustment ?? '',
      'statePaymentAdjustment': statePaymentAdjustment ?? '',
      'observationPaymentAdjustment': observationPaymentAdjustment ?? '',
      'valuePaymentAdjustment': valuePaymentAdjustment ?? 0.0,
      'orderBankPaymentAdjustment': orderBankPaymentAdjustment ?? '',
      'electronicTicketPaymentAdjustment': electronicTicketPaymentAdjustment ?? '',
      'fontPaymentAdjustment': fontPaymentAdjustment ?? '',
      'datePaymentAdjustment': datePaymentAdjustment != null ? Timestamp.fromDate(datePaymentAdjustment!) : null,
      'taxPaymentAdjustment': taxPaymentAdjustment ?? 0.0,
      'pdfUrl': pdfUrl, // legado
      'attachments': (attachments ?? const <Attachment>[]).map((a) => a.toMap()).toList(),
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
    };
  }

  factory PaymentsAdjustmentsData.fromJson(Map<String, dynamic> json) {
    List<Attachment>? parseAtts(dynamic v) {
      if (v is List) {
        return v.whereType<Map<String, dynamic>>().map(Attachment.fromMap).toList();
      }
      return null;
    }

    return PaymentsAdjustmentsData(
      contractId: json['contractId'],
      idPaymentAdjustment: json['idPaymentAdjustment'] ?? '',
      orderPaymentAdjustment: json['orderPaymentAdjustment'] ?? 0,
      processPaymentAdjustment: json['processPaymentAdjustment'] ?? '',
      statePaymentAdjustment: json['statePaymentAdjustment'] ?? '',
      observationPaymentAdjustment: json['observationPaymentAdjustment'] ?? '',
      valuePaymentAdjustment: (json['valuePaymentAdjustment'] is num)
          ? (json['valuePaymentAdjustment'] as num).toDouble()
          : double.tryParse(json['valuePaymentAdjustment']?.toString() ?? '') ?? 0.0,
      orderBankPaymentAdjustment: json['orderBankPaymentAdjustment'] ?? '',
      electronicTicketPaymentAdjustment: json['electronicTicketPaymentAdjustment'] ?? '',
      fontPaymentAdjustment: json['fontPaymentAdjustment'] ?? '',
      datePaymentAdjustment: (json['datePaymentAdjustment'] as Timestamp?)?.toDate(),
      taxPaymentAdjustment: (json['taxPaymentAdjustment'] is num)
          ? (json['taxPaymentAdjustment'] as num).toDouble()
          : double.tryParse(json['taxPaymentAdjustment']?.toString() ?? '') ?? 0.0,
      pdfUrl: json['pdfUrl'] as String?,
      attachments: parseAtts(json['attachments']),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] ?? '',
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: json['updatedBy'] ?? '',
      deletedAt: (json['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: json['deletedBy'] ?? '',
    );
  }

  factory PaymentsAdjustmentsData.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    List<Attachment>? parseAtts(dynamic v) {
      if (v is List) {
        return v.whereType<Map<String, dynamic>>().map(Attachment.fromMap).toList();
      }
      return null;
    }

    return PaymentsAdjustmentsData(
      contractId: map['contractId'],
      idPaymentAdjustment: map['idPaymentAdjustment'] ?? '',
      orderPaymentAdjustment: map['orderPaymentAdjustment'] ?? 0,
      processPaymentAdjustment: map['processPaymentAdjustment'] ?? '',
      statePaymentAdjustment: map['statePaymentAdjustment'] ?? '',
      observationPaymentAdjustment: map['observationPaymentAdjustment'] ?? '',
      valuePaymentAdjustment: parseDouble(map['valuePaymentAdjustment']) ?? 0.0,
      orderBankPaymentAdjustment: map['orderBankPaymentAdjustment'] ?? '',
      electronicTicketPaymentAdjustment: map['electronicTicketPaymentAdjustment'] ?? '',
      fontPaymentAdjustment: map['fontPaymentAdjustment'] ?? '',
      datePaymentAdjustment: parseDate(map['datePaymentAdjustment']),
      taxPaymentAdjustment: parseDouble(map['taxPaymentAdjustment']) ?? 0.0,
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
