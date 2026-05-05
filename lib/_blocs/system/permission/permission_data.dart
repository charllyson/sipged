// lib/_blocs/system/permission/permission_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PermissionAction {
  read,
  create,
  edit,
  delete,
  approve,
}

enum SystemUserRole {
  administrador,
  desenvolvedor,
  gestorRegional,
  fiscal,
  colaborador,
  leitor,
}

class SystemRoleCodec {
  const SystemRoleCodec._();

  static const Map<SystemUserRole, String> _ids = {
    SystemUserRole.administrador: 'ADMINISTRADOR',
    SystemUserRole.desenvolvedor: 'DESENVOLVEDOR',
    SystemUserRole.gestorRegional: 'GESTOR_REGIONAL',
    SystemUserRole.fiscal: 'FISCAL',
    SystemUserRole.colaborador: 'COLABORADOR',
    SystemUserRole.leitor: 'LEITOR',
  };

  static const Map<SystemUserRole, String> _labels = {
    SystemUserRole.administrador: 'Administrador',
    SystemUserRole.desenvolvedor: 'Desenvolvedor',
    SystemUserRole.gestorRegional: 'Gestor Regional',
    SystemUserRole.fiscal: 'Fiscal',
    SystemUserRole.colaborador: 'Colaborador',
    SystemUserRole.leitor: 'Leitor',
  };

  static String serialize(SystemUserRole role) {
    return _ids[role] ?? _ids[SystemUserRole.leitor]!;
  }

  static String label(SystemUserRole role) {
    return _labels[role] ?? _labels[SystemUserRole.leitor]!;
  }

  static SystemUserRole parse(String? raw) {
    final value = (raw ?? '').trim();

    if (value.isEmpty) {
      return SystemUserRole.leitor;
    }

    final upper = value.toUpperCase().trim();

    if (upper == 'CONVIDADO') {
      return SystemUserRole.leitor;
    }

    for (final entry in _ids.entries) {
      if (entry.value == upper) {
        return entry.key;
      }
    }

    final normalized = upper
        .replaceAll('-', '_')
        .replaceAll(' ', '_')
        .replaceAll('__', '_');

    for (final entry in _ids.entries) {
      if (entry.value == normalized) {
        return entry.key;
      }
    }

    for (final role in SystemUserRole.values) {
      if (role.name.toLowerCase() == value.toLowerCase()) {
        return role;
      }
    }

    switch (normalized) {
      case 'ADMIN':
      case 'ADMINISTRADOR':
        return SystemUserRole.administrador;

      case 'DEV':
      case 'DESENVOLVEDOR':
        return SystemUserRole.desenvolvedor;

      case 'GESTORREGIONAL':
      case 'GESTOR_REGIONAL':
        return SystemUserRole.gestorRegional;

      case 'FISCAL':
        return SystemUserRole.fiscal;

      case 'COLABORADOR':
        return SystemUserRole.colaborador;

      case 'LEITOR':
      case 'READER':
      default:
        return SystemUserRole.leitor;
    }
  }

  static bool isSuperUser(SystemUserRole role) {
    return role == SystemUserRole.administrador ||
        role == SystemUserRole.desenvolvedor;
  }
}

class PermissionSet extends Equatable {
  final bool read;
  final bool create;
  final bool edit;
  final bool delete;
  final bool approve;

  const PermissionSet({
    this.read = false,
    this.create = false,
    this.edit = false,
    this.delete = false,
    this.approve = false,
  });

  static const none = PermissionSet();

  static const full = PermissionSet(
    read: true,
    create: true,
    edit: true,
    delete: true,
    approve: true,
  );

  static const readOnly = PermissionSet(
    read: true,
  );

  bool allows(PermissionAction action) {
    switch (action) {
      case PermissionAction.read:
        return read || create || edit || delete || approve;

      case PermissionAction.create:
        return create || edit || delete || approve;

      case PermissionAction.edit:
        return edit || delete || approve;

      case PermissionAction.delete:
        return delete || approve;

      case PermissionAction.approve:
        return approve;
    }
  }

  bool allowsString(String action) {
    return allows(PermissionActionCodec.parse(action));
  }

  PermissionSet mergeAllow(PermissionSet other) {
    return PermissionSet(
      read: read || other.read,
      create: create || other.create,
      edit: edit || other.edit,
      delete: delete || other.delete,
      approve: approve || other.approve,
    );
  }

  PermissionSet copyWith({
    bool? read,
    bool? create,
    bool? edit,
    bool? delete,
    bool? approve,
  }) {
    return PermissionSet(
      read: read ?? this.read,
      create: create ?? this.create,
      edit: edit ?? this.edit,
      delete: delete ?? this.delete,
      approve: approve ?? this.approve,
    );
  }

  Map<String, bool> toBoolMap() {
    return {
      'read': read,
      'create': create,
      'edit': edit,
      'delete': delete,
      'approve': approve,
    };
  }

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from(toBoolMap());
  }

  factory PermissionSet.fromMap(Map<String, dynamic>? map) {
    final m = map ?? const <String, dynamic>{};

    return PermissionSet(
      read: m['read'] == true,
      create: m['create'] == true,
      edit: m['edit'] == true,
      delete: m['delete'] == true,
      approve: m['approve'] == true,
    );
  }

  factory PermissionSet.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return PermissionSet.none;
    }

    final map = <String, dynamic>{};

    raw.forEach((key, value) {
      if (key is String) {
        map[key] = value;
      }
    });

    return PermissionSet.fromMap(map);
  }

  @override
  List<Object?> get props => [
    read,
    create,
    edit,
    delete,
    approve,
  ];
}

class PermissionActionCodec {
  const PermissionActionCodec._();

  static PermissionAction parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'create':
        return PermissionAction.create;

      case 'edit':
      case 'update':
        return PermissionAction.edit;

      case 'delete':
      case 'remove':
        return PermissionAction.delete;

      case 'approve':
      case 'approval':
        return PermissionAction.approve;

      case 'read':
      default:
        return PermissionAction.read;
    }
  }

  static String serialize(PermissionAction action) {
    switch (action) {
      case PermissionAction.read:
        return 'read';

      case PermissionAction.create:
        return 'create';

      case PermissionAction.edit:
        return 'edit';

      case PermissionAction.delete:
        return 'delete';

      case PermissionAction.approve:
        return 'approve';
    }
  }
}

class TenantPermissionData extends Equatable {
  final String tenantId;
  final bool enabled;
  final SystemUserRole? role;
  final String? label;
  final Map<String, PermissionSet> moduleOverrides;
  final Map<String, dynamic> extra;

  const TenantPermissionData({
    required this.tenantId,
    this.enabled = true,
    this.role,
    this.label,
    this.moduleOverrides = const <String, PermissionSet>{},
    this.extra = const <String, dynamic>{},
  });

  factory TenantPermissionData.fromMap({
    required String tenantId,
    required Map<String, dynamic>? map,
  }) {
    final raw = Map<String, dynamic>.from(map ?? const <String, dynamic>{});

    final enabled = raw.remove('enabled') != false;

    final roleRaw = raw.remove('role')?.toString().trim();
    final labelRaw = raw.remove('label')?.toString().trim();

    final moduleOverrides = <String, PermissionSet>{};

    final rawModuleOverrides = raw.remove('moduleOverrides');

    if (rawModuleOverrides is Map) {
      rawModuleOverrides.forEach((key, value) {
        final module = key.toString().trim();

        if (module.isEmpty) return;

        moduleOverrides[module] = PermissionSet.fromDynamic(value);
      });
    }

    return TenantPermissionData(
      tenantId: tenantId.trim(),
      enabled: enabled,
      role: roleRaw == null || roleRaw.isEmpty
          ? null
          : SystemRoleCodec.parse(roleRaw),
      label: labelRaw == null || labelRaw.isEmpty ? null : labelRaw,
      moduleOverrides: moduleOverrides,
      extra: raw,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      if (role != null) 'role': SystemRoleCodec.serialize(role!),
      if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
      if (moduleOverrides.isNotEmpty)
        'moduleOverrides': {
          for (final entry in moduleOverrides.entries)
            entry.key: entry.value.toMap(),
        },
      ...extra,
    };
  }

  TenantPermissionData copyWith({
    String? tenantId,
    bool? enabled,
    SystemUserRole? role,
    bool clearRole = false,
    String? label,
    bool clearLabel = false,
    Map<String, PermissionSet>? moduleOverrides,
    Map<String, dynamic>? extra,
  }) {
    return TenantPermissionData(
      tenantId: tenantId ?? this.tenantId,
      enabled: enabled ?? this.enabled,
      role: clearRole ? null : role ?? this.role,
      label: clearLabel ? null : label ?? this.label,
      moduleOverrides: moduleOverrides ?? this.moduleOverrides,
      extra: extra ?? this.extra,
    );
  }

  PermissionSet overrideForModule(String module) {
    return moduleOverrides[module.trim()] ?? PermissionSet.none;
  }

  @override
  List<Object?> get props => [
    tenantId,
    enabled,
    role,
    label,
    moduleOverrides,
    extra,
  ];
}

class UserPermissionData extends Equatable {
  final String uid;
  final SystemUserRole globalRole;
  final Map<String, PermissionSet> globalModuleOverrides;
  final Map<String, TenantPermissionData> tenantAccess;
  final Map<String, dynamic> extra;

  const UserPermissionData({
    required this.uid,
    this.globalRole = SystemUserRole.leitor,
    this.globalModuleOverrides = const <String, PermissionSet>{},
    this.tenantAccess = const <String, TenantPermissionData>{},
    this.extra = const <String, dynamic>{},
  });

  const UserPermissionData.empty()
      : uid = '',
        globalRole = SystemUserRole.leitor,
        globalModuleOverrides = const <String, PermissionSet>{},
        tenantAccess = const <String, TenantPermissionData>{},
        extra = const <String, dynamic>{};

  bool get isEmpty => uid.trim().isEmpty;

  bool get isGlobalSuperUser => SystemRoleCodec.isSuperUser(globalRole);

  factory UserPermissionData.fromMap({
    required String uid,
    required Map<String, dynamic>? map,
  }) {
    if (map == null) {
      return UserPermissionData(
        uid: uid,
      );
    }

    final raw = Map<String, dynamic>.from(map);

    final roleRaw = raw.remove('baseRole') ??
        raw.remove('baseProfile') ??
        raw.remove('role');

    final globalRole = SystemRoleCodec.parse(roleRaw?.toString());

    final globalModuleOverrides = <String, PermissionSet>{};

    final rawGlobalModuleOverrides = raw.remove('moduleOverrides');

    if (rawGlobalModuleOverrides is Map) {
      rawGlobalModuleOverrides.forEach((key, value) {
        final module = key.toString().trim();

        if (module.isEmpty) return;

        globalModuleOverrides[module] = PermissionSet.fromDynamic(value);
      });
    }

    final tenantAccess = <String, TenantPermissionData>{};

    final rawTenantAccess = raw.remove('tenantAccess');

    if (rawTenantAccess is Map) {
      rawTenantAccess.forEach((key, value) {
        final tenantId = key.toString().trim();

        if (tenantId.isEmpty) return;

        if (value is Map) {
          tenantAccess[tenantId] = TenantPermissionData.fromMap(
            tenantId: tenantId,
            map: Map<String, dynamic>.from(value),
          );
        }
      });
    }

    return UserPermissionData(
      uid: uid.trim(),
      globalRole: globalRole,
      globalModuleOverrides: globalModuleOverrides,
      tenantAccess: tenantAccess,
      extra: raw,
    );
  }

  factory UserPermissionData.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    return UserPermissionData.fromMap(
      uid: doc.id,
      map: doc.data(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseRole': SystemRoleCodec.serialize(globalRole),
      if (globalModuleOverrides.isNotEmpty)
        'moduleOverrides': {
          for (final entry in globalModuleOverrides.entries)
            entry.key: entry.value.toMap(),
        },
      if (tenantAccess.isNotEmpty)
        'tenantAccess': {
          for (final entry in tenantAccess.entries)
            entry.key: entry.value.toMap(),
        },
      ...extra,
    };
  }

  List<String> get enabledTenantIds {
    if (isGlobalSuperUser) {
      return tenantAccess.keys.toList(growable: false);
    }

    return tenantAccess.entries
        .where((entry) => entry.value.enabled)
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  TenantPermissionData? tenantPermission(String? tenantId) {
    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return tenantAccess[id];
  }

  bool canAccessTenant(String? tenantId) {
    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return false;
    }

    if (isGlobalSuperUser) {
      return true;
    }

    return tenantAccess[id]?.enabled == true;
  }

  SystemUserRole roleForTenant(String? tenantId) {
    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return globalRole;
    }

    final tenantRole = tenantAccess[id]?.role;

    return tenantRole ?? globalRole;
  }

  bool isSuperUserForTenant(String? tenantId) {
    return SystemRoleCodec.isSuperUser(
      roleForTenant(tenantId),
    );
  }

  PermissionSet defaultPermissionsForTenant(String? tenantId) {
    final role = roleForTenant(tenantId);

    switch (role) {
      case SystemUserRole.administrador:
      case SystemUserRole.desenvolvedor:
        return PermissionSet.full;

      case SystemUserRole.gestorRegional:
      case SystemUserRole.fiscal:
      case SystemUserRole.colaborador:
      case SystemUserRole.leitor:
        return PermissionSet.none;
    }
  }

  PermissionSet moduleOverride({
    required String module,
    String? tenantId,
  }) {
    final cleanModule = module.trim();

    if (cleanModule.isEmpty) {
      return PermissionSet.none;
    }

    final id = tenantId?.trim();

    if (id != null && id.isNotEmpty) {
      final tenantOverride = tenantAccess[id]?.overrideForModule(cleanModule);

      if (tenantOverride != null && tenantOverride != PermissionSet.none) {
        return tenantOverride;
      }
    }

    return globalModuleOverrides[cleanModule] ?? PermissionSet.none;
  }

  PermissionSet effectiveModulePermissions({
    required String module,
    String? tenantId,
  }) {
    final base = defaultPermissionsForTenant(tenantId);

    final override = moduleOverride(
      module: module,
      tenantId: tenantId,
    );

    return base.mergeAllow(override);
  }

  bool canModule({
    required String module,
    required PermissionAction action,
    String? tenantId,
  }) {
    final id = tenantId?.trim();

    if (id != null && id.isNotEmpty) {
      if (!canAccessTenant(id)) {
        return false;
      }
    }

    final effective = effectiveModulePermissions(
      module: module,
      tenantId: id,
    );

    return effective.allows(action);
  }

  bool canModuleString({
    required String module,
    required String action,
    String? tenantId,
  }) {
    return canModule(
      module: module,
      action: PermissionActionCodec.parse(action),
      tenantId: tenantId,
    );
  }

  UserPermissionData copyWith({
    String? uid,
    SystemUserRole? globalRole,
    Map<String, PermissionSet>? globalModuleOverrides,
    Map<String, TenantPermissionData>? tenantAccess,
    Map<String, dynamic>? extra,
  }) {
    return UserPermissionData(
      uid: uid ?? this.uid,
      globalRole: globalRole ?? this.globalRole,
      globalModuleOverrides:
      globalModuleOverrides ?? this.globalModuleOverrides,
      tenantAccess: tenantAccess ?? this.tenantAccess,
      extra: extra ?? this.extra,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    globalRole,
    globalModuleOverrides,
    tenantAccess,
    extra,
  ];
}