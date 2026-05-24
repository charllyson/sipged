import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class RevisionPaidData {
  static const String collectionName = 'revisionPayments';

  String? id;

  String? contractId;
  String? revisionId;
  int? revisionOrder;

  String? fundingSourceId;
  String? fundingSourceLabel;

  DateTime? paymentDate;
  double? paymentValue;

  DateTime? inssPaymentDate;
  double? inssPaymentValue;

  DateTime? irpfPaymentDate;
  double? irpfPaymentValue;

  DateTime? issPaymentDate;
  double? issPaymentValue;

  String? note;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  List<Attachment>? attachments;

  RevisionPaidData({
    this.id,
    this.contractId,
    this.revisionId,
    this.revisionOrder,
    this.fundingSourceId,
    this.fundingSourceLabel,
    this.paymentDate,
    this.paymentValue,
    this.inssPaymentDate,
    this.inssPaymentValue,
    this.irpfPaymentDate,
    this.irpfPaymentValue,
    this.issPaymentDate,
    this.issPaymentValue,
    this.note,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.attachments,
  });

  static Map<String, dynamic> _readSnapData(DocumentSnapshot snap) {
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return snap.data() ?? <String, dynamic>{};
    }

    final raw = snap.data();

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    return <String, dynamic>{};
  }

  static dynamic _first(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        return data[key];
      }
    }

    return null;
  }

  static String? _toStringValue(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    return text;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is num) return value.toInt();

    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9-]'), '').trim();

      if (clean.isEmpty) return null;

      return int.tryParse(clean);
    }

    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) return value.toDouble();

    if (value is String) {
      var clean = value
          .trim()
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .trim();

      if (clean.isEmpty) return null;

      final hasComma = clean.contains(',');
      final hasDot = clean.contains('.');

      if (hasComma) {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(clean);
      }

      if (hasDot) {
        return double.tryParse(clean);
      }

      return double.tryParse(clean);
    }

    return null;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is Timestamp) return value.toDate();

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      final clean = value.trim();

      if (clean.isEmpty) return null;

      final iso = DateTime.tryParse(clean);
      if (iso != null) return iso;

      final parts = clean.split('/');

      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day == null || month == null || year == null) return null;

        final parsed = DateTime(year, month, day);

        if (parsed.day == day &&
            parsed.month == month &&
            parsed.year == year) {
          return parsed;
        }
      }
    }

    return null;
  }

  static List<Attachment>? _toAttachments(dynamic value) {
    if (value == null) return null;

    if (value is! List) return null;

    final list = <Attachment>[];

    for (final item in value) {
      if (item is Attachment) {
        list.add(item);
      } else if (item is Map) {
        list.add(
          Attachment.fromMap(
            Map<String, dynamic>.from(item),
          ),
        );
      }
    }

    return list.isEmpty ? null : list;
  }

  static RevisionPaidData _fromData({
    required Map<String, dynamic> data,
    String? documentId,
    String? contractIdFromPath,
    String? revisionIdFromPath,
  }) {
    return RevisionPaidData(
      id: _toStringValue(_first(data, const ['id'])) ?? documentId,
      contractId: _toStringValue(
        _first(
          data,
          const [
            'contractId',
            'contract_id',
            'idContrato',
            'uidContract',
            'uidcontract',
          ],
        ),
      ) ??
          contractIdFromPath,
      revisionId: _toStringValue(
        _first(
          data,
          const [
            'revisionId',
            'revision_id',
            'idRevision',
            'idRevisao',
            'revisaoId',
          ],
        ),
      ) ??
          revisionIdFromPath,
      revisionOrder: _toInt(
        _first(
          data,
          const [
            'revisionOrder',
            'revisionorder',
            'revision_order',
            'order',
            'ordemRevisao',
            'ordem',
          ],
        ),
      ),
      fundingSourceId: _toStringValue(
        _first(
          data,
          const [
            'fundingSourceId',
            'funding_source_id',
            'fonteRecursoId',
            'sourceId',
          ],
        ),
      ),
      fundingSourceLabel: _toStringValue(
        _first(
          data,
          const [
            'fundingSourceLabel',
            'funding_source_label',
            'fonteRecurso',
            'fonteRecursoLabel',
            'fonte',
            'sourceLabel',
          ],
        ),
      ),
      paymentDate: _toDate(
        _first(
          data,
          const [
            'paymentDate',
            'paymentdate',
            'payment_date',
            'date',
            'dataPagamento',
            'dataDoPagamento',
          ],
        ),
      ),
      paymentValue: _toDouble(
        _first(
          data,
          const [
            'paymentValue',
            'paymentvalue',
            'payment_value',
            'value',
            'valorPagamento',
            'valorDoPagamento',
            'paidValue',
            'paid_value',
            'valorPago',
          ],
        ),
      ),
      inssPaymentDate: _toDate(
        _first(
          data,
          const [
            'inssPaymentDate',
            'insspaymentdate',
            'inss_payment_date',
            'dataPagamentoInss',
            'dataInss',
            'inssDate',
          ],
        ),
      ),
      inssPaymentValue: _toDouble(
        _first(
          data,
          const [
            'inssPaymentValue',
            'insspaymentvalue',
            'inss_payment_value',
            'valorPagamentoInss',
            'valorInss',
            'inssValue',
          ],
        ),
      ),
      irpfPaymentDate: _toDate(
        _first(
          data,
          const [
            'irpfPaymentDate',
            'irpfpaymentdate',
            'irpf_payment_date',
            'dataPagamentoIrpf',
            'dataIrpf',
            'irpfDate',
          ],
        ),
      ),
      irpfPaymentValue: _toDouble(
        _first(
          data,
          const [
            'irpfPaymentValue',
            'irpfpaymentvalue',
            'irpf_payment_value',
            'valorPagamentoIrpf',
            'valorIrpf',
            'irpfValue',
          ],
        ),
      ),
      issPaymentDate: _toDate(
        _first(
          data,
          const [
            'issPaymentDate',
            'isspaymentdate',
            'iss_payment_date',
            'dataPagamentoIss',
            'dataIss',
            'issDate',
          ],
        ),
      ),
      issPaymentValue: _toDouble(
        _first(
          data,
          const [
            'issPaymentValue',
            'isspaymentvalue',
            'iss_payment_value',
            'valorPagamentoIss',
            'valorIss',
            'issValue',
          ],
        ),
      ),
      note: _toStringValue(
        _first(
          data,
          const [
            'note',
            'observation',
            'observacao',
            'observação',
            'obs',
            'descricao',
          ],
        ),
      ),
      createdAt: _toDate(data['createdAt']),
      createdBy: _toStringValue(data['createdBy']),
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: _toStringValue(data['updatedBy']),
      attachments: _toAttachments(data['attachments']),
    );
  }

  factory RevisionPaidData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);

    return _fromData(
      data: data,
      documentId: snap.id,
    );
  }

  factory RevisionPaidData.fromMap(Map<String, dynamic> json) {
    return _fromData(data: json);
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'contractId': contractId,
      'revisionId': revisionId,
      'revisionOrder': revisionOrder,
      'fundingSourceId': fundingSourceId,
      'fundingSourceLabel': fundingSourceLabel,
      'paymentDate': paymentDate,
      'paymentValue': paymentValue,
      'inssPaymentDate': inssPaymentDate,
      'inssPaymentValue': inssPaymentValue,
      'irpfPaymentDate': irpfPaymentDate,
      'irpfPaymentValue': irpfPaymentValue,
      'issPaymentDate': issPaymentDate,
      'issPaymentValue': issPaymentValue,
      'note': note,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'attachments': attachments?.map((item) => item.toMap()).toList(),
    }..removeWhere((key, value) => value == null);
  }

  RevisionPaidData copyWith({
    String? id,
    String? contractId,
    String? revisionId,
    int? revisionOrder,
    String? fundingSourceId,
    String? fundingSourceLabel,
    DateTime? paymentDate,
    double? paymentValue,
    DateTime? inssPaymentDate,
    double? inssPaymentValue,
    DateTime? irpfPaymentDate,
    double? irpfPaymentValue,
    DateTime? issPaymentDate,
    double? issPaymentValue,
    String? note,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    List<Attachment>? attachments,
  }) {
    return RevisionPaidData(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      revisionId: revisionId ?? this.revisionId,
      revisionOrder: revisionOrder ?? this.revisionOrder,
      fundingSourceId: fundingSourceId ?? this.fundingSourceId,
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentValue: paymentValue ?? this.paymentValue,
      inssPaymentDate: inssPaymentDate ?? this.inssPaymentDate,
      inssPaymentValue: inssPaymentValue ?? this.inssPaymentValue,
      irpfPaymentDate: irpfPaymentDate ?? this.irpfPaymentDate,
      irpfPaymentValue: irpfPaymentValue ?? this.irpfPaymentValue,
      issPaymentDate: issPaymentDate ?? this.issPaymentDate,
      issPaymentValue: issPaymentValue ?? this.issPaymentValue,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      attachments: attachments ?? this.attachments,
    );
  }
}