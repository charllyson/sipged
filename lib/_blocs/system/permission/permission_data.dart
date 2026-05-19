import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/module/module_catalog.dart';

/// ============================================================================
/// PERMISSION DATA MODEL
///
/// Schema canônico esperado no Firestore:
///
/// users_permissions/{uid}
/// {
///   "globalRole": "LEITOR",
///   "activeTenantId": "tenant_123",
///   "globalModuleOverrides": {
///     "module_id": {
///       "read": true,
///       "create": false,
///       "edit": false,
///       "delete": false,
///       "approve": false
///     }
///   },
///   "tenantAccess": {
///     "tenant_123": {
///       "enabled": true,
///       "role": "GESTOR_REGIONAL",
///       "label": "Empresa A",
///       "moduleOverrides": {
///         "contracts_list": {
///           "read": true,
///           "create": true,
///           "edit": false,
///           "delete": false,
///           "approve": false
///         }
///       }
///     }
///   }
/// }
///
/// Regras principais:
/// - Administrador e Desenvolvedor têm acesso total.
/// - Usuário precisa ter acesso ao tenant.
/// - Para módulos gerais, vale a permissão do módulo.
/// - Para contratos, a permissão documental do contrato pode liberar a ação.
/// - A permissão de módulo funciona como fallback para telas gerais.
/// ============================================================================

enum PermissionType {
  read,
  create,
  edit,
  delete,
  approve,
}

enum PermissionUser {
  administrador,
  desenvolvedor,
  gestorRegional,
  fiscal,
  colaborador,
  leitor,
}

/// ============================================================================
/// ROLE CODEC
/// ============================================================================

class SystemRoleCodec {
  const SystemRoleCodec._();

  static const Map<PermissionUser, String> _ids = {
    PermissionUser.administrador: 'ADMINISTRADOR',
    PermissionUser.desenvolvedor: 'DESENVOLVEDOR',
    PermissionUser.gestorRegional: 'GESTOR_REGIONAL',
    PermissionUser.fiscal: 'FISCAL',
    PermissionUser.colaborador: 'COLABORADOR',
    PermissionUser.leitor: 'LEITOR',
  };

  static const Map<PermissionUser, String> _labels = {
    PermissionUser.administrador: 'Administrador',
    PermissionUser.desenvolvedor: 'Desenvolvedor',
    PermissionUser.gestorRegional: 'Gestor Regional',
    PermissionUser.fiscal: 'Fiscal',
    PermissionUser.colaborador: 'Colaborador',
    PermissionUser.leitor: 'Leitor',
  };

  static String serialize(PermissionUser role) {
    return _ids[role]!;
  }

  static String label(PermissionUser role) {
    return _labels[role]!;
  }

  static PermissionUser? tryParse(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    for (final entry in _ids.entries) {
      if (entry.value == text) {
        return entry.key;
      }
    }

    for (final role in PermissionUser.values) {
      if (role.name == text) {
        return role;
      }
    }

    return null;
  }

  static PermissionUser parseOrDefault(
      String? value, {
        PermissionUser fallback = PermissionUser.leitor,
      }) {
    return tryParse(value) ?? fallback;
  }

  static bool isSuperUser(PermissionUser role) {
    return role == PermissionUser.administrador ||
        role == PermissionUser.desenvolvedor;
  }
}

/// ============================================================================
/// ACTION CODEC
/// ============================================================================

class PermissionActionCodec {
  const PermissionActionCodec._();

  static String serialize(PermissionType action) {
    switch (action) {
      case PermissionType.read:
        return 'read';
      case PermissionType.create:
        return 'create';
      case PermissionType.edit:
        return 'edit';
      case PermissionType.delete:
        return 'delete';
      case PermissionType.approve:
        return 'approve';
    }
  }

  static PermissionType? tryParse(String? value) {
    final text = value?.trim().toLowerCase();

    if (text == null || text.isEmpty) {
      return null;
    }

    for (final action in PermissionType.values) {
      if (action.name == text) {
        return action;
      }
    }

    return null;
  }

  static PermissionType parseOrDefault(
      String? value, {
        PermissionType fallback = PermissionType.read,
      }) {
    return tryParse(value) ?? fallback;
  }
}

/// ============================================================================
/// PERMISSION SET
/// ============================================================================

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

  static const PermissionSet none = PermissionSet();

  static const PermissionSet readOnly = PermissionSet(
    read: true,
  );

  static const PermissionSet full = PermissionSet(
    read: true,
    create: true,
    edit: true,
    delete: true,
    approve: true,
  );

  bool get isNone {
    return !read && !create && !edit && !delete && !approve;
  }

  bool get isFull {
    return read && create && edit && delete && approve;
  }

  bool allows(PermissionType action) {
    switch (action) {
      case PermissionType.read:
        return read || create || edit || delete || approve;

      case PermissionType.create:
        return create || edit || delete || approve;

      case PermissionType.edit:
        return edit || delete || approve;

      case PermissionType.delete:
        return delete || approve;

      case PermissionType.approve:
        return approve;
    }
  }

  bool allowsString(String action) {
    final parsedAction = PermissionActionCodec.tryParse(action);

    if (parsedAction == null) {
      return false;
    }

    return allows(parsedAction);
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

  Map<String, bool> toMap() {
    return <String, bool>{
      'read': read,
      'create': create,
      'edit': edit,
      'delete': delete,
      'approve': approve,
    };
  }

  factory PermissionSet.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return PermissionSet.none;
    }

    return PermissionSet(
      read: map['read'] == true,
      create: map['create'] == true,
      edit: map['edit'] == true,
      delete: map['delete'] == true,
      approve: map['approve'] == true,
    );
  }

  factory PermissionSet.fromBoolMap(Map<String, bool>? map) {
    if (map == null) {
      return PermissionSet.none;
    }

    return PermissionSet(
      read: map['read'] == true,
      create: map['create'] == true,
      edit: map['edit'] == true,
      delete: map['delete'] == true,
      approve: map['approve'] == true,
    );
  }

  factory PermissionSet.fromDynamic(dynamic value) {
    if (value == null) {
      return PermissionSet.none;
    }

    if (value is PermissionSet) {
      return value;
    }

    if (value is Map<String, dynamic>) {
      return PermissionSet.fromMap(value);
    }

    if (value is Map) {
      return PermissionSet.fromMap(
        value.map(
              (key, mapValue) {
            return MapEntry(
              key.toString(),
              mapValue,
            );
          },
        ),
      );
    }

    return PermissionSet.none;
  }

  @override
  List<Object?> get props {
    return <Object?>[
      read,
      create,
      edit,
      delete,
      approve,
    ];
  }
}

/// ============================================================================
/// TENANT PERMISSION DATA
/// ============================================================================

class TenantPermissionData extends Equatable {
  final String tenantId;
  final bool enabled;
  final PermissionUser role;
  final String? label;
  final Map<String, PermissionSet> moduleOverrides;

  const TenantPermissionData({
    required this.tenantId,
    this.enabled = true,
    this.role = PermissionUser.leitor,
    this.label,
    this.moduleOverrides = const <String, PermissionSet>{},
  });

  factory TenantPermissionData.fromMap({
    required String tenantId,
    required Map<String, dynamic>? map,
  }) {
    final data = map ?? const <String, dynamic>{};

    final rawModules = data['moduleOverrides'];
    final moduleOverrides = <String, PermissionSet>{};

    if (rawModules is Map) {
      rawModules.forEach((key, value) {
        final moduleId = key.toString().trim();

        if (moduleId.isEmpty) {
          return;
        }

        moduleOverrides[moduleId] = PermissionSet.fromDynamic(value);
      });
    }

    final labelText = data['label']?.toString().trim();

    return TenantPermissionData(
      tenantId: tenantId.trim(),
      enabled: data['enabled'] == true,
      role: SystemRoleCodec.parseOrDefault(
        data['role']?.toString(),
      ),
      label: labelText == null || labelText.isEmpty ? null : labelText,
      moduleOverrides: moduleOverrides,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'role': SystemRoleCodec.serialize(role),
      if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
      'moduleOverrides': <String, dynamic>{
        for (final entry in moduleOverrides.entries)
          entry.key: entry.value.toMap(),
      },
    };
  }

  TenantPermissionData copyWith({
    String? tenantId,
    bool? enabled,
    PermissionUser? role,
    String? label,
    bool clearLabel = false,
    Map<String, PermissionSet>? moduleOverrides,
  }) {
    return TenantPermissionData(
      tenantId: tenantId ?? this.tenantId,
      enabled: enabled ?? this.enabled,
      role: role ?? this.role,
      label: clearLabel ? null : label ?? this.label,
      moduleOverrides: moduleOverrides ?? this.moduleOverrides,
    );
  }

  PermissionSet permissionForModule(String module) {
    final moduleId = module.trim();

    if (moduleId.isEmpty) {
      return PermissionSet.none;
    }

    return moduleOverrides[moduleId] ?? PermissionSet.none;
  }

  bool hasModule(String module) {
    return !permissionForModule(module).isNone;
  }

  @override
  List<Object?> get props {
    return <Object?>[
      tenantId,
      enabled,
      role,
      label,
      moduleOverrides,
    ];
  }
}

/// ============================================================================
/// USER PERMISSION DATA
/// ============================================================================

class UserPermissionData extends Equatable {
  final String uid;
  final PermissionUser globalRole;
  final Map<String, PermissionSet> globalModuleOverrides;
  final Map<String, TenantPermissionData> tenantAccess;
  final String? activeTenantId;

  const UserPermissionData({
    required this.uid,
    this.globalRole = PermissionUser.leitor,
    this.globalModuleOverrides = const <String, PermissionSet>{},
    this.tenantAccess = const <String, TenantPermissionData>{},
    this.activeTenantId,
  });

  const UserPermissionData.empty()
      : uid = '',
        globalRole = PermissionUser.leitor,
        globalModuleOverrides = const <String, PermissionSet>{},
        tenantAccess = const <String, TenantPermissionData>{},
        activeTenantId = null;

  bool get isEmpty {
    return uid.trim().isEmpty;
  }

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

  Map<String, PermissionUser> get tenantRoles {
    return <String, PermissionUser>{
      for (final entry in tenantAccess.entries)
        if (entry.value.enabled) entry.key: entry.value.role,
    };
  }

  Map<String, Map<String, PermissionSet>> get tenantModuleOverrides {
    return <String, Map<String, PermissionSet>>{
      for (final entry in tenantAccess.entries)
        if (entry.value.moduleOverrides.isNotEmpty)
          entry.key: entry.value.moduleOverrides,
    };
  }

  factory UserPermissionData.fromMap({
    required String uid,
    required Map<String, dynamic>? map,
  }) {
    if (map == null) {
      return UserPermissionData(
        uid: uid.trim(),
      );
    }

    final globalModuleOverrides = <String, PermissionSet>{};
    final rawGlobalModules = map['globalModuleOverrides'];

    if (rawGlobalModules is Map) {
      rawGlobalModules.forEach((key, value) {
        final moduleId = key.toString().trim();

        if (moduleId.isEmpty) {
          return;
        }

        globalModuleOverrides[moduleId] = PermissionSet.fromDynamic(value);
      });
    }

    final tenantAccess = <String, TenantPermissionData>{};
    final rawTenantAccess = map['tenantAccess'];

    if (rawTenantAccess is Map) {
      rawTenantAccess.forEach((key, value) {
        final tenantId = key.toString().trim();

        if (tenantId.isEmpty) {
          return;
        }

        if (value is Map) {
          tenantAccess[tenantId] = TenantPermissionData.fromMap(
            tenantId: tenantId,
            map: value.map(
                  (mapKey, mapValue) {
                return MapEntry(
                  mapKey.toString(),
                  mapValue,
                );
              },
            ),
          );
        }
      });
    }

    final activeTenantText = map['activeTenantId']?.toString().trim();

    return UserPermissionData(
      uid: uid.trim(),
      globalRole: SystemRoleCodec.parseOrDefault(
        map['globalRole']?.toString(),
      ),
      globalModuleOverrides: globalModuleOverrides,
      tenantAccess: tenantAccess,
      activeTenantId: activeTenantText == null || activeTenantText.isEmpty
          ? null
          : activeTenantText,
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
    return <String, dynamic>{
      'globalRole': SystemRoleCodec.serialize(globalRole),
      if (activeTenantId != null && activeTenantId!.trim().isNotEmpty)
        'activeTenantId': activeTenantId!.trim(),
      'globalModuleOverrides': <String, dynamic>{
        for (final entry in globalModuleOverrides.entries)
          entry.key: entry.value.toMap(),
      },
      'tenantAccess': <String, dynamic>{
        for (final entry in tenantAccess.entries) entry.key: entry.value.toMap(),
      },
    };
  }

  UserPermissionData copyWith({
    String? uid,
    PermissionUser? globalRole,
    Map<String, PermissionSet>? globalModuleOverrides,
    Map<String, TenantPermissionData>? tenantAccess,
    String? activeTenantId,
    bool clearActiveTenantId = false,
  }) {
    return UserPermissionData(
      uid: uid ?? this.uid,
      globalRole: globalRole ?? this.globalRole,
      globalModuleOverrides:
      globalModuleOverrides ?? this.globalModuleOverrides,
      tenantAccess: tenantAccess ?? this.tenantAccess,
      activeTenantId:
      clearActiveTenantId ? null : activeTenantId ?? this.activeTenantId,
    );
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
        .where((tenantId) => available.contains(tenantId))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return list;
  }

  TenantPermissionData? tenantPermission(String? tenantId) {
    final id = _cleanId(tenantId);

    if (id == null) {
      return null;
    }

    return tenantAccess[id];
  }

  bool canAccessTenant(String? tenantId) {
    final id = _cleanId(tenantId);

    if (id == null) {
      return false;
    }

    if (hasGlobalFreeAccess) {
      return true;
    }

    return tenantAccess[id]?.enabled == true;
  }

  PermissionUser roleForTenant(String? tenantId) {
    final id = _cleanId(tenantId);

    if (hasGlobalFreeAccess) {
      return globalRole;
    }

    if (id == null) {
      return PermissionUser.leitor;
    }

    final tenant = tenantAccess[id];

    if (tenant == null || tenant.enabled == false) {
      return PermissionUser.leitor;
    }

    return tenant.role;
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

    final id = _cleanId(tenantId);

    if (id == null) {
      return PermissionSet.none;
    }

    if (!canAccessTenant(id)) {
      return PermissionSet.none;
    }

    final role = roleForTenant(id);

    if (SystemRoleCodec.isSuperUser(role)) {
      return PermissionSet.full;
    }

    return PermissionSet.none;
  }

  PermissionSet modulePermission({
    required String module,
    String? tenantId,
  }) {
    final moduleId = module.trim();

    if (moduleId.isEmpty) {
      return PermissionSet.none;
    }

    if (hasGlobalFreeAccess) {
      return PermissionSet.full;
    }

    final id = _cleanId(tenantId);

    if (id == null) {
      return globalModuleOverrides[moduleId] ?? PermissionSet.none;
    }

    final tenant = tenantAccess[id];

    if (tenant == null || tenant.enabled == false) {
      return PermissionSet.none;
    }

    final tenantModulePermission = tenant.permissionForModule(moduleId);

    if (!tenantModulePermission.isNone) {
      return tenantModulePermission;
    }

    return globalModuleOverrides[moduleId] ?? PermissionSet.none;
  }

  PermissionSet effectiveModulePermissions({
    required String module,
    String? tenantId,
  }) {
    final moduleId = module.trim();

    if (moduleId.isEmpty) {
      return PermissionSet.none;
    }

    if (hasGlobalFreeAccess) {
      return PermissionSet.full;
    }

    final id = _cleanId(tenantId);

    if (id == null || !canAccessTenant(id)) {
      return PermissionSet.none;
    }

    final base = defaultPermissionsForTenant(id);
    final moduleSpecific = modulePermission(
      module: moduleId,
      tenantId: id,
    );

    return base.mergeAllow(moduleSpecific);
  }

  bool canModule({
    required String module,
    required PermissionType action,
    String? tenantId,
  }) {
    final moduleId = module.trim();

    if (moduleId.isEmpty) {
      return false;
    }

    if (hasGlobalFreeAccess) {
      return true;
    }

    final id = _cleanId(tenantId);

    if (id == null) {
      return false;
    }

    if (!canAccessTenant(id)) {
      return false;
    }

    final effective = effectiveModulePermissions(
      module: moduleId,
      tenantId: id,
    );

    return effective.allows(action);
  }

  bool canModuleString({
    required String module,
    required String action,
    String? tenantId,
  }) {
    final parsedAction = PermissionActionCodec.tryParse(action);

    if (parsedAction == null) {
      return false;
    }

    return canModule(
      module: module,
      action: parsedAction,
      tenantId: tenantId,
    );
  }

  static String? _cleanId(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  @override
  List<Object?> get props {
    return <Object?>[
      uid,
      globalRole,
      globalModuleOverrides,
      tenantAccess,
      activeTenantId,
    ];
  }
}

/// ============================================================================
/// SYSTEM PERMISSION
///
/// Centraliza regras de autorização do sistema.
/// ============================================================================

class SystemPermission {
  const SystemPermission._();

  static const List<String> docPermissionKeys = <String>[
    'read',
    'create',
    'edit',
    'delete',
    'approve',
  ];

  static Map<String, bool> initialDocPerms() {
    return const <String, bool>{
      'read': true,
      'create': false,
      'edit': false,
      'delete': false,
      'approve': false,
    };
  }

  static Map<String, bool> emptyDocPerms() {
    return const <String, bool>{
      'read': false,
      'create': false,
      'edit': false,
      'delete': false,
      'approve': false,
    };
  }

  static Map<String, bool> normalizeDocPerms(dynamic raw) {
    if (raw is! Map) {
      return emptyDocPerms();
    }

    return <String, bool>{
      'read': raw['read'] == true,
      'create': raw['create'] == true,
      'edit': raw['edit'] == true,
      'delete': raw['delete'] == true,
      'approve': raw['approve'] == true,
    };
  }

  static PermissionSet permissionSetFromDocPerms(dynamic raw) {
    return PermissionSet.fromBoolMap(
      normalizeDocPerms(raw),
    );
  }

  static Map<String, dynamic>? participantInfoOf({
    required ContractData contract,
    required String uid,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    return contract.participantsInfo[cleanUid];
  }

  static PermissionSet docPermissionsOf({
    required ContractData contract,
    required String uid,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return PermissionSet.none;
    }

    final participant = participantInfoOf(
      contract: contract,
      uid: cleanUid,
    );

    if (participant == null) {
      return PermissionSet.none;
    }

    if (participant['active'] == false) {
      return PermissionSet.none;
    }

    return permissionSetFromDocPerms(
      participant['permissions'],
    );
  }

  static bool hasContractParticipant({
    required ContractData contract,
    required String uid,
  }) {
    final participant = participantInfoOf(
      contract: contract,
      uid: uid,
    );

    if (participant == null) {
      return false;
    }

    return participant['active'] != false;
  }

  static bool canContractDocOnly({
    required UserPermissionData permissions,
    required ContractData contract,
    required String action,
    String? tenantId,
  }) {
    final cleanTenantId = _cleanId(tenantId);

    if (permissions.isSuperUserForTenant(cleanTenantId)) {
      return true;
    }

    final cleanAction = action.trim().toLowerCase();

    if (cleanAction.isEmpty) {
      return false;
    }

    final parsedAction = PermissionActionCodec.tryParse(cleanAction);

    if (parsedAction == null) {
      return false;
    }

    final uid = permissions.uid.trim();

    if (uid.isEmpty) {
      return false;
    }

    final docPerms = docPermissionsOf(
      contract: contract,
      uid: uid,
    );

    return docPerms.allows(parsedAction);
  }

  static bool canContractByModuleOnly({
    required UserPermissionData permissions,
    required String action,
    required String module,
    String? tenantId,
  }) {
    final cleanTenantId = _cleanId(tenantId);
    final cleanModule = module.trim();
    final cleanAction = action.trim().toLowerCase();

    if (cleanTenantId == null || cleanModule.isEmpty || cleanAction.isEmpty) {
      return false;
    }

    if (permissions.isSuperUserForTenant(cleanTenantId)) {
      return true;
    }

    if (!permissions.canAccessTenant(cleanTenantId)) {
      return false;
    }

    final parsedAction = PermissionActionCodec.tryParse(cleanAction);

    if (parsedAction == null) {
      return false;
    }

    return permissions.canModule(
      module: cleanModule,
      action: parsedAction,
      tenantId: cleanTenantId,
    );
  }

  static bool canContract({
    required UserPermissionData permissions,
    required ContractData contract,
    required String action,
    String module = ModuleCatalog.modContractsList,
    String? tenantId,
  }) {
    final cleanTenantId = _cleanId(tenantId);
    final cleanModule = module.trim();
    final cleanAction = action.trim().toLowerCase();

    if (cleanModule.isEmpty || cleanAction.isEmpty) {
      return false;
    }

    final parsedAction = PermissionActionCodec.tryParse(cleanAction);

    if (parsedAction == null) {
      return false;
    }

    if (permissions.isSuperUserForTenant(cleanTenantId)) {
      return true;
    }

    if (cleanTenantId == null) {
      return false;
    }

    if (!permissions.canAccessTenant(cleanTenantId)) {
      return false;
    }

    final canByDocument = canContractDocOnly(
      permissions: permissions,
      contract: contract,
      action: cleanAction,
      tenantId: cleanTenantId,
    );

    if (canByDocument) {
      return true;
    }

    return permissions.canModule(
      module: cleanModule,
      action: parsedAction,
      tenantId: cleanTenantId,
    );
  }

  static List<ContractData> filterVisibleContracts({
    required UserPermissionData permissions,
    required Iterable<ContractData> contracts,
    String module = ModuleCatalog.modContractsList,
    String? tenantId,
  }) {
    final cleanTenantId = _cleanId(tenantId);
    final cleanModule = module.trim();

    if (cleanModule.isEmpty) {
      return const <ContractData>[];
    }

    if (permissions.isSuperUserForTenant(cleanTenantId)) {
      return contracts.toList(growable: false);
    }

    if (cleanTenantId == null) {
      return const <ContractData>[];
    }

    if (!permissions.canAccessTenant(cleanTenantId)) {
      return const <ContractData>[];
    }

    return contracts.where((contract) {
      return canContract(
        permissions: permissions,
        contract: contract,
        action: PermissionActionCodec.serialize(PermissionType.read),
        module: cleanModule,
        tenantId: cleanTenantId,
      );
    }).toList(growable: false);
  }

  static String? _cleanId(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}