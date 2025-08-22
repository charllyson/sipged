import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sisged/_datas/system/user_data.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  Future<UserData?> getById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserData.fromDocument(snapshot: doc) : null;
  }

  Stream<UserData?> currentUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(null);
    return _db.collection('users').doc(user.uid).snapshots().map(
          (d) => d.exists ? UserData.fromDocument(snapshot: d) : null,
    );
  }

  Future<List<UserData>> getAll({int limit = 200}) async {
    final qs = await _db.collection('users').limit(limit).get();
    return qs.docs.map((d) => UserData.fromDocument(snapshot: d)).toList();
  }

  Future<void> save(UserData user) async {
    if (user.id == null) return;
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> markNotificationSeen(String uid, String notificationId) {
    return _db.collection('users').doc(uid)
        .collection('notifications').doc(notificationId)
        .update({'seen': true});
  }
}
