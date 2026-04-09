import 'package:flutter/foundation.dart';

@immutable
class WorkspaceFilter {
  final String sourceItemId;
  final String sourceLayerId;
  final String sourceField;
  final String label;
  final double? value;

  const WorkspaceFilter({
    required this.sourceItemId,
    required this.sourceLayerId,
    required this.sourceField,
    required this.label,
    this.value,
  });

  WorkspaceFilter copyWith({
    String? sourceItemId,
    String? sourceLayerId,
    String? sourceField,
    String? label,
    Object? value = _sentinel,
  }) {
    return WorkspaceFilter(
      sourceItemId: sourceItemId ?? this.sourceItemId,
      sourceLayerId: sourceLayerId ?? this.sourceLayerId,
      sourceField: sourceField ?? this.sourceField,
      label: label ?? this.label,
      value: identical(value, _sentinel) ? this.value : value as double?,
    );
  }

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) {
    return other is WorkspaceFilter &&
        other.sourceItemId == sourceItemId &&
        other.sourceLayerId == sourceLayerId &&
        other.sourceField == sourceField &&
        other.label == label &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(
    sourceItemId,
    sourceLayerId,
    sourceField,
    label,
    value,
  );
}