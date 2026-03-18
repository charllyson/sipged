import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/permitions/user_permission.dart' as up;
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import '../module/module_data.dart';

const kPermKeys = <String>['read', 'create', 'edit', 'delete', 'approve'];

// ✅ liga/desliga logs de permissão
const bool kDebugPerms = true;

class ModulePermissions {
  final bool read, create, edit, delete, approve;

  const ModulePermissions({
    this.read = false,
    this.create = false,
    this.edit = false,
    this.delete = false,
    this.approve = false,
  });

  ModulePermissions copyWith({
    bool? read,
    bool? create,
    bool? edit,
    bool? delete,
    bool? approve,
  }) =>
      ModulePermissions(
        read: read ?? this.read,
        create: create ?? this.create,
        edit: edit ?? this.edit,
        delete: delete ?? this.delete,
        approve: approve ?? this.approve,
      );

  ModulePermissions merge(ModulePermissions other) => ModulePermissions(
    read: read || other.read,
    create: create || other.create,
    edit: edit || other.edit,
    delete: delete || other.delete,
    approve: approve || other.approve,
  );

  Map<String, bool> toBoolMap() => {
    'read': read,
    'create': create,
    'edit': edit,
    'delete': delete,
    'approve': approve,
  };

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(toBoolMap());

  factory ModulePermissions.fromMap(Map<String, dynamic>? m) {
    m ??= const {};
    return ModulePermissions(
      read: m['read'] == true,
      create: m['create'] == true,
      edit: m['edit'] == true,
      delete: m['delete'] == true,
      approve: m['approve'] == true,
    );
  }

  static const none = ModulePermissions();
}

// ---------------------------------------------------------------------------
// helpers básicos
// ---------------------------------------------------------------------------
Map<String, bool> normalizePermMap(Map<String, bool>? raw) {
  final r = raw ?? const {};
  return {for (final k in kPermKeys) k: r[k] == true};
}

Map<String, bool> initialDocPerms() => const {
  'read': true,
  'create': false,
  'edit': false,
  'delete': false,
  'approve': false,
};

Map<String, bool> toFiveKeys(Map? raw) {
  if (raw == null) return normalizePermMap(const {});
  final m = <String, bool>{};
  raw.forEach((key, value) {
    if (key is String) m[key] = value == true;
  });
  return normalizePermMap(m);
}

// ---------------------------------------------------------------------------
// defaults por papel global (módulo)
// ---------------------------------------------------------------------------
ModulePermissions defaultPermsForRole(up.UserProfile role) {
  switch (role) {
    case up.UserProfile.administrador:
    case up.UserProfile.developer:
      return const ModulePermissions(
        read: true,
        create: true,
        edit: true,
        delete: true,
        approve: true,
      );

    case up.UserProfile.regionalManager:
    case up.UserProfile.fiscal:
    case up.UserProfile.collaborator:
    case up.UserProfile.readerOnly:
      return const ModulePermissions(read: false);
  }
}

// ---------------------------------------------------------------------------
// overrides por módulo no usuário (users/{uid}.moduleOverrides.<module>)
// ---------------------------------------------------------------------------
ModulePermissions getOverrideForUserModule(UserData user, String module) {
  final data = user.userSnap?.data();
  final raw = data?['moduleOverrides'];

  if (raw is! Map) return ModulePermissions.none;

  // moduleOverrides: { "<module>": {read:true,...} }
  final modRaw = raw[module];
  if (modRaw is! Map) return ModulePermissions.none;

  final m = <String, dynamic>{};
  modRaw.forEach((key, value) {
    if (key is String) m[key] = value;
  });

  return ModulePermissions.fromMap(m);
}

Future<void> setOverrideForUserModule(
    UserData user,
    String module,
    ModulePermissions perms,
    ) async {
  final uid = (user.uid ?? '').trim();
  if (uid.isEmpty) return;

  final ref = FirebaseFirestore.instance.collection('users').doc(uid);
  await ref.set(
    {
      'moduleOverrides': {module: perms.toMap()},
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}

ModulePermissions effectiveModulePerms(UserData user, String module) {
  final base = defaultPermsForRole(up.roleForUser(user));
  final ov = getOverrideForUserModule(user, module);
  final eff = base.merge(ov);

  return eff;
}

// ---------------------------------------------------------------------------
// checks para UI/Router
// ---------------------------------------------------------------------------
bool userCanModule({
  required UserData user,
  required String module,
  required String action, // read|create|edit|delete|approve
}) {
  final eff = effectiveModulePerms(user, module);

  final result = switch (action) {
    'read' => eff.read,
    'create' => eff.create || eff.edit || eff.delete || eff.approve,
    'edit' => eff.edit || eff.delete || eff.approve,
    'delete' => eff.delete || eff.approve,
    'approve' => eff.approve,
    _ => false,
  };

  return result;
}

bool userCanOnContract({
  required UserData user,
  required ProcessData contract,
  required String action,
  String module = ModuleData.modContractsList,
}) {
  if (!userCanModule(user: user, module: module, action: action)) {
    return false;
  }

  final role = up.roleForUser(user);
  if (role == up.UserProfile.administrador || role == up.UserProfile.developer) {
    return true;
  }

  final uid = (user.uid ?? '').trim();
  if (uid.isEmpty) return false;

  final docPerms = contract.permissionContractId[uid];
  if (docPerms == null) {
    return false;
  }

  final p = ModulePermissions.fromMap(docPerms);

  final ok = switch (action) {
    'read' => p.read || p.create || p.edit || p.delete || p.approve,
    'create' => p.create || p.edit || p.delete || p.approve,
    'edit' => p.edit || p.delete || p.approve,
    'delete' => p.delete || p.approve,
    'approve' => p.approve,
    _ => false,
  };
  return ok;
}
