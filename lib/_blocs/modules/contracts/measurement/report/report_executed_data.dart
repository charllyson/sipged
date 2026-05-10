import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class ReportExecutedData {
  static const String collectionName = 'reportsMeasurement';

  String? id;
  int? order;
  String? numberprocess;
  DateTime? date;
  double? value;

  String? contractId;
  String? pdfUrl;

  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  ReportExecutedData({
    this.id,
    this.order,
    this.numberprocess,
    this.date,
    this.value,
    this.contractId,
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) return value.toDouble();

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) return null;

      final normalized = text
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();

      return double.tryParse(normalized);
    }

    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) return null;

      final onlyDigits = text.replaceAll(RegExp(r'[^\d-]'), '');

      return int.tryParse(onlyDigits);
    }

    return null;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);

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

  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static List<Attachment>? _toAttachments(
      dynamic value, {
        String? fallbackPdfUrl,
      }) {
    final cleanFallback = fallbackPdfUrl?.trim();

    if (value == null) {
      if (cleanFallback != null && cleanFallback.isNotEmpty) {
        return <Attachment>[
          Attachment(
            id: 'pdf',
            label: 'PDF da medição',
            url: cleanFallback,
            path: '',
            ext: '.pdf',
          ),
        ];
      }

      return null;
    }

    if (value is! List) return null;

    final list = <Attachment>[];

    for (final item in value) {
      if (item == null) continue;

      if (item is Attachment) {
        list.add(item);
        continue;
      }

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

    if (list.isEmpty &&
        cleanFallback != null &&
        cleanFallback.isNotEmpty) {
      return <Attachment>[
        Attachment(
          id: 'pdf',
          label: 'PDF da medição',
          url: cleanFallback,
          path: '',
          ext: '.pdf',
        ),
      ];
    }

    return list.isEmpty ? null : list;
  }

  static Map<String, dynamic> _readSnapData(DocumentSnapshot snap) {
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return snap.data() ?? <String, dynamic>{};
    }

    final raw = snap.data();

    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  static dynamic _pick(
      Map<String, dynamic> map,
      List<String> keys,
      ) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        return map[key];
      }
    }

    return null;
  }

  factory ReportExecutedData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);
    final contractIdFromPath = snap.reference.parent.parent?.id;

    return ReportExecutedData.fromMap(
      data,
      id: snap.id,
      fallbackContractId: contractIdFromPath,
    );
  }

  factory ReportExecutedData.fromMap(
      Map<String, dynamic> json, {
        String? id,
        String? fallbackContractId,
      }) {
    final pdfUrl = _toStringOrNull(
      _pick(
        json,
        const [
          'pdfUrl',
          'urlPdf',
          'pdf',
        ],
      ),
    );

    return ReportExecutedData(
      id: id ?? _toStringOrNull(json['id']),
      order: _toInt(
        _pick(
          json,
          const [
            'order',
            'measurementorder',
            'measurementOrder',
            'ordem',
          ],
        ),
      ),
      numberprocess: _toStringOrNull(
        _pick(
          json,
          const [
            'numberprocess',
            'numberProcess',
            'measurementnumberprocess',
            'measurementNumberProcess',
            'processNumber',
          ],
        ),
      ),
      date: _toDate(
        _pick(
          json,
          const [
            'date',
            'measurementdata',
            'measurementData',
            'data',
          ],
        ),
      ),
      value: _toDouble(
        _pick(
          json,
          const [
            'value',
            'measurementinitialvalue',
            'measurementInitialValue',
            'valor',
          ],
        ),
      ),
      pdfUrl: pdfUrl,
      contractId: _toStringOrNull(
        _pick(
          json,
          const [
            'contractId',
            'uidContract',
            'uidcontract',
            'processId',
          ],
        ),
      ) ??
          fallbackContractId,
      createdAt: _toDate(json['createdAt']),
      createdBy: _toStringOrNull(json['createdBy']),
      updatedAt: _toDate(json['updatedAt']),
      updatedBy: _toStringOrNull(json['updatedBy']),
      attachments: _toAttachments(
        _pick(
          json,
          const [
            'attachments',
            'anexos',
            'files',
          ],
        ),
        fallbackPdfUrl: pdfUrl,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      if (order != null) 'order': order,
      if (numberprocess != null && numberprocess!.trim().isNotEmpty)
        'numberprocess': numberprocess,
      if (date != null) 'date': date,
      if (value != null) 'value': value,
      if (pdfUrl != null && pdfUrl!.trim().isNotEmpty) 'pdfUrl': pdfUrl,
      if (contractId != null && contractId!.trim().isNotEmpty)
        'contractId': contractId,
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

  ReportExecutedData copyWith({
    String? id,
    int? order,
    String? numberprocess,
    DateTime? date,
    double? value,
    String? contractId,
    String? pdfUrl,
    List<Attachment>? attachments,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    bool clearId = false,
    bool clearOrder = false,
    bool clearNumberprocess = false,
    bool clearDate = false,
    bool clearValue = false,
    bool clearContractId = false,
    bool clearPdfUrl = false,
    bool clearAttachments = false,
    bool clearCreatedAt = false,
    bool clearCreatedBy = false,
    bool clearUpdatedAt = false,
    bool clearUpdatedBy = false,
  }) {
    return ReportExecutedData(
      id: clearId ? null : id ?? this.id,
      order: clearOrder ? null : order ?? this.order,
      numberprocess:
      clearNumberprocess ? null : numberprocess ?? this.numberprocess,
      date: clearDate ? null : date ?? this.date,
      value: clearValue ? null : value ?? this.value,
      contractId: clearContractId ? null : contractId ?? this.contractId,
      pdfUrl: clearPdfUrl ? null : pdfUrl ?? this.pdfUrl,
      attachments: clearAttachments ? null : attachments ?? this.attachments,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
      updatedBy: clearUpdatedBy ? null : updatedBy ?? this.updatedBy,
    );
  }
}