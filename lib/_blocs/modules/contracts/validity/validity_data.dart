// lib/_blocs/modules/contracts/validity/validity_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class ValidityData {
  String? id;
  String? uidContract;
  DateTime? orderdate;
  int? orderNumber;
  String? ordertype;

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
    this.pdfUrl,
    this.attachments,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.deletedBy,
    this.deletedAt,
  });

  static const List<String> typeOfOrder = <String>[
    'ORDEM DE INÍCIO',
    'ORDEM DE PARALISAÇÃO',
    'ORDEM DE REINÍCIO',
    'ORDEM DE FINALIZAÇÃO',
  ];

  static dynamic _pick(
      Map<String, dynamic> map,
      List<String> keys,
      ) {
    for (final key in keys) {
      if (map.containsKey(key)) return map[key];
    }

    return null;
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

      return int.tryParse(text.replaceAll(RegExp(r'[^\d-]'), ''));
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
    return ValidityData(
      id: id ?? _toStringOrNull(_pick(map, const <String>['id'])),
      uidContract: _toStringOrNull(
        _pick(
          map,
          const <String>[
            'uidcontract',
            'uidContract',
            'contractId',
            'uidContrato',
          ],
        ),
      ) ??
          fallbackContractId,
      orderNumber: _toInt(
        _pick(
          map,
          const <String>[
            'ordernumber',
            'orderNumber',
            'order',
            'ordem',
          ],
        ),
      ),
      ordertype: _toStringOrNull(
        _pick(
          map,
          const <String>[
            'ordertype',
            'orderType',
            'type',
            'tipo',
          ],
        ),
      ),
      orderdate: _toDate(
        _pick(
          map,
          const <String>[
            'orderdate',
            'orderDate',
            'date',
            'data',
          ],
        ),
      ),
      pdfUrl: _toStringOrNull(
        _pick(
          map,
          const <String>[
            'pdfUrl',
            'urlPdf',
            'pdf',
          ],
        ),
      ),
      attachments: _toAttachments(
        _pick(
          map,
          const <String>[
            'attachments',
            'anexos',
            'files',
          ],
        ),
      ),
      createdBy: _toStringOrNull(map['createdBy']),
      createdAt: _toDate(map['createdAt']),
      updatedBy: _toStringOrNull(map['updatedBy']),
      updatedAt: _toDate(map['updatedAt']),
      deletedBy: _toStringOrNull(map['deletedBy']),
      deletedAt: _toDate(map['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      if (uidContract != null && uidContract!.trim().isNotEmpty) ...{
        'uidcontract': uidContract,
        'uidContract': uidContract,
        'contractId': uidContract,
      },
      'ordernumber': orderNumber ?? 0,
      'orderNumber': orderNumber ?? 0,
      'ordertype': ordertype ?? '',
      'orderType': ordertype ?? '',
      'orderdate': orderdate,
      'orderDate': orderdate,
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((item) => item.toMap()).toList(),
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
    return ValidityData(
      id: clearId ? null : id ?? this.id,
      uidContract: clearUidContract ? null : uidContract ?? this.uidContract,
      orderdate: clearOrderDate ? null : orderdate ?? this.orderdate,
      orderNumber: clearOrderNumber ? null : orderNumber ?? this.orderNumber,
      ordertype: clearOrderType ? null : ordertype ?? this.ordertype,
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
        'orderdate: $orderdate, '
        'attachments: ${attachments?.length ?? 0}'
        ')';
  }
}