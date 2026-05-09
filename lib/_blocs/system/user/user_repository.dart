import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';

class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _usersCol() {
    return _db.collection('users');
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _usersCol().doc(uid);
  }

  Map<String, dynamic> _normalizeUserMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? '').toString().trim();
    final surname = (map['surname'] ?? '').toString().trim();
    final email = (map['email'] ?? '').toString().trim().toLowerCase();

    return {
      ...map,
      'name': name,
      'surname': surname,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  List<String> _cleanStringList(Iterable<String> values) {
    final list = values
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<UserData?> getById(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) return null;

    final doc = await _userDoc(id).get();
    if (!doc.exists) return null;

    return UserData.fromDocument(snapshot: doc);
  }

  Future<List<UserData>> getAll({int limit = 200}) async {
    final qs = await _usersCol().limit(limit).get();

    return qs.docs
        .map((doc) => UserData.fromDocument(snapshot: doc))
        .where((user) => user.isDeleted != true)
        .toList();
  }

  Future<void> save(UserData user) async {
    final id = (user.uid ?? '').trim();
    if (id.isEmpty) return;

    final map = _normalizeUserMap(user.toMap());

    await _userDoc(id).set(
      map,
      SetOptions(merge: true),
    );
  }

  Future<void> setUserTenantAccess({
    required String uid,
    required List<String> tenantIds,
    String? primaryTenantId,
    String? activeTenantId,
  }) async {
    final userId = uid.trim();

    if (userId.isEmpty) return;

    final cleanTenantIds = _cleanStringList(tenantIds);

    final cleanPrimary = primaryTenantId?.trim();
    final cleanActive = activeTenantId?.trim();

    final data = <String, dynamic>{
      'tenantIds': cleanTenantIds,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (cleanPrimary != null && cleanPrimary.isNotEmpty) {
      data['primaryTenantId'] = cleanPrimary;
    } else if (cleanTenantIds.isNotEmpty) {
      data['primaryTenantId'] = cleanTenantIds.first;
    } else {
      data['primaryTenantId'] = FieldValue.delete();
    }

    if (cleanActive != null && cleanActive.isNotEmpty) {
      data['activeTenantId'] = cleanActive;
    } else if (cleanTenantIds.isNotEmpty) {
      data['activeTenantId'] = cleanTenantIds.first;
    } else {
      data['activeTenantId'] = FieldValue.delete();
    }

    await _userDoc(userId).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> addTenantToUser({
    required String uid,
    required String tenantId,
  }) async {
    final userId = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (userId.isEmpty || cleanTenantId.isEmpty) return;

    final user = await getById(userId);
    final current = user?.tenantIds ?? const <String>[];

    final updated = _cleanStringList([
      ...current,
      cleanTenantId,
    ]);

    await setUserTenantAccess(
      uid: userId,
      tenantIds: updated,
      primaryTenantId: user?.primaryTenantId ?? cleanTenantId,
      activeTenantId: user?.activeTenantId ?? cleanTenantId,
    );
  }

  Future<void> removeTenantFromUser({
    required String uid,
    required String tenantId,
  }) async {
    final userId = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (userId.isEmpty || cleanTenantId.isEmpty) return;

    final user = await getById(userId);
    final current = user?.tenantIds ?? const <String>[];

    final updated = _cleanStringList(
      current.where(
            (id) => id.trim().toLowerCase() != cleanTenantId.toLowerCase(),
      ),
    );

    final oldPrimary = user?.primaryTenantId?.trim();
    final oldActive = user?.activeTenantId?.trim();

    final nextPrimary =
    updated.contains(oldPrimary) ? oldPrimary : updated.firstOrNull;

    final nextActive = updated.contains(oldActive) ? oldActive : nextPrimary;

    await setUserTenantAccess(
      uid: userId,
      tenantIds: updated,
      primaryTenantId: nextPrimary,
      activeTenantId: nextActive,
    );
  }

  Future<void> setActiveTenantForUser({
    required String uid,
    required String tenantId,
  }) async {
    final userId = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (userId.isEmpty || cleanTenantId.isEmpty) return;

    await _userDoc(userId).set(
      {
        'activeTenantId': cleanTenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deactivateUser(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) return;

    await _userDoc(id).set(
      {
        'isActive': false,
        'isBlocked': false,
        'isDeleted': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivatedReason': 'Desativado temporariamente pelo administrador.',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> reactivateUser(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) return;

    await _userDoc(id).set(
      {
        'isActive': true,
        'isBlocked': false,
        'isDeleted': false,
        'deactivatedAt': null,
        'deactivatedReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> blockUser(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) return;

    await _userDoc(id).set(
      {
        'isActive': false,
        'isBlocked': true,
        'isDeleted': false,
        'blockedAt': FieldValue.serverTimestamp(),
        'blockedReason': 'Bloqueado pelo administrador.',
        'baseRole': null,
        'baseProfile': null,
        'globalRole': null,
        'tenantRoles': <String, dynamic>{},
        'modulePermissions': <String, dynamic>{},
        'moduleOverrides': <String, dynamic>{},
        'tenantModuleOverrides': <String, dynamic>{},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> softDeleteUser(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) return;

    await _userDoc(id).set(
      {
        'isActive': false,
        'isBlocked': true,
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedReason': 'Excluído pelo administrador.',
        'baseRole': null,
        'baseProfile': null,
        'globalRole': null,
        'tenantRoles': <String, dynamic>{},
        'modulePermissions': <String, dynamic>{},
        'moduleOverrides': <String, dynamic>{},
        'tenantModuleOverrides': <String, dynamic>{},
        'tenantIds': <String>[],
        'primaryTenantId': FieldValue.delete(),
        'activeTenantId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> hardDeleteUserDocument(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) return;

    await _deleteUserStorageFolder(id);
    await _userDoc(id).delete();
  }

  Future<void> _deleteUserStorageFolder(String uid) async {
    try {
      final ref = _storage.ref().child('users').child(uid);
      final list = await ref.listAll();

      for (final item in list.items) {
        await item.delete();
      }

      for (final prefix in list.prefixes) {
        final nested = await prefix.listAll();

        for (final item in nested.items) {
          await item.delete();
        }
      }
    } catch (_) {
      // Ignora storage inexistente.
    }
  }

  Stream<UserData?> currentUserStream() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value(null);
    }

    return _userDoc(currentUser.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserData.fromDocument(snapshot: doc);
    });
  }

  Stream<List<UserData>> usersStream({int? limit}) {
    Query<Map<String, dynamic>> query = _usersCol();

    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((doc) => UserData.fromDocument(snapshot: doc))
          .where((user) => user.isDeleted != true)
          .toList();
    });
  }

  Future<void> markNotificationSeen(String uid, String notificationId) async {
    final userId = uid.trim();
    final notifId = notificationId.trim();

    if (userId.isEmpty || notifId.isEmpty) return;

    await _userDoc(userId)
        .collection('notifications')
        .doc(notifId)
        .update({
      'seen': true,
      'seenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<(List<UserData> page, DocumentSnapshot? lastDoc)> getAllPaged({
    int pageSize = 50,
    DocumentSnapshot? startAfter,
    String orderByField = 'name',
  }) async {
    Query<Map<String, dynamic>> query =
    _usersCol().orderBy(orderByField).limit(pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final qs = await query.get();

    final list = qs.docs
        .map((doc) => UserData.fromDocument(snapshot: doc))
        .where((user) => user.isDeleted != true)
        .toList();

    final last = qs.docs.isEmpty ? null : qs.docs.last;

    return (list, last);
  }
}