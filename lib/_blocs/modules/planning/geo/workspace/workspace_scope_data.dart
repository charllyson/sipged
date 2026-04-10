import 'package:flutter/foundation.dart';

enum WorkspaceScopeType {
  general,
  layer,
  group,
}

@immutable
class WorkspaceScopeData {
  final WorkspaceScopeType type;
  final String id;

  const WorkspaceScopeData({
    required this.type,
    required this.id,
  });

  const WorkspaceScopeData.general()
      : type = WorkspaceScopeType.general,
        id = 'general_id';

  bool get isGeneral => type == WorkspaceScopeType.general;
  bool get isLayer => type == WorkspaceScopeType.layer;
  bool get isGroup => type == WorkspaceScopeType.group;

  String get collectionName {
    switch (type) {
      case WorkspaceScopeType.general:
        return 'general';
      case WorkspaceScopeType.layer:
        return 'layer';
      case WorkspaceScopeType.group:
        return 'group';
    }
  }

  String get documentId {
    if (isGeneral) return 'general_id';
    return id.trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'id': id,
    };
  }

  factory WorkspaceScopeData.fromMap(Map<String, dynamic> map) {
    final rawType = (map['type'] ?? 'general').toString();

    return WorkspaceScopeData(
      type: WorkspaceScopeType.values.firstWhere(
            (e) => e.name == rawType,
        orElse: () => WorkspaceScopeType.general,
      ),
      id: (map['id'] ?? 'general_id').toString(),
    );
  }

  WorkspaceScopeData copyWith({
    WorkspaceScopeType? type,
    String? id,
  }) {
    return WorkspaceScopeData(
      type: type ?? this.type,
      id: id ?? this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceScopeData &&
        other.type == type &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);
}