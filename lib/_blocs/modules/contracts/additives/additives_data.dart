// lib/_blocs/modules/contracts/additives/additives_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

/// Modelo de aditivo.
class AdditivesData {
  String? id;
  String? contractId;

  int? additiveOrder;
  String? additiveNumberProcess;
  DateTime? additiveDate;
  String? typeOfAdditive;
  double? additiveValue;

  /// Dias de validade do contrato após o aditivo.
  int? additiveValidityContractDays;

  /// Dias de execução aditivados.
  int? additiveValidityExecutionDays;

  /// Legado: último PDF salvo diretamente no documento.
  String? pdfUrl;

  /// Anexos com rótulo.
  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  AdditivesData({
    this.id,
    this.contractId,
    this.additiveNumberProcess,
    this.additiveOrder,
    this.additiveValidityExecutionDays,
    this.additiveDate,
    this.additiveValidityContractDays,
    this.additiveValue,
    this.typeOfAdditive,
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  // ---------------------------------------------------------------------------
  // Tipos permitidos
  // ---------------------------------------------------------------------------

  static const List<String> allowedTypes = <String>[
    'VALOR',
    'PRAZO',
    'REEQUÍLIBRIO',
    'RATIFICAÇÃO',
    'RENOVAÇÃO',
  ];

  // ---------------------------------------------------------------------------
  // Paleta consistente para termos/aditivos
  // ---------------------------------------------------------------------------

  static const List<Color> _palette = <Color>[
    Colors.amber,
    Colors.purpleAccent,
    Colors.green,
    Colors.pink,
    Colors.orange,
    Colors.blue,
    Colors.red,
    Colors.brown,
    Colors.teal,
    Colors.cyan,
    Colors.indigo,
  ];

  /// Cor padrão usada para o contratado/base.
  static const Color contractedColor = Color(0xFF206AF5);

  static const Color trackColor = Color(0xFFE0E0E0);

  static Color colorForOrder(int order) {
    if (order <= 0) return contractedColor;
    return _palette[(order - 1) % _palette.length];
  }

  static Color tintForOrder(int order, {double opacity = .06}) {
    return colorForOrder(order).withValues(alpha: opacity);
  }

  static Color strongTintForOrder(int order, {double opacity = .10}) {
    return colorForOrder(order).withValues(alpha: opacity);
  }

  static ({Color fill, Color track, bool disabled}) barColorsForOrder(
      int? order,
      ) {
    if (order == null) {
      return (
      fill: const Color(0xFF9E9E9E),
      track: trackColor,
      disabled: true,
      );
    }

    return (
    fill: colorForOrder(order),
    track: trackColor,
    disabled: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers de parsing
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Factory: Firestore Document
  // ---------------------------------------------------------------------------

  factory AdditivesData.fromDocument({
    required DocumentSnapshot snapshot,
  }) {
    if (!snapshot.exists) {
      throw Exception('Aditivo não encontrado');
    }

    final data =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final contractIdFromPath = snapshot.reference.parent.parent?.id;

    return AdditivesData.fromMap(
      data,
      id: snapshot.id,
      fallbackContractId: contractIdFromPath,
    );
  }

  // ---------------------------------------------------------------------------
  // Factory: Map genérico
  // ---------------------------------------------------------------------------

  factory AdditivesData.fromMap(
      Map<String, dynamic> map, {
        String? id,
        String? fallbackContractId,
      }) {
    return AdditivesData(
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
      additiveNumberProcess: _toStringOrNull(
        _pick(
          map,
          const [
            'additivenumberprocess',
            'additiveNumberProcess',
            'additiveNumber',
            'numberProcess',
            'numberprocess',
            'processNumber',
          ],
        ),
      ),
      additiveOrder: _toInt(
        _pick(
          map,
          const [
            'additiveorder',
            'additiveOrder',
            'order',
            'ordem',
          ],
        ),
      ),
      additiveValidityContractDays: _toInt(
        _pick(
          map,
          const [
            'additivevaliditycontractdays',
            'additiveValidityContractDays',
            'validityContractDays',
            'contractValidityDays',
          ],
        ),
      ),
      additiveValidityExecutionDays: _toInt(
        _pick(
          map,
          const [
            'additivevalidityexecutiondays',
            'additiveValidityExecutionDays',
            'validityExecutionDays',
            'executionValidityDays',
          ],
        ),
      ),
      additiveDate: _toDate(
        _pick(
          map,
          const [
            'additivedata',
            'additiveDate',
            'additiveData',
            'date',
            'data',
          ],
        ),
      ),
      additiveValue: _toDouble(
        _pick(
          map,
          const [
            'additivevalue',
            'additiveValue',
            'value',
            'valor',
          ],
        ),
      ),
      typeOfAdditive: _toStringOrNull(
        _pick(
          map,
          const [
            'typeOfAdditive',
            'type_of_additive',
            'additiveType',
            'type',
            'tipo',
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

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  AdditivesData copyWith({
    String? id,
    String? contractId,
    int? additiveOrder,
    String? additiveNumberProcess,
    DateTime? additiveDate,
    String? typeOfAdditive,
    double? additiveValue,
    int? additiveValidityContractDays,
    int? additiveValidityExecutionDays,
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
    bool clearAdditiveOrder = false,
    bool clearAdditiveNumberProcess = false,
    bool clearAdditiveDate = false,
    bool clearTypeOfAdditive = false,
    bool clearAdditiveValue = false,
    bool clearAdditiveValidityContractDays = false,
    bool clearAdditiveValidityExecutionDays = false,
    bool clearPdfUrl = false,
    bool clearAttachments = false,
    bool clearCreatedAt = false,
    bool clearCreatedBy = false,
    bool clearUpdatedAt = false,
    bool clearUpdatedBy = false,
    bool clearDeletedAt = false,
    bool clearDeletedBy = false,
  }) {
    return AdditivesData(
      id: clearId ? null : id ?? this.id,
      contractId: clearContractId ? null : contractId ?? this.contractId,
      additiveOrder: clearAdditiveOrder
          ? null
          : additiveOrder ?? this.additiveOrder,
      additiveNumberProcess: clearAdditiveNumberProcess
          ? null
          : additiveNumberProcess ?? this.additiveNumberProcess,
      additiveDate:
      clearAdditiveDate ? null : additiveDate ?? this.additiveDate,
      typeOfAdditive:
      clearTypeOfAdditive ? null : typeOfAdditive ?? this.typeOfAdditive,
      additiveValue:
      clearAdditiveValue ? null : additiveValue ?? this.additiveValue,
      additiveValidityContractDays: clearAdditiveValidityContractDays
          ? null
          : additiveValidityContractDays ??
          this.additiveValidityContractDays,
      additiveValidityExecutionDays: clearAdditiveValidityExecutionDays
          ? null
          : additiveValidityExecutionDays ??
          this.additiveValidityExecutionDays,
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

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      if (contractId != null && contractId!.trim().isNotEmpty)
        'contractId': contractId,

      // Campos atuais usados no sistema.
      'additivenumberprocess': additiveNumberProcess ?? '',
      'additiveorder': additiveOrder ?? 0,
      'additivevaliditycontractdays': additiveValidityContractDays ?? 0,
      'additivevalidityexecutiondays': additiveValidityExecutionDays ?? 0,
      'additivedata': additiveDate,
      'additivevalue': additiveValue ?? 0.0,
      'typeOfAdditive': typeOfAdditive ?? '',

      // Compatibilidade/consulta futura.
      'additiveNumberProcess': additiveNumberProcess ?? '',
      'additiveOrder': additiveOrder ?? 0,
      'additiveValidityContractDays': additiveValidityContractDays ?? 0,
      'additiveValidityExecutionDays': additiveValidityExecutionDays ?? 0,
      'additiveDate': additiveDate,
      'additiveValue': additiveValue ?? 0.0,

      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),

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
      'additivenumberprocess': additiveNumberProcess,
      'additiveorder': additiveOrder,
      'additivevaliditycontractdays': additiveValidityContractDays,
      'additivevalidityexecutiondays': additiveValidityExecutionDays,
      'additivedata': additiveDate,
      'additivevalue': additiveValue,
      'typeOfAdditive': typeOfAdditive,
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
    return 'AdditivesData('
        'id: $id, '
        'contractId: $contractId, '
        'additiveOrder: $additiveOrder, '
        'additiveNumberProcess: $additiveNumberProcess, '
        'additiveDate: $additiveDate, '
        'typeOfAdditive: $typeOfAdditive, '
        'additiveValue: $additiveValue, '
        'additiveValidityContractDays: $additiveValidityContractDays, '
        'additiveValidityExecutionDays: $additiveValidityExecutionDays, '
        'attachments: ${attachments?.length ?? 0}'
        ')';
  }
}