// lib/_blocs/system/permission/permission_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'permission_data.dart';

class PermissionRepository {
  PermissionRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef {
    return _firestore.collection('users');
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _usersRef.doc(uid.trim());
  }

  Future<UserPermissionData?> loadUserPermissions(String uid) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    final snap = await _userRef(cleanUid).get();

    if (!snap.exists) {
      return null;
    }

    return UserPermissionData.fromDoc(snap);
  }

  Stream<UserPermissionData?> watchUserPermissions(String uid) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Stream<UserPermissionData?>.value(null);
    }

    return _userRef(cleanUid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserPermissionData.fromDoc(snap);
    });
  }

  Future<void> setGlobalRole({
    required String uid,
    required SystemUserRole role,
    bool writeLegacyBaseProfile = true,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) return;

    final roleId = SystemRoleCodec.serialize(role);

    await _userRef(cleanUid).set(
      {
        'baseRole': roleId,
        if (writeLegacyBaseProfile) 'baseProfile': roleId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setGlobalModuleOverride({
    required String uid,
    required String module,
    required PermissionSet permissions,
  }) async {
    final cleanUid = uid.trim();
    final cleanModule = module.trim();

    if (cleanUid.isEmpty || cleanModule.isEmpty) return;

    await _userRef(cleanUid).set(
      {
        'moduleOverrides': {
          cleanModule: permissions.toMap(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeGlobalModuleOverride({
    required String uid,
    required String module,
  }) async {
    final cleanUid = uid.trim();
    final cleanModule = module.trim();

    if (cleanUid.isEmpty || cleanModule.isEmpty) return;

    await _userRef(cleanUid).set(
      {
        'moduleOverrides': {
          cleanModule: FieldValue.delete(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setTenantAccess({
    required String uid,
    required String tenantId,
    bool enabled = true,
    SystemUserRole? role,
    String? label,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) return;

    await _userRef(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: {
            'enabled': enabled,
            if (role != null) 'role': SystemRoleCodec.serialize(role),
            if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> disableTenantAccess({
    required String uid,
    required String tenantId,
  }) {
    return setTenantAccess(
      uid: uid,
      tenantId: tenantId,
      enabled: false,
    );
  }

  Future<void> removeTenantAccess({
    required String uid,
    required String tenantId,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) return;

    await _userRef(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: FieldValue.delete(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setTenantRole({
    required String uid,
    required String tenantId,
    required SystemUserRole role,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) return;

    await _userRef(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: {
            'enabled': true,
            'role': SystemRoleCodec.serialize(role),
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setTenantModuleOverride({
    required String uid,
    required String tenantId,
    required String module,
    required PermissionSet permissions,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();
    final cleanModule = module.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty || cleanModule.isEmpty) {
      return;
    }

    await _userRef(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: {
            'moduleOverrides': {
              cleanModule: permissions.toMap(),
            },
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeTenantModuleOverride({
    required String uid,
    required String tenantId,
    required String module,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();
    final cleanModule = module.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty || cleanModule.isEmpty) {
      return;
    }

    await _userRef(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: {
            'moduleOverrides': {
              cleanModule: FieldValue.delete(),
            },
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}