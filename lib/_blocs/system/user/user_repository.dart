// lib/_blocs/system/user/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';

class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _usersCol() {
    return _db.collection('users');
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _usersCol().doc(uid);
  }

  Map<String, dynamic> _normalizeUserMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? '').toString().trim();
    final surname = (map['surname'] ?? '').toString().trim();

    return {
      ...map,
      'name': name,
      'surname': surname,
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
        .toList();

    final last = qs.docs.isEmpty ? null : qs.docs.last;

    return (list, last);
  }
}