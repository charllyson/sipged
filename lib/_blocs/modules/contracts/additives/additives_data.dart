// lib/_blocs/modules/contracts/additives/additives_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

/// 🧩 Modelo de aditivo (somente dados, sem lógica de UI)
class AdditivesData {
  String? id;
  String? contractId;
  int? additiveOrder;
  String? additiveNumberProcess;
  DateTime? additiveDate;
  String? typeOfAdditive;
  double? additiveValue;

  /// Dias de validade (prazo) do **contrato** após o aditivo.
  int? additiveValidityContractDays;

  /// Dias de **execução** aditivados (usado para estender o cronograma).
  int? additiveValidityExecutionDays;

  // Legado: último PDF salvo no doc
  String? pdfUrl;

  // Anexos com rótulo (múltiplos)
  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  // ---------------------------------------------------------------------------
  // 🎨 Paleta consistente para *termos*
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

  /// Cor padrão usada para o **contratado** (PV base / barras bloqueadas).
  static const Color contractedColor = Color(0xFF206AF5); // azul
  static const Color trackColor = Color(0xFFE0E0E0);

  /// Cor principal para um **termo** pela sua ordem (1..N).
  static Color colorForOrder(int order) {
    if (order <= 0) return contractedColor;
    return _palette[(order - 1) % _palette.length];
  }

  /// Variedades convenientes da cor do termo para fundos/tintas.
  static Color tintForOrder(int order, {double opacity = .06}) =>
      colorForOrder(order).withValues(alpha: opacity);

  static Color strongTintForOrder(int order, {double opacity = .10}) =>
      colorForOrder(order).withValues(alpha: opacity);

  /// Cores para a barra de percentual na tabela.
  /// - `order == null` => usado na **seção de aditivos** para “Contratado” bloqueado (cinza).
  static ({Color fill, Color track, bool disabled}) barColorsForOrder(
      int? order,
      ) {
    if (order == null) {
      return (
      fill: const Color(0xFF9E9E9E), // cinza neutro para bloqueado
      track: trackColor,
      disabled: true,
      );
    }
    return (fill: colorForOrder(order), track: trackColor, disabled: false);
  }

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

  // -------------------- Tipos permitidos --------------------
  static const List<String> allowedTypes = <String>[
    'VALOR',
    'PRAZO',
    'REEQUÍLIBRIO',
    'RATIFICAÇÃO',
    'RENOVAÇÃO',
  ];

  static List<Attachment>? _toAttachments(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return null;
  }

  // =========================
  // Helpers locais
  // =========================
  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) {
      final sanitized = v.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(sanitized);
    }
    return null;
  }

  // =========================
  // FACTORY: Firestore Document
  // =========================
  factory AdditivesData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception("Aditivo não encontrado");

    final Map<String, dynamic> data =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final String? contractIdFromPath = snapshot.reference.parent.parent?.id;

    return AdditivesData(
      id: snapshot.id,
      contractId: (data['contractId'] ?? contractIdFromPath) as String?,
      additiveNumberProcess:
      data['additivenumberprocess'] ?? data['additiveNumberProcess'],
      additiveOrder:
      _toInt(data['additiveorder'] ?? data['additiveOrder']),
      additiveValidityContractDays: _toInt(
        data['additivevaliditycontractdays'] ??
            data['additiveValidityContractDays'],
      ),
      additiveValidityExecutionDays: _toInt(
        data['additivevalidityexecutiondays'] ??
            data['additiveValidityExecutionDays'],
      ),
      additiveDate: _toDate(data['additivedata'] ?? data['additiveDate']),
      additiveValue:
      _toDouble(data['additivevalue'] ?? data['additiveValue']),
      typeOfAdditive: data['typeOfAdditive'] ?? data['type_of_additive'],
      pdfUrl: data['pdfUrl'] as String?,
      attachments: _toAttachments(data['attachments']),
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
      deletedAt: _toDate(data['deletedAt']),
      deletedBy: data['deletedBy'] as String?,
    );
  }

  // =========================
  // FACTORY: Map genérico
  // =========================
  factory AdditivesData.fromMap(Map<String, dynamic> map, {String? id}) {
    return AdditivesData(
      id: id ?? map['id'],
      contractId: map['contractId'],
      additiveNumberProcess:
      map['additivenumberprocess'] ?? map['additiveNumberProcess'],
      additiveOrder: _toInt(map['additiveorder'] ?? map['additiveOrder']),
      additiveValidityContractDays: _toInt(
        map['additivevaliditycontractdays'] ??
            map['additiveValidityContractDays'],
      ),
      additiveValidityExecutionDays: _toInt(
        map['additivevalidityexecutiondays'] ??
            map['additiveValidityExecutionDays'],
      ),
      additiveDate: _toDate(map['additivedata'] ?? map['additiveDate']),
      additiveValue:
      _toDouble(map['additivevalue'] ?? map['additiveValue']),
      typeOfAdditive: map['typeOfAdditive'],
      pdfUrl: map['pdfUrl'] as String?,
      attachments: _toAttachments(map['attachments']),
      createdAt: _toDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: _toDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: _toDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
    );
  }

  /// Mapa enxuto para gravar/atualizar no Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id ?? '',
      'contractId': contractId ?? '',
      'additivenumberprocess': additiveNumberProcess ?? '',
      'additiveorder': additiveOrder ?? 0,
      'additivevaliditycontractdays': additiveValidityContractDays ?? 0,
      'additivevalidityexecutiondays': additiveValidityExecutionDays ?? 0,
      'additivedata': additiveDate,
      'additivevalue': additiveValue ?? 0,
      'typeOfAdditive': typeOfAdditive ?? '',
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
    };
  }

  /// Versão mais completa (caso precise em memória).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractId': contractId,
      'additivenumberprocess': additiveNumberProcess,
      'additiveorder': additiveOrder,
      'additivevaliditycontractdays': additiveValidityContractDays,
      'additivevalidityexecutiondays': additiveValidityExecutionDays,
      'additivedata': additiveDate,
      'additivevalue': additiveValue ?? 0,
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
}
