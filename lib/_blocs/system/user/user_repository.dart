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

  // ---- helpers privados (mesma ideia do ScheduleRepository) ----
  CollectionReference<Map<String, dynamic>> _usersCol() =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCol().doc(uid);

  // Normaliza pequenos detalhes antes de salvar (ex.: name/surname trim/upper)
  Map<String, dynamic> _normalizeUserMap(Map<String, dynamic> m) {
    final name = (m['name'] ?? '').toString().trim();
    final surname = (m['surname'] ?? '').toString().trim();
    return {
      ...m,
      'name': name,
      'surname': surname,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ---------------- CRUD básico ----------------

  Future<UserData?> getById(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _userDoc(uid).get();
    return doc.exists ? UserData.fromDocument(snapshot: doc) : null;
  }

  Future<List<UserData>> getAll({int limit = 200}) async {
    final qs = await _usersCol().limit(limit).get();
    return qs.docs.map((d) => UserData.fromDocument(snapshot: d)).toList();
  }

  /// Salva/atualiza o usuário (id obrigatório no UserData)
  Future<void> save(UserData user) async {
    final id = (user.uid ?? '').trim();
    if (id.isEmpty) {
      return;
    }
    final map = _normalizeUserMap(user.toMap());
    await _userDoc(id).set(map, SetOptions(merge: true));
  }

  // ---------------- Streams (realtime) ----------------

  /// Stream do usuário autenticado (ou null se não logado)
  Stream<UserData?> currentUserStream() {
    final u = _auth.currentUser;
    if (u == null) return Stream.value(null);
    return _userDoc(u.uid).snapshots().map(
          (d) => d.exists ? UserData.fromDocument(snapshot: d) : null,
    );
  }

  /// Stream de todos os usuários (opcionalmente limitado)
  Stream<List<UserData>> usersStream({int? limit}) {
    Query<Map<String, dynamic>> q = _usersCol();
    if (limit != null && limit > 0) q = q.limit(limit);
    return q.snapshots().map(
          (snap) => snap.docs.map((d) => UserData.fromDocument(snapshot: d)).toList(),
    );
  }

  // ---------------- Notificações ----------------

  Future<void> markNotificationSeen(String uid, String notificationId) async {
    if (uid.isEmpty || notificationId.isEmpty) return;
    await _userDoc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'seen': true, 'seenAt': FieldValue.serverTimestamp()});
  }

  // ---------------- Paginação simples (opcional) ----------------

  Future<(List<UserData> page, DocumentSnapshot? lastDoc)> getAllPaged({
    int pageSize = 50,
    DocumentSnapshot? startAfter,
    String orderByField = 'name',
  }) async {
    Query<Map<String, dynamic>> q = _usersCol().orderBy(orderByField).limit(pageSize);
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final qs = await q.get();
    final list = qs.docs.map((d) => UserData.fromDocument(snapshot: d)).toList();
    final last = qs.docs.isEmpty ? null : qs.docs.last;
    return (list, last);
  }
}
