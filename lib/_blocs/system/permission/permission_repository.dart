// lib/_blocs/system/permission/permission_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'permission_data.dart';

class PermissionRepository {
  PermissionRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Mantive em `users` porque seu sistema atual já parece usar permissões
  /// dentro do documento do usuário.
  ///
  /// Se depois você quiser separar em `users_permissions/{uid}`,
  /// mudamos somente este getter.
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
      return UserPermissionData(
        uid: cleanUid,
      );
    }

    return UserPermissionData.fromDoc(snap);
  }

  Stream<UserPermissionData?> watchUserPermissions(String uid) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Stream<UserPermissionData?>.value(null);
    }

    return _userRef(cleanUid).snapshots().map((snap) {
      if (!snap.exists) {
        return UserPermissionData(
          uid: cleanUid,
        );
      }

      return UserPermissionData.fromDoc(snap);
    });
  }

  Future<void> setCurrentTenantId({
    required String uid,
    required String? tenantId,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId?.trim();

    if (cleanUid.isEmpty) {
      return;
    }

    if (cleanTenantId == null || cleanTenantId.isEmpty) {
      await _userRef(cleanUid).set(
        {
          'activeTenantId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return;
    }

    await _userRef(cleanUid).set(
      {
        'activeTenantId': cleanTenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setGlobalRole({
    required String uid,
    required PermissionUser role,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return;
    }

    await _userRef(cleanUid).set(
      {
        'globalRole': SystemRoleCodec.serialize(role),
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

    if (cleanUid.isEmpty || cleanModule.isEmpty) {
      return;
    }

    await _userRef(cleanUid).set(
      {
        'globalModuleOverrides': {
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

    if (cleanUid.isEmpty || cleanModule.isEmpty) {
      return;
    }

    await _userRef(cleanUid).set(
      {
        'globalModuleOverrides': {
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
    PermissionUser role = PermissionUser.leitor,
    String? label,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();
    final cleanLabel = label?.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) {
      return;
    }

    await _userRef(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: {
            'enabled': enabled,
            'role': SystemRoleCodec.serialize(role),
            if (cleanLabel != null && cleanLabel.isNotEmpty)
              'label': cleanLabel,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> enableTenantAccess({
    required String uid,
    required String tenantId,
    PermissionUser role = PermissionUser.leitor,
    String? label,
  }) {
    return setTenantAccess(
      uid: uid,
      tenantId: tenantId,
      enabled: true,
      role: role,
      label: label,
    );
  }

  Future<void> disableTenantAccess({
    required String uid,
    required String tenantId,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) {
      return;
    }

    await _userRef(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: {
            'enabled': false,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeTenantAccess({
    required String uid,
    required String tenantId,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) {
      return;
    }

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
    required PermissionUser role,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) {
      return;
    }

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
            'enabled': true,
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