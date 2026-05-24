// lib/_blocs/modules/financial/payments/adjustment/adjustment_paid_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class AdjustmentPaidData {
  static const String collectionName = 'adjustmentPayments';

  String? id;

  String? contractId;
  String? adjustmentId;
  int? adjustmentOrder;

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

  AdjustmentPaidData({
    this.id,
    this.contractId,
    this.adjustmentId,
    this.adjustmentOrder,
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
        continue;
      }

      if (item is Map) {
        list.add(
          Attachment.fromMap(
            Map<String, dynamic>.from(item),
          ),
        );
      }
    }

    return list.isEmpty ? null : list;
  }

  static AdjustmentPaidData _fromData({
    required Map<String, dynamic> data,
    String? documentId,
    String? contractIdFromPath,
    String? adjustmentIdFromPath,
  }) {
    return AdjustmentPaidData(
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
      adjustmentId: _toStringValue(
        _first(
          data,
          const [
            'adjustmentId',
            'adjustment_id',
            'idAdjustment',
            'idReajuste',
            'reajusteId',
          ],
        ),
      ) ??
          adjustmentIdFromPath,
      adjustmentOrder: _toInt(
        _first(
          data,
          const [
            'adjustmentOrder',
            'adjustmentorder',
            'adjustment_order',
            'order',
            'ordemReajuste',
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

  factory AdjustmentPaidData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);

    return _fromData(
      data: data,
      documentId: snap.id,
    );
  }

  factory AdjustmentPaidData.fromMap(Map<String, dynamic> json) {
    return _fromData(data: json);
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      if (contractId != null && contractId!.trim().isNotEmpty)
        'contractId': contractId,
      if (adjustmentId != null && adjustmentId!.trim().isNotEmpty)
        'adjustmentId': adjustmentId,
      if (adjustmentOrder != null) 'adjustmentOrder': adjustmentOrder,
      if (fundingSourceId != null && fundingSourceId!.trim().isNotEmpty)
        'fundingSourceId': fundingSourceId,
      if (fundingSourceLabel != null && fundingSourceLabel!.trim().isNotEmpty)
        'fundingSourceLabel': fundingSourceLabel,
      if (paymentDate != null) 'paymentDate': paymentDate,
      if (paymentValue != null) 'paymentValue': paymentValue,
      if (inssPaymentDate != null) 'inssPaymentDate': inssPaymentDate,
      if (inssPaymentValue != null) 'inssPaymentValue': inssPaymentValue,
      if (irpfPaymentDate != null) 'irpfPaymentDate': irpfPaymentDate,
      if (irpfPaymentValue != null) 'irpfPaymentValue': irpfPaymentValue,
      if (issPaymentDate != null) 'issPaymentDate': issPaymentDate,
      if (issPaymentValue != null) 'issPaymentValue': issPaymentValue,
      if (note != null && note!.trim().isNotEmpty) 'note': note,
      if (createdAt != null) 'createdAt': createdAt,
      if (createdBy != null && createdBy!.trim().isNotEmpty)
        'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (updatedBy != null && updatedBy!.trim().isNotEmpty)
        'updatedBy': updatedBy,
      if (attachments != null && attachments!.isNotEmpty)
        'attachments': attachments!.map((item) => item.toMap()).toList(),
    };
  }

  AdjustmentPaidData copyWith({
    String? id,
    String? contractId,
    String? adjustmentId,
    int? adjustmentOrder,
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
    bool clearId = false,
    bool clearContractId = false,
    bool clearAdjustmentId = false,
    bool clearAdjustmentOrder = false,
    bool clearFundingSourceId = false,
    bool clearFundingSourceLabel = false,
    bool clearPaymentDate = false,
    bool clearPaymentValue = false,
    bool clearInssPaymentDate = false,
    bool clearInssPaymentValue = false,
    bool clearIrpfPaymentDate = false,
    bool clearIrpfPaymentValue = false,
    bool clearIssPaymentDate = false,
    bool clearIssPaymentValue = false,
    bool clearNote = false,
    bool clearCreatedAt = false,
    bool clearCreatedBy = false,
    bool clearUpdatedAt = false,
    bool clearUpdatedBy = false,
    bool clearAttachments = false,
  }) {
    return AdjustmentPaidData(
      id: clearId ? null : id ?? this.id,
      contractId: clearContractId ? null : contractId ?? this.contractId,
      adjustmentId: clearAdjustmentId ? null : adjustmentId ?? this.adjustmentId,
      adjustmentOrder:
      clearAdjustmentOrder ? null : adjustmentOrder ?? this.adjustmentOrder,
      fundingSourceId:
      clearFundingSourceId ? null : fundingSourceId ?? this.fundingSourceId,
      fundingSourceLabel: clearFundingSourceLabel
          ? null
          : fundingSourceLabel ?? this.fundingSourceLabel,
      paymentDate: clearPaymentDate ? null : paymentDate ?? this.paymentDate,
      paymentValue: clearPaymentValue ? null : paymentValue ?? this.paymentValue,
      inssPaymentDate: clearInssPaymentDate
          ? null
          : inssPaymentDate ?? this.inssPaymentDate,
      inssPaymentValue: clearInssPaymentValue
          ? null
          : inssPaymentValue ?? this.inssPaymentValue,
      irpfPaymentDate: clearIrpfPaymentDate
          ? null
          : irpfPaymentDate ?? this.irpfPaymentDate,
      irpfPaymentValue: clearIrpfPaymentValue
          ? null
          : irpfPaymentValue ?? this.irpfPaymentValue,
      issPaymentDate:
      clearIssPaymentDate ? null : issPaymentDate ?? this.issPaymentDate,
      issPaymentValue:
      clearIssPaymentValue ? null : issPaymentValue ?? this.issPaymentValue,
      note: clearNote ? null : note ?? this.note,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
      updatedBy: clearUpdatedBy ? null : updatedBy ?? this.updatedBy,
      attachments: clearAttachments ? null : attachments ?? this.attachments,
    );
  }

  @override
  String toString() {
    return 'AdjustmentPaidData('
        'id: $id, '
        'contractId: $contractId, '
        'adjustmentId: $adjustmentId, '
        'adjustmentOrder: $adjustmentOrder, '
        'paymentDate: $paymentDate, '
        'paymentValue: $paymentValue, '
        'attachments: ${attachments?.length ?? 0}'
        ')';
  }
}