import 'package:flutter/foundation.dart';

@immutable
class WorkspaceFilter {
  final String sourceItemId;
  final String sourceLayerId;
  final String sourceField;
  final String label;
  final dynamic value;

  const WorkspaceFilter({
    required this.sourceItemId,
    required this.sourceLayerId,
    required this.sourceField,
    required this.label,
    this.value,
  });

  bool get isValid {
    return sourceItemId.trim().isNotEmpty &&
        sourceLayerId.trim().isNotEmpty &&
        sourceField.trim().isNotEmpty &&
        label.trim().isNotEmpty;
  }

  WorkspaceFilter copyWith({
    String? sourceItemId,
    String? sourceLayerId,
    String? sourceField,
    String? label,
    dynamic value = _workspaceFilterSentinel,
  }) {
    return WorkspaceFilter(
      sourceItemId: sourceItemId ?? this.sourceItemId,
      sourceLayerId: sourceLayerId ?? this.sourceLayerId,
      sourceField: sourceField ?? this.sourceField,
      label: label ?? this.label,
      value: identical(value, _workspaceFilterSentinel) ? this.value : value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sourceItemId': sourceItemId,
      'sourceLayerId': sourceLayerId,
      'sourceField': sourceField,
      'label': label,
      'value': value,
    };
  }

  factory WorkspaceFilter.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const WorkspaceFilter(
        sourceItemId: '',
        sourceLayerId: '',
        sourceField: '',
        label: '',
      );
    }

    return WorkspaceFilter(
      sourceItemId: map['sourceItemId']?.toString() ?? '',
      sourceLayerId: map['sourceLayerId']?.toString() ?? '',
      sourceField: map['sourceField']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      value: map['value'],
    );
  }

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
  int get hashCode {
    return Object.hash(
      sourceItemId,
      sourceLayerId,
      sourceField,
      label,
      value,
    );
  }
}

const Object _workspaceFilterSentinel = Object();