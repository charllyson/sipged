// lib/_blocs/modules/contracts/apostilles/apostilles_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_utils/formatters/sipged_format_numbers.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

class ApostillesData {
  static const String collectionName = 'apostilles';

  String? id;
  String? contractId;

  String? apostilleNumberProcess;
  int? apostilleOrder;
  DateTime? apostilleData;
  double? apostilleValue;

  String? pdfUrl;

  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  ApostillesData({
    this.id,
    this.contractId,
    this.apostilleNumberProcess,
    this.apostilleOrder,
    this.apostilleData,
    this.apostilleValue,
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

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

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is num) return value.toDouble();

    if (value is String) {
      return SipGedFormatNumbers.toDouble(value);
    }

    return null;
  }

  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
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

  factory ApostillesData.fromDocument({
    required DocumentSnapshot snapshot,
  }) {
    if (!snapshot.exists) {
      throw Exception('Apostilamento não encontrado');
    }

    final data =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final contractIdFromPath = snapshot.reference.parent.parent?.id;

    return ApostillesData.fromMap(
      data,
      id: snapshot.id,
      fallbackContractId: contractIdFromPath,
    );
  }

  factory ApostillesData.fromMap(
      Map<String, dynamic> map, {
        String? id,
        String? fallbackContractId,
      }) {
    return ApostillesData(
      id: id ?? _toStringOrNull(_pick(map, const ['id'])),
      contractId: _toStringOrNull(
        _pick(
          map,
          const [
            'contractId',
            'uidContract',
            'uidcontract',
            'processId',
          ],
        ),
      ) ??
          fallbackContractId,
      apostilleNumberProcess: _toStringOrNull(
        _pick(
          map,
          const [
            'apostillenumberprocess',
            'apostilleNumberProcess',
            'apostilleNumber',
            'numberProcess',
            'numberprocess',
            'processNumber',
          ],
        ),
      ),
      apostilleOrder: _toInt(
        _pick(
          map,
          const [
            'apostilleorder',
            'apostilleOrder',
            'order',
            'ordem',
          ],
        ),
      ),
      apostilleData: _toDate(
        _pick(
          map,
          const [
            'apostilledata',
            'apostilleDate',
            'apostilleData',
            'date',
            'data',
          ],
        ),
      ),
      apostilleValue: _toDouble(
        _pick(
          map,
          const [
            'apostillevalue',
            'apostilleValue',
            'value',
            'valor',
          ],
        ),
      ),
      pdfUrl: _toStringOrNull(
        _pick(
          map,
          const [
            'pdfUrl',
            'urlPdf',
            'pdf',
          ],
        ),
      ),
      attachments: _toAttachments(
        _pick(
          map,
          const [
            'attachments',
            'anexos',
            'files',
          ],
        ),
      ),
      createdAt: _toDate(map['createdAt']),
      createdBy: _toStringOrNull(map['createdBy']),
      updatedAt: _toDate(map['updatedAt']),
      updatedBy: _toStringOrNull(map['updatedBy']),
      deletedAt: _toDate(map['deletedAt']),
      deletedBy: _toStringOrNull(map['deletedBy']),
    );
  }

  ApostillesData copyWith({
    String? id,
    String? contractId,
    String? apostilleNumberProcess,
    int? apostilleOrder,
    DateTime? apostilleData,
    double? apostilleValue,
    String? pdfUrl,
    List<Attachment>? attachments,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
    bool clearId = false,
    bool clearContractId = false,
    bool clearApostilleNumberProcess = false,
    bool clearApostilleOrder = false,
    bool clearApostilleData = false,
    bool clearApostilleValue = false,
    bool clearPdfUrl = false,
    bool clearAttachments = false,
    bool clearCreatedAt = false,
    bool clearCreatedBy = false,
    bool clearUpdatedAt = false,
    bool clearUpdatedBy = false,
    bool clearDeletedAt = false,
    bool clearDeletedBy = false,
  }) {
    return ApostillesData(
      id: clearId ? null : id ?? this.id,
      contractId: clearContractId ? null : contractId ?? this.contractId,
      apostilleNumberProcess: clearApostilleNumberProcess
          ? null
          : apostilleNumberProcess ?? this.apostilleNumberProcess,
      apostilleOrder:
      clearApostilleOrder ? null : apostilleOrder ?? this.apostilleOrder,
      apostilleData:
      clearApostilleData ? null : apostilleData ?? this.apostilleData,
      apostilleValue:
      clearApostilleValue ? null : apostilleValue ?? this.apostilleValue,
      pdfUrl: clearPdfUrl ? null : pdfUrl ?? this.pdfUrl,
      attachments: clearAttachments ? null : attachments ?? this.attachments,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
      updatedBy: clearUpdatedBy ? null : updatedBy ?? this.updatedBy,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      deletedBy: clearDeletedBy ? null : deletedBy ?? this.deletedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      if (contractId != null && contractId!.trim().isNotEmpty)
        'contractId': contractId,

      'apostillenumberprocess': apostilleNumberProcess ?? '',
      'apostilleorder': apostilleOrder ?? 0,
      'apostilledata': apostilleData,
      'apostillevalue': apostilleValue ?? 0.0,

      'apostilleNumberProcess': apostilleNumberProcess ?? '',
      'apostilleOrder': apostilleOrder ?? 0,
      'apostilleDate': apostilleData,
      'apostilleValue': apostilleValue ?? 0.0,

      if (pdfUrl != null && pdfUrl!.trim().isNotEmpty) 'pdfUrl': pdfUrl,
      if (attachments != null && attachments!.isNotEmpty)
        'attachments': attachments!.map((e) => e.toMap()).toList(),

      if (createdAt != null) 'createdAt': createdAt,
      if (createdBy != null && createdBy!.trim().isNotEmpty)
        'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (updatedBy != null && updatedBy!.trim().isNotEmpty)
        'updatedBy': updatedBy,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (deletedBy != null && deletedBy!.trim().isNotEmpty)
        'deletedBy': deletedBy,
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'contractId': contractId,
      'apostillenumberprocess': apostilleNumberProcess,
      'apostilleorder': apostilleOrder,
      'apostilledata': apostilleData,
      'apostillevalue': apostilleValue,
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
    };
  }

  @override
  String toString() {
    return 'ApostillesData('
        'id: $id, '
        'contractId: $contractId, '
        'apostilleOrder: $apostilleOrder, '
        'apostilleNumberProcess: $apostilleNumberProcess, '
        'apostilleData: $apostilleData, '
        'apostilleValue: $apostilleValue, '
        'attachments: ${attachments?.length ?? 0}'
        ')';
  }
}