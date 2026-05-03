import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

DateTime? _dateFromFirestore(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

Timestamp? _dateToFirestore(DateTime? value) {
  if (value == null) return null;
  return Timestamp.fromDate(value);
}

enum SetupGroup {
  modules,
  profiles,
  permissions,
  parameters,
  integrations,
  featureFlags,
}

extension SetupGroupExtension on SetupGroup {
  String get collectionName {
    switch (this) {
      case SetupGroup.modules:
        return 'modules';

      case SetupGroup.profiles:
        return 'profiles';

      case SetupGroup.permissions:
        return 'permissions';

      case SetupGroup.parameters:
        return 'parameters';

      case SetupGroup.integrations:
        return 'integrations';

      case SetupGroup.featureFlags:
        return 'feature_flags';
    }
  }

  String get label {
    switch (this) {
      case SetupGroup.modules:
        return 'Módulos';

      case SetupGroup.profiles:
        return 'Perfis';

      case SetupGroup.permissions:
        return 'Permissões';

      case SetupGroup.parameters:
        return 'Parâmetros';

      case SetupGroup.integrations:
        return 'Integrações';

      case SetupGroup.featureFlags:
        return 'Recursos';
    }
  }
}

class SetupData extends Equatable {
  final String id;

  final String tenantId;

  final SetupGroup group;

  /// Chave técnica. Ex:
  /// contracts-overview-dashboard
  /// traffic-accidents-records
  /// max-upload-size
  /// enable-push-notifications
  final String key;

  /// Nome exibido na interface.
  final String label;

  /// Descrição técnica ou funcional.
  final String? description;

  /// Tipo lógico do item. Ex:
  /// module, profile, permission, parameter, integration, feature_flag.
  final String type;

  /// Valor livre para parâmetros e flags.
  ///
  /// Pode ser bool, String, num, List ou Map.
  final dynamic value;

  final bool enabled;

  final int order;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  final Map<String, dynamic> metadata;

  const SetupData({
    required this.id,
    required this.tenantId,
    required this.group,
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.value,
    this.enabled = true,
    this.order = 0,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.metadata = const <String, dynamic>{},
  });

  const SetupData.empty()
      : id = '',
        tenantId = '',
        group = SetupGroup.parameters,
        key = '',
        label = '',
        description = null,
        type = 'parameter',
        value = null,
        enabled = true,
        order = 0,
        createdAt = null,
        createdBy = null,
        updatedAt = null,
        updatedBy = null,
        metadata = const <String, dynamic>{};

  factory SetupData.fromMap({
    required String id,
    required Map<String, dynamic>? map,
    required SetupGroup group,
    String? forcedTenantId,
  }) {
    if (map == null) return const SetupData.empty();

    final raw = Map<String, dynamic>.from(map);

    final tenantId = (forcedTenantId ?? raw.remove('tenantId')?.toString() ?? '')
        .trim();

    final key = (raw.remove('key') ?? id).toString().trim();

    final label = (raw.remove('label') ?? key).toString().trim();

    final descriptionRaw = raw.remove('description')?.toString().trim();
    final description =
    descriptionRaw == null || descriptionRaw.isEmpty ? null : descriptionRaw;

    final type = (raw.remove('type') ?? _defaultTypeForGroup(group))
        .toString()
        .trim();

    final value = raw.remove('value');

    final enabledRaw = raw.remove('enabled');
    final enabled = enabledRaw is bool ? enabledRaw : true;

    final orderRaw = raw.remove('order');
    final order = orderRaw is int
        ? orderRaw
        : orderRaw is num
        ? orderRaw.toInt()
        : int.tryParse(orderRaw?.toString() ?? '') ?? 0;

    final createdAt = _dateFromFirestore(raw.remove('createdAt'));
    final updatedAt = _dateFromFirestore(raw.remove('updatedAt'));

    final createdBy = raw.remove('createdBy')?.toString();
    final updatedBy = raw.remove('updatedBy')?.toString();

    final metadataRaw = raw.remove('metadata');

    final metadata = <String, dynamic>{};

    if (metadataRaw is Map) {
      metadata.addAll(Map<String, dynamic>.from(metadataRaw));
    }

    metadata.addAll(raw);

    return SetupData(
      id: id,
      tenantId: tenantId,
      group: group,
      key: key,
      label: label,
      description: description,
      type: type,
      value: value,
      enabled: enabled,
      order: order,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      metadata: metadata,
    );
  }

  factory SetupData.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        required SetupGroup group,
        String? forcedTenantId,
      }) {
    return SetupData.fromMap(
      id: doc.id,
      map: doc.data(),
      group: group,
      forcedTenantId: forcedTenantId,
    );
  }

  static String _defaultTypeForGroup(SetupGroup group) {
    switch (group) {
      case SetupGroup.modules:
        return 'module';

      case SetupGroup.profiles:
        return 'profile';

      case SetupGroup.permissions:
        return 'permission';

      case SetupGroup.parameters:
        return 'parameter';

      case SetupGroup.integrations:
        return 'integration';

      case SetupGroup.featureFlags:
        return 'feature_flag';
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tenantId': tenantId,
      'key': key,
      'label': label,
      'type': type,
      'enabled': enabled,
      'order': order,
      if (description != null && description!.trim().isNotEmpty)
        'description': description,
      if (value != null) 'value': value,
      if (createdAt != null) 'createdAt': _dateToFirestore(createdAt),
      if (createdBy != null && createdBy!.trim().isNotEmpty)
        'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': _dateToFirestore(updatedAt),
      if (updatedBy != null && updatedBy!.trim().isNotEmpty)
        'updatedBy': updatedBy,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  SetupData copyWith({
    String? id,
    String? tenantId,
    SetupGroup? group,
    String? key,
    String? label,
    String? description,
    String? type,
    dynamic value,
    bool? enabled,
    int? order,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    Map<String, dynamic>? metadata,
  }) {
    return SetupData(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      group: group ?? this.group,
      key: key ?? this.key,
      label: label ?? this.label,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  @override
  List<Object?> get props => [
    id,
    tenantId,
    group,
    key,
    label,
    description,
    type,
    value,
    enabled,
    order,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    metadata,
  ];
}