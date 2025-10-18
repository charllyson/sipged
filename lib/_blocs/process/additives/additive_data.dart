import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// 🆕 reutiliza o mesmo modelo de anexo
import 'package:siged/_widgets/list/files/attachment.dart';

class AdditiveData extends ChangeNotifier {
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

  // 🆕 anexos com rótulo (múltiplos)
  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  // ---------------------------------------------------------------------------
  // 🎨 PALETA CONSISTENTE PARA *TERMOS* (evitando azul/laranja reservados)
  // Reservas:
  //   - Azul (contratado) e Laranja (realizado) NÃO entram na paleta.
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
      colorForOrder(order).withOpacity(opacity);

  static Color strongTintForOrder(int order, {double opacity = .10}) =>
      colorForOrder(order).withOpacity(opacity);

  /// Cores para a barra de percentual na tabela.
  /// - `order == null` => usado na **seção de aditivos** para “Contratado” bloqueado (cinza).
  static ({Color fill, Color track, bool disabled}) barColorsForOrder(int? order) {
    if (order == null) {
      return (
      fill: const Color(0xFF9E9E9E), // cinza neutro para bloqueado (na aba aditivos)
      track: trackColor,
      disabled: true
      );
    }
    return (fill: colorForOrder(order), track: trackColor, disabled: false);
  }

  AdditiveData({
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

  static List<Attachment>? _toAttachments(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return null;
  }

  factory AdditiveData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception("Contrato não encontrado");

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) throw Exception("Os dados do contrato estão vazios");

    return AdditiveData(
      id: snapshot.id,
      contractId: data['contractId'] ?? '',
      additiveNumberProcess: data['additivenumberprocess'],
      additiveOrder: (data['additiveorder'] as num?)?.toInt(),
      additiveValidityContractDays:
      (data['additivevaliditycontractdays'] as num?)?.toInt(),
      additiveValidityExecutionDays:
      (data['additivevalidityexecutiondays'] as num?)?.toInt(),
      additiveDate: (data['additivedata'] as Timestamp?)?.toDate(),
      additiveValue: (data['additivevalue'] as num?)?.toDouble(),
      typeOfAdditive: data['typeOfAdditive'],
      pdfUrl: data['pdfUrl'] as String?,
      attachments: _toAttachments(data['attachments']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] ?? '',
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] ?? '',
    );
  }

  factory AdditiveData.fromMap(Map<String, dynamic> map, {String? id}) {
    return AdditiveData(
      id: id ?? map['id'],
      contractId: map['contractId'],
      additiveNumberProcess: map['additivenumberprocess'],
      additiveOrder: (map['additiveorder'] as num?)?.toInt(),
      additiveValidityContractDays:
      (map['additivevaliditycontractdays'] as num?)?.toInt(),
      additiveValidityExecutionDays:
      (map['additivevalidityexecutiondays'] as num?)?.toInt(),
      additiveDate:
      (map['additivedata'] is Timestamp) ? (map['additivedata'] as Timestamp).toDate() : null,
      additiveValue: (map['additivevalue'] as num?)?.toDouble(),
      typeOfAdditive: map['typeOfAdditive'],
      pdfUrl: map['pdfUrl'] as String?,
      attachments: _toAttachments(map['attachments']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      createdBy: map['createdBy'],
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: map['updatedBy'],
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: map['deletedBy'],
    );
  }

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
    };
  }
}
