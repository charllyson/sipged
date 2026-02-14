import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore db;

  LoginRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : auth = auth ?? FirebaseAuth.instance,
        db = db ?? FirebaseFirestore.instance;

  static const String _kLastEmailKey = 'sipged_last_login_email';

  Stream<User?> authStateChanges() => auth.authStateChanges();

  User? get currentUser => auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => auth.signOut();

  Future<void> recoverPass(String email) {
    return auth.sendPasswordResetEmail(email: email);
  }

  Future<Map<String, dynamic>?> getUserDocByUid(String uid) async {
    final doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, dynamic>?> getUserDocByEmailLower(String emailLower) async {
    final q = await db
        .collection('users')
        .where('email', isEqualTo: emailLower) // ideal: email salvo lowerCase
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.data();
  }

  // ===================== Local storage (último email) =====================

  Future<void> saveLastEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastEmailKey, e);
  }

  Future<String?> loadLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kLastEmailKey);
    final e = v?.trim();
    if (e == null || e.isEmpty) return null;
    return e;
  }

  Future<void> clearLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastEmailKey);
  }
}
