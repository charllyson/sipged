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

    if (upper == 'CONVIDADO' || upper == 'GUEST') {
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
        .replaceAll('__', '_')
        .trim();

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
      case 'ADM':
      case 'ADMINISTRADOR':
      case 'ADMINISTRATOR':
      case 'SUPER_ADMIN':
      case 'SUPERADMIN':
      case 'SUPER_USER':
      case 'SUPERUSER':
        return SystemUserRole.administrador;

      case 'DEV':
      case 'DEVELOPER':
      case 'DESENVOLVEDOR':
        return SystemUserRole.desenvolvedor;

      case 'GESTORREGIONAL':
      case 'GESTOR_REGIONAL':
      case 'REGIONAL_MANAGER':
      case 'MANAGER_REGIONAL':
        return SystemUserRole.gestorRegional;

      case 'FISCAL':
      case 'INSPECTOR':
        return SystemUserRole.fiscal;

      case 'COLABORADOR':
      case 'EDITOR':
      case 'CONTRIBUTOR':
      case 'COLLABORATOR':
        return SystemUserRole.colaborador;

      case 'LEITOR':
      case 'VIEWER':
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

  bool get isNone {
    return !read && !create && !edit && !delete && !approve;
  }

  bool get isFull {
    return read && create && edit && delete && approve;
  }

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
    return <String, bool>{
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

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'sim' ||
        text == 'yes' ||
        text == 'y' ||
        text == 's';
  }

  static String _normalizeKey(String raw) {
    final key = raw.trim().toLowerCase();

    switch (key) {
      case 'read':
      case 'ler':
      case 'view':
      case 'viewer':
      case 'visualizar':
        return 'read';

      case 'create':
      case 'criar':
      case 'write':
      case 'add':
      case 'insert':
      case 'inserir':
      case 'cadastrar':
        return 'create';

      case 'edit':
      case 'editar':
      case 'update':
      case 'atualizar':
      case 'change':
      case 'alterar':
        return 'edit';

      case 'delete':
      case 'deletar':
      case 'remove':
      case 'remover':
      case 'excluir':
      case 'apagar':
        return 'delete';

      case 'approve':
      case 'aprovar':
      case 'approval':
      case 'approved':
      case 'autorizar':
      case 'authorize':
      case 'authorized':
        return 'approve';

      default:
        return key;
    }
  }

  factory PermissionSet.fromMap(Map<String, dynamic>? map) {
    final m = map ?? const <String, dynamic>{};

    final normalized = <String, bool>{
      'read': false,
      'create': false,
      'edit': false,
      'delete': false,
      'approve': false,
    };

    for (final entry in m.entries) {
      final key = _normalizeKey(entry.key);

      if (!normalized.containsKey(key)) continue;

      normalized[key] = _readBool(entry.value);
    }

    return PermissionSet(
      read: normalized['read'] ?? false,
      create: normalized['create'] ?? false,
      edit: normalized['edit'] ?? false,
      delete: normalized['delete'] ?? false,
      approve: normalized['approve'] ?? false,
    );
  }

  factory PermissionSet.fromDynamic(dynamic raw) {
    if (raw == null) {
      return PermissionSet.none;
    }

    if (raw is PermissionSet) {
      return raw;
    }

    if (raw is Map) {
      final map = <String, dynamic>{};

      raw.forEach((key, value) {
        final cleanKey = key?.toString().trim();

        if (cleanKey == null || cleanKey.isEmpty) return;

        map[cleanKey] = value;
      });

      return PermissionSet.fromMap(map);
    }

    if (raw is Iterable) {
      final map = <String, dynamic>{};

      for (final item in raw) {
        final key = item?.toString().trim();

        if (key == null || key.isEmpty) continue;

        map[key] = true;
      }

      return PermissionSet.fromMap(map);
    }

    if (raw is String) {
      final map = <String, dynamic>{};

      final parts = raw
          .split(RegExp(r'[,;|\n]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty);

      for (final part in parts) {
        map[part] = true;
      }

      return PermissionSet.fromMap(map);
    }

    return PermissionSet.none;
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
      case 'criar':
      case 'write':
      case 'add':
      case 'insert':
      case 'cadastrar':
        return PermissionAction.create;

      case 'edit':
      case 'update':
      case 'editar':
      case 'atualizar':
      case 'change':
      case 'alterar':
        return PermissionAction.edit;

      case 'delete':
      case 'remove':
      case 'excluir':
      case 'apagar':
      case 'deletar':
      case 'remover':
        return PermissionAction.delete;

      case 'approve':
      case 'approval':
      case 'approved':
      case 'aprovar':
      case 'autorizar':
      case 'authorize':
      case 'authorized':
        return PermissionAction.approve;

      case 'read':
      case 'view':
      case 'visualizar':
      case 'ler':
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

    final enabledRaw = raw.remove('enabled') ??
        raw.remove('active') ??
        raw.remove('allowed') ??
        true;

    final enabled = _readEnabled(enabledRaw);

    final roleRaw = raw.remove('role') ??
        raw.remove('baseRole') ??
        raw.remove('baseProfile');

    final labelRaw = raw.remove('label') ??
        raw.remove('companyName') ??
        raw.remove('fantasyName');

    final moduleOverrides = <String, PermissionSet>{};

    final rawModuleOverrides = raw.remove('moduleOverrides') ??
        raw.remove('modules') ??
        raw.remove('permissions');

    if (rawModuleOverrides is Map) {
      rawModuleOverrides.forEach((key, value) {
        final module = key.toString().trim();

        if (module.isEmpty) return;

        moduleOverrides[module] = PermissionSet.fromDynamic(value);
      });
    }

    final roleText = roleRaw?.toString().trim();
    final labelText = labelRaw?.toString().trim();

    return TenantPermissionData(
      tenantId: tenantId.trim(),
      enabled: enabled,
      role: roleText == null || roleText.isEmpty
          ? null
          : SystemRoleCodec.parse(roleText),
      label: labelText == null || labelText.isEmpty ? null : labelText,
      moduleOverrides: moduleOverrides,
      extra: raw,
    );
  }

  static bool _readEnabled(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    if (text == null || text.isEmpty) return true;

    if (text == 'false' ||
        text == '0' ||
        text == 'nao' ||
        text == 'não' ||
        text == 'no' ||
        text == 'n' ||
        text == 'disabled' ||
        text == 'inactive') {
      return false;
    }

    return true;
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
  final String? activeTenantId;
  final Map<String, dynamic> extra;

  const UserPermissionData({
    required this.uid,
    this.globalRole = SystemUserRole.leitor,
    this.globalModuleOverrides = const <String, PermissionSet>{},
    this.tenantAccess = const <String, TenantPermissionData>{},
    this.activeTenantId,
    this.extra = const <String, dynamic>{},
  });

  const UserPermissionData.empty()
      : uid = '',
        globalRole = SystemUserRole.leitor,
        globalModuleOverrides = const <String, PermissionSet>{},
        tenantAccess = const <String, TenantPermissionData>{},
        activeTenantId = null,
        extra = const <String, dynamic>{};

  bool get isEmpty => uid.trim().isEmpty;

  bool get isGlobalSuperUser {
    return SystemRoleCodec.isSuperUser(globalRole);
  }

  bool get hasGlobalFreeAccess {
    return isGlobalSuperUser;
  }

  bool get canSelectAnyTenant {
    return hasGlobalFreeAccess;
  }

  bool get hasTenantRestriction {
    return !hasGlobalFreeAccess;
  }

  List<String> get enabledTenantIds {
    final ids = tenantAccess.entries
        .where((entry) => entry.value.enabled)
        .map((entry) => entry.key.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    ids.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ids;
  }

  Map<String, SystemUserRole> get tenantRoles {
    return {
      for (final entry in tenantAccess.entries)
        if (entry.value.enabled) entry.key: entry.value.role ?? globalRole,
    };
  }

  Map<String, Map<String, PermissionSet>> get tenantModuleOverrides {
    return {
      for (final entry in tenantAccess.entries)
        if (entry.value.moduleOverrides.isNotEmpty)
          entry.key: entry.value.moduleOverrides,
    };
  }

  List<String> selectableTenantIds({
    required Iterable<String> availableTenantIds,
  }) {
    final available = availableTenantIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (available.isEmpty) {
      return const <String>[];
    }

    if (hasGlobalFreeAccess) {
      final list = available.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return list;
    }

    final list = enabledTenantIds
        .where((id) => available.contains(id))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return list;
  }

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

    final roleRaw = raw.remove('globalRole') ??
        raw.remove('baseRole') ??
        raw.remove('baseProfile') ??
        raw.remove('role');

    final globalRole = SystemRoleCodec.parse(roleRaw?.toString());

    final activeTenantId = _cleanString(
      raw.remove('activeTenantId') ??
          raw.remove('currentTenantId') ??
          raw.remove('selectedTenantId') ??
          raw.remove('tenantId') ??
          raw.remove('companyId') ??
          raw.remove('currentCompanyId'),
    );

    final globalModuleOverrides = <String, PermissionSet>{};

    final rawGlobalModuleOverrides =
        raw.remove('moduleOverrides') ?? raw.remove('globalModuleOverrides');

    if (rawGlobalModuleOverrides is Map) {
      rawGlobalModuleOverrides.forEach((key, value) {
        final module = key.toString().trim();

        if (module.isEmpty) return;

        globalModuleOverrides[module] = PermissionSet.fromDynamic(value);
      });
    }

    final tenantAccess = <String, TenantPermissionData>{};

    final rawTenantAccess = raw.remove('tenantAccess') ??
        raw.remove('tenantsAccess') ??
        raw.remove('companyAccess') ??
        raw.remove('companiesAccess');

    if (rawTenantAccess is Map) {
      rawTenantAccess.forEach((key, value) {
        final tenantId = key.toString().trim();

        if (tenantId.isEmpty) return;

        if (value is Map) {
          tenantAccess[tenantId] = TenantPermissionData.fromMap(
            tenantId: tenantId,
            map: Map<String, dynamic>.from(value),
          );
        } else if (value == true) {
          tenantAccess[tenantId] = TenantPermissionData(
            tenantId: tenantId,
            enabled: true,
          );
        } else if (value == false) {
          tenantAccess[tenantId] = TenantPermissionData(
            tenantId: tenantId,
            enabled: false,
          );
        }
      });
    }

    final rawTenantIds = raw.remove('tenantIds') ??
        raw.remove('allowedTenantIds') ??
        raw.remove('accessibleTenantIds') ??
        raw.remove('companyIds') ??
        raw.remove('allowedCompanyIds') ??
        raw.remove('accessibleCompanyIds') ??
        raw.remove('tenants') ??
        raw.remove('companies');

    for (final tenantId in _stringListFromDynamic(rawTenantIds)) {
      tenantAccess.putIfAbsent(
        tenantId,
            () => TenantPermissionData(
          tenantId: tenantId,
          enabled: true,
        ),
      );
    }

    final rawTenantRoles = raw.remove('tenantRoles');

    if (rawTenantRoles is Map) {
      rawTenantRoles.forEach((key, value) {
        final tenantId = key.toString().trim();

        if (tenantId.isEmpty) return;

        final existing = tenantAccess[tenantId];

        tenantAccess[tenantId] = (existing ??
            TenantPermissionData(
              tenantId: tenantId,
              enabled: true,
            ))
            .copyWith(
          enabled: true,
          role: SystemRoleCodec.parse(value?.toString()),
        );
      });
    }

    final rawTenantModuleOverrides = raw.remove('tenantModuleOverrides');

    if (rawTenantModuleOverrides is Map) {
      rawTenantModuleOverrides.forEach((tenantKey, modulesRaw) {
        final tenantId = tenantKey.toString().trim();

        if (tenantId.isEmpty || modulesRaw is! Map) return;

        final moduleOverrides = <String, PermissionSet>{};

        modulesRaw.forEach((moduleKey, permissionRaw) {
          final module = moduleKey.toString().trim();

          if (module.isEmpty) return;

          moduleOverrides[module] = PermissionSet.fromDynamic(permissionRaw);
        });

        final existing = tenantAccess[tenantId];

        tenantAccess[tenantId] = (existing ??
            TenantPermissionData(
              tenantId: tenantId,
              enabled: true,
            ))
            .copyWith(
          enabled: true,
          moduleOverrides: {
            ...?existing?.moduleOverrides,
            ...moduleOverrides,
          },
        );
      });
    }

    return UserPermissionData(
      uid: uid.trim(),
      globalRole: globalRole,
      globalModuleOverrides: globalModuleOverrides,
      tenantAccess: tenantAccess,
      activeTenantId: activeTenantId,
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

  static String? _cleanString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) return null;

    return text;
  }

  static List<String> _stringListFromDynamic(dynamic value) {
    final values = <String>{};

    void addValue(dynamic item) {
      if (item == null) return;

      if (item is String) {
        final parts = item.split(RegExp(r'[,;|\n]'));

        for (final part in parts) {
          final clean = part.trim();

          if (clean.isNotEmpty) {
            values.add(clean);
          }
        }

        return;
      }

      if (item is Iterable) {
        for (final child in item) {
          addValue(child);
        }

        return;
      }

      if (item is Map) {
        item.forEach((key, mapValue) {
          final cleanKey = key?.toString().trim() ?? '';

          if (cleanKey.isEmpty) return;

          if (mapValue == true) {
            values.add(cleanKey);
            return;
          }

          if (mapValue is Map) {
            final enabled = mapValue['enabled'] == true ||
                mapValue['active'] == true ||
                mapValue['allowed'] == true;

            if (enabled) {
              values.add(cleanKey);
            }
          }
        });
      }
    }

    addValue(value);

    final list = values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return list;
  }

  Map<String, dynamic> toMap() {
    final tenantIds = enabledTenantIds;

    return {
      'baseRole': SystemRoleCodec.serialize(globalRole),
      'globalRole': SystemRoleCodec.serialize(globalRole),
      if (activeTenantId != null && activeTenantId!.trim().isNotEmpty)
        'activeTenantId': activeTenantId!.trim(),
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
      'tenantIds': tenantIds,
      ...extra,
    };
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

    if (hasGlobalFreeAccess) {
      return true;
    }

    return tenantAccess[id]?.enabled == true;
  }

  SystemUserRole roleForTenant(String? tenantId) {
    final id = tenantId?.trim();

    if (hasGlobalFreeAccess) {
      return globalRole;
    }

    if (id == null || id.isEmpty) {
      return globalRole;
    }

    final access = tenantAccess[id];

    if (access?.enabled == false) {
      return SystemUserRole.leitor;
    }

    return access?.role ?? globalRole;
  }

  bool isSuperUserForTenant(String? tenantId) {
    if (hasGlobalFreeAccess) {
      return true;
    }

    return SystemRoleCodec.isSuperUser(
      roleForTenant(tenantId),
    );
  }

  PermissionSet defaultPermissionsForTenant(String? tenantId) {
    if (hasGlobalFreeAccess) {
      return PermissionSet.full;
    }

    final id = tenantId?.trim();

    if (id != null && id.isNotEmpty && !canAccessTenant(id)) {
      return PermissionSet.none;
    }

    final role = roleForTenant(id);

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
      final tenant = tenantAccess[id];

      if (tenant == null || tenant.enabled != true) {
        return PermissionSet.none;
      }

      return tenant.overrideForModule(cleanModule);
    }

    return globalModuleOverrides[cleanModule] ?? PermissionSet.none;
  }

  PermissionSet effectiveModulePermissions({
    required String module,
    String? tenantId,
  }) {
    final cleanModule = module.trim();

    if (cleanModule.isEmpty) {
      return PermissionSet.none;
    }

    if (hasGlobalFreeAccess) {
      return PermissionSet.full;
    }

    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return PermissionSet.none;
    }

    if (!canAccessTenant(id)) {
      return PermissionSet.none;
    }

    final base = defaultPermissionsForTenant(id);

    final tenantOverride =
        tenantAccess[id]?.overrideForModule(cleanModule) ?? PermissionSet.none;

    return base.mergeAllow(tenantOverride);
  }

  bool canModule({
    required String module,
    required PermissionAction action,
    String? tenantId,
  }) {
    final cleanModule = module.trim();

    if (cleanModule.isEmpty) {
      return false;
    }

    if (hasGlobalFreeAccess) {
      return true;
    }

    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return false;
    }

    if (!canAccessTenant(id)) {
      return false;
    }

    final effective = effectiveModulePermissions(
      module: cleanModule,
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
    String? activeTenantId,
    bool clearActiveTenantId = false,
    Map<String, dynamic>? extra,
  }) {
    return UserPermissionData(
      uid: uid ?? this.uid,
      globalRole: globalRole ?? this.globalRole,
      globalModuleOverrides:
      globalModuleOverrides ?? this.globalModuleOverrides,
      tenantAccess: tenantAccess ?? this.tenantAccess,
      activeTenantId:
      clearActiveTenantId ? null : activeTenantId ?? this.activeTenantId,
      extra: extra ?? this.extra,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    globalRole,
    globalModuleOverrides,
    tenantAccess,
    activeTenantId,
    extra,
  ];
}