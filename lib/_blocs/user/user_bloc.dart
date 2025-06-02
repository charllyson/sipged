import 'dart:io';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import '../../_datas/user/user_data.dart';

class UserBloc extends BlocBase {
  final Map<String, Map<String, dynamic>> _users = {};
  late UserData? userData;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late User? firebaseUser;

  final _createdController = BehaviorSubject<bool>();
  final _loadingController = BehaviorSubject<bool>();

  Stream<bool> get outLoading => _loadingController.stream;
  Stream<bool> get outCreated => _createdController.stream;

  UserBloc() {
    _addUsersListener();
  }


  ///Salvando os dados no firebase
  Future<bool> saveUser({
    required UserData userData,
    DocumentSnapshot? snapUser,
  }) async {
    _loadingController.add(true);
    try {

      ///criando o usuário com o mesmo id do auth
      if (userData.uid != null) {
        await _db.collection("users").doc(userData.uid).set(userData.toMap());
      }
      ///Atualizando os dados do usuário
      if (snapUser != null) {
        if (userData.urlPhoto != null) {
          await _uploadImages(snapUser.id);
        }
        await snapUser.reference.update(userData.toMap());
      }
      if (userData.urlPhoto != null) {
        await _uploadImages(userData.uid);
      }
      _createdController.add(true);
      _loadingController.add(false);
      return true;
    } catch (e) {
      _loadingController.add(false);
      return false;
    }
  }

  ///Salvando as imagens noFirebaseFirestore
  Future _uploadImages(String? userId) async {
    if (userData!.urlPhoto is File) {
      final UploadTask task = FirebaseStorage.instance
          .ref()
          .child("users")
          .child(userId!)
          .child("photoProfile")
          .putFile(userData!.urlPhoto as File);

      final TaskSnapshot s = await task;
      final String downloadUrl = await s.ref.getDownloadURL();
      userData!.urlPhoto = downloadUrl;
    }
  }

  ///Pegando a coleção de usuários
  void _addUsersListener() {
    _db.collection("users").snapshots().listen((snapshot) async {
      for (final DocumentSnapshot<Map<String, dynamic>> change
          in snapshot.docs) {
        final String uid = change.id;
        _users[uid] = change.data()!;
      }
    });
  }

  Future<List<Map<String, dynamic>>>? getAllUsersOfCPF() {
    List<Map<String, dynamic>> _users = [];

    _db.collection("users").get().then((e){
      for (final DocumentSnapshot<Map<String, dynamic>> change in e.docs) {
        _users.add(change.data()!);
      }
      return _users;
    });
    return null;
  }

  ///Repra o usuário com o id informado
  Future<DocumentSnapshot<Map<String, dynamic>>> getSpecificUser({
    required String? uid,
  }) async {
    return _db.collection('users').doc(uid).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDataUser({
    required String uid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> docUser =
        await _db.collection("users").doc(uid).get();
    return docUser;
  }

  Future<UserData?> getUserData({required String uid}) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!snapshot.exists) {
      print('Usuário com UID $uid não encontrado no Firestore');
      return null;
    }

    return UserData.fromDocument(snapshot: snapshot);
  }

  ///Deletando o token do usuário
  Future<void> deleteSpecificToken({
    required String? uid,
    required String? tokenId,
  }) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("tokens")
        .doc(tokenId)
        .delete();
  }

  ///Recuperando todos os tokens do usuário
  Stream<QuerySnapshot<Map<String, dynamic>>> getStreamAllTokens({
    required String? uid,
  }) {
    return _db.collection("users").doc(uid).collection("tokens").snapshots();
  }

  ///Recuperando todos os tokens do usuário
  Future<QuerySnapshot> getAllTokens({required String? uid}) async {
    return _db.collection('users').doc(uid).collection('tokens').get();
  }


  @override
  void dispose() {
    super.dispose();
    _loadingController.close();
    _createdController.close();
  }
}
