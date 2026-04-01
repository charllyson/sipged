import 'package:flutter/foundation.dart';

class AttributeData {
  final String? sourceId;
  final String? sourceLabel;
  final String? fieldName;
  final String? aggregation;
  final dynamic fieldValue;
  final List<dynamic> fieldValues;

  const AttributeData({
    this.sourceId,
    this.sourceLabel,
    this.fieldName,
    this.aggregation,
    this.fieldValue,
    this.fieldValues = const [],
  });

  AttributeData copyWith({
    String? sourceId,
    String? sourceLabel,
    String? fieldName,
    String? aggregation,
    dynamic fieldValue = _bindingSentinel,
    List<dynamic>? fieldValues,
  }) {
    return AttributeData(
      sourceId: sourceId ?? this.sourceId,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      fieldName: fieldName ?? this.fieldName,
      aggregation: aggregation ?? this.aggregation,
      fieldValue: identical(fieldValue, _bindingSentinel)
          ? this.fieldValue
          : fieldValue,
      fieldValues: fieldValues ?? this.fieldValues,
    );
  }

  bool get hasBinding {
    return (sourceId ?? '').trim().isNotEmpty ||
        (fieldName ?? '').trim().isNotEmpty;
  }

  String get displayValue {
    final pieces = <String>[
      if ((sourceLabel ?? '').trim().isNotEmpty) sourceLabel!.trim(),
      if ((fieldName ?? '').trim().isNotEmpty) fieldName!.trim(),
      if ((aggregation ?? '').trim().isNotEmpty) aggregation!.trim(),
    ];

    if (pieces.isEmpty) return 'Não definido';
    return pieces.join(' • ');
  }

  String? get previewValueText {
    if (fieldValue == null) return null;
    final value = fieldValue.toString().trim();
    if (value.isEmpty) return null;
    return value;
  }

  String get valuesSummary {
    if (fieldValues.isEmpty) {
      return 'Sem valores carregados';
    }

    final sample = fieldValues
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .take(3)
        .map((e) => e.toString().trim())
        .join(', ');

    if (sample.isEmpty) {
      return '${fieldValues.length} valor(es)';
    }

    return '${fieldValues.length} valor(es) • ex: $sample';
  }

  @override
  bool operator ==(Object other) {
    return other is AttributeData &&
        other.sourceId == sourceId &&
        other.sourceLabel == sourceLabel &&
        other.fieldName == fieldName &&
        other.aggregation == aggregation &&
        other.fieldValue == fieldValue &&
        listEquals(other.fieldValues, fieldValues);
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    sourceLabel,
    fieldName,
    aggregation,
    fieldValue,
    Object.hashAll(fieldValues),
  );
}

const _bindingSentinel = Object();