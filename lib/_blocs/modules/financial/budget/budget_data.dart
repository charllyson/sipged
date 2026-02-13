import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

class BudgetData {
  static const String collectionName = 'budgets';

  String? id;

  /// opcional: se você quiser filtrar orçamento dentro de um contrato/tela por contrato
  String? contractId;

  String? companyId;
  String? companyLabel;

  String? fundingSourceId;
  String? fundingSourceLabel;

  int year;

  /// opcional (ex: código LOA / dotação)
  String? budgetCode;

  /// opcional (ex: programa/ação/descritivo)
  String? description;

  double amount;

  String? pdfUrl;
  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  BudgetData({
    this.id,
    this.contractId,
    this.companyId,
    this.companyLabel,
    this.fundingSourceId,
    this.fundingSourceLabel,
    required this.year,
    this.budgetCode,
    this.description,
    required this.amount,
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static Map<String, dynamic> _readSnapData(DocumentSnapshot snap) {
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return snap.data() ?? <String, dynamic>{};
    }
    final raw = snap.data();
    return (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
  }

  static List<Attachment>? _toAttachments(dynamic v, {String? fallbackPdfUrl}) {
    if (v == null) {
      if (fallbackPdfUrl != null && fallbackPdfUrl.isNotEmpty) {
        return [
          Attachment(
            id: 'pdf',
            label: 'PDF do orçamento',
            url: fallbackPdfUrl,
            path: '',
            ext: '.pdf',
          ),
        ];
      }
      return null;
    }
    if (v is List) {
      return v.map<Attachment>((e) {
        if (e is Attachment) return e;
        return Attachment.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList();
    }
    return null;
  }

  factory BudgetData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);
    final pdfUrl = data['pdfUrl'] as String?;

    return BudgetData(
      id: (data['id'] as String?) ?? snap.id,
      contractId: data['contractId'] as String?,
      companyId: data['companyId'] as String?,
      companyLabel: (data['companyLabel'] as String?) ??
          (data['companyName'] as String?),
      fundingSourceId: data['fundingSourceId'] as String?,
      fundingSourceLabel: (data['fundingSourceLabel'] as String?) ??
          (data['fundingSource'] as String?),
      year: _toInt(data['year']),
      budgetCode: (data['budgetCode'] as String?)?.trim().isEmpty ?? true
          ? null
          : (data['budgetCode'] as String?)?.trim(),
      description: (data['description'] as String?)?.trim().isEmpty ?? true
          ? null
          : (data['description'] as String?)?.trim(),
      amount: _toDouble(data['amount']) ?? 0.0,
      pdfUrl: pdfUrl,
      attachments: _toAttachments(data['attachments'], fallbackPdfUrl: pdfUrl),
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'contractId': contractId,
      'companyId': companyId,
      'companyLabel': companyLabel,
      'fundingSourceId': fundingSourceId,
      'fundingSourceLabel': fundingSourceLabel,
      'year': year,
      'budgetCode': budgetCode,
      'description': description,
      'amount': amount,
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    }..removeWhere((k, v) => v == null);
  }

  BudgetData copyWith({
    String? id,
    String? contractId,
    String? companyId,
    String? companyLabel,
    String? fundingSourceId,
    String? fundingSourceLabel,
    int? year,
    String? budgetCode,
    String? description,
    double? amount,
    String? pdfUrl,
    List<Attachment>? attachments,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return BudgetData(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      companyId: companyId ?? this.companyId,
      companyLabel: companyLabel ?? this.companyLabel,
      fundingSourceId: fundingSourceId ?? this.fundingSourceId,
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,
      year: year ?? this.year,
      budgetCode: budgetCode ?? this.budgetCode,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
