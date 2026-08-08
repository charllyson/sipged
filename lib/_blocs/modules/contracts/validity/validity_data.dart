// lib/_blocs/modules/contracts/validity/validity_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

enum ValidityOrderType {
  inicio(
    code: 'inicio',
    label: 'ORDEM DE INÍCIO',
  ),
  paralisacao(
    code: 'paralisacao',
    label: 'ORDEM DE PARALISAÇÃO',
  ),
  reinicio(
    code: 'reinicio',
    label: 'ORDEM DE REINÍCIO',
  ),
  finalizacao(
    code: 'finalizacao',
    label: 'ORDEM DE FINALIZAÇÃO',
  );

  const ValidityOrderType({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;

  static ValidityOrderType? fromCode(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) return null;

    for (final item in ValidityOrderType.values) {
      if (item.code == clean) {
        return item;
      }
    }

    return null;
  }

  static ValidityOrderType? fromLabel(String? value) {
    final clean = value?.trim();

    if (clean == null || clean.isEmpty) return null;

    for (final item in ValidityOrderType.values) {
      if (item.label == clean) {
        return item;
      }
    }

    return null;
  }

  static ValidityOrderType? fromStored({
    required String? code,
    required String? label,
  }) {
    return fromCode(code) ?? fromLabel(label);
  }
}

class ValidityData {
  static const String collectionName = 'orders';

  String? id;
  String? uidContract;
  DateTime? orderdate;
  int? orderNumber;
  String? ordertype;
  String? orderTypeCode;

  String? pdfUrl;

  List<Attachment>? attachments;

  String? createdBy;
  DateTime? createdAt;
  String? updatedBy;
  DateTime? updatedAt;
  String? deletedBy;
  DateTime? deletedAt;

  ValidityData({
    this.id,
    this.uidContract,
    this.orderdate,
    this.orderNumber,
    this.ordertype,
    this.orderTypeCode,
    this.pdfUrl,
    this.attachments,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.deletedBy,
    this.deletedAt,
  });

  static List<String> get typeOfOrder {
    return ValidityOrderType.values.map((item) => item.label).toList();
  }

  ValidityOrderType? get orderKind {
    return ValidityOrderType.fromStored(
      code: orderTypeCode,
      label: ordertype,
    );
  }

  String? get canonicalOrderTypeCode {
    return orderKind?.code;
  }

  String? get canonicalOrderTypeLabel {
    return orderKind?.label;
  }

  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) return null;

      return int.tryParse(text.replaceAll(RegExp(r'[^0-9-]'), ''));
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
      final text = value.trim();

      if (text.isEmpty) return null;

      final iso = DateTime.tryParse(text);
      if (iso != null) return iso;

      final parts = text.split('/');

      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          final parsed = DateTime(year, month, day);

          if (parsed.day == day &&
              parsed.month == month &&
              parsed.year == year) {
            return parsed;
          }
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
      if (item == null) continue;

      if (item is Map<String, dynamic>) {
        list.add(Attachment.fromMap(item));
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

  factory ValidityData.fromDocument({
    required DocumentSnapshot snapshot,
  }) {
    final data =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final contractIdFromPath = snapshot.reference.parent.parent?.id;

    return ValidityData.fromMap(
      data,
      id: snapshot.id,
      fallbackContractId: contractIdFromPath,
    );
  }

  factory ValidityData.fromMap(
      Map<String, dynamic> map, {
        String? id,
        String? fallbackContractId,
      }) {
    final storedCode = _toStringOrNull(map['orderTypeCode']);
    final storedLabel = _toStringOrNull(map['ordertype']);

    final kind = ValidityOrderType.fromStored(
      code: storedCode,
      label: storedLabel,
    );

    return ValidityData(
      id: id ?? _toStringOrNull(map['id']),
      uidContract: _toStringOrNull(map['contractId']) ?? fallbackContractId,
      orderNumber: _toInt(map['orderNumber']),
      ordertype: kind?.label ?? storedLabel,
      orderTypeCode: kind?.code ?? storedCode,
      orderdate: _toDate(map['orderDate']),
      pdfUrl: _toStringOrNull(map['pdfUrl']),
      attachments: _toAttachments(map['attachments']),
      createdBy: _toStringOrNull(map['createdBy']),
      createdAt: _toDate(map['createdAt']),
      updatedBy: _toStringOrNull(map['updatedBy']),
      updatedAt: _toDate(map['updatedAt']),
      deletedBy: _toStringOrNull(map['deletedBy']),
      deletedAt: _toDate(map['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final kind = orderKind;

    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      if (uidContract != null && uidContract!.trim().isNotEmpty)
        'contractId': uidContract,
      'orderNumber': orderNumber ?? 0,
      'orderTypeCode': kind?.code,
      'ordertype': kind?.label ?? ordertype ?? '',
      'orderDate': orderdate,
      if (pdfUrl != null && pdfUrl!.trim().isNotEmpty) 'pdfUrl': pdfUrl,
      if (attachments != null && attachments!.isNotEmpty)
        'attachments': attachments!.map((item) => item.toMap()).toList(),
      if (createdBy != null && createdBy!.trim().isNotEmpty)
        'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedBy != null && updatedBy!.trim().isNotEmpty)
        'updatedBy': updatedBy,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (deletedBy != null && deletedBy!.trim().isNotEmpty)
        'deletedBy': deletedBy,
      if (deletedAt != null) 'deletedAt': deletedAt,
    }..removeWhere((key, value) => value == null);
  }

  Map<String, dynamic> toMap() => toJson();

  ValidityData copyWith({
    String? id,
    String? uidContract,
    DateTime? orderdate,
    int? orderNumber,
    String? ordertype,
    String? orderTypeCode,
    String? pdfUrl,
    List<Attachment>? attachments,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? deletedBy,
    DateTime? deletedAt,
    bool clearId = false,
    bool clearUidContract = false,
    bool clearOrderDate = false,
    bool clearOrderNumber = false,
    bool clearOrderType = false,
    bool clearPdfUrl = false,
    bool clearAttachments = false,
    bool clearCreatedBy = false,
    bool clearCreatedAt = false,
    bool clearUpdatedBy = false,
    bool clearUpdatedAt = false,
    bool clearDeletedBy = false,
    bool clearDeletedAt = false,
  }) {
    final nextType = clearOrderType ? null : ordertype ?? this.ordertype;
    final nextTypeCode =
    clearOrderType ? null : orderTypeCode ?? this.orderTypeCode;

    final kind = ValidityOrderType.fromStored(
      code: nextTypeCode,
      label: nextType,
    );

    return ValidityData(
      id: clearId ? null : id ?? this.id,
      uidContract: clearUidContract ? null : uidContract ?? this.uidContract,
      orderdate: clearOrderDate ? null : orderdate ?? this.orderdate,
      orderNumber: clearOrderNumber ? null : orderNumber ?? this.orderNumber,
      ordertype: kind?.label ?? nextType,
      orderTypeCode: kind?.code ?? nextTypeCode,
      pdfUrl: clearPdfUrl ? null : pdfUrl ?? this.pdfUrl,
      attachments: clearAttachments ? null : attachments ?? this.attachments,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
      updatedBy: clearUpdatedBy ? null : updatedBy ?? this.updatedBy,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
      deletedBy: clearDeletedBy ? null : deletedBy ?? this.deletedBy,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'ValidityData('
        'id: $id, '
        'uidContract: $uidContract, '
        'orderNumber: $orderNumber, '
        'ordertype: $ordertype, '
        'orderTypeCode: $orderTypeCode, '
        'orderdate: $orderdate, '
        'attachments: ${attachments?.length ?? 0}'
        ')';
  }
}