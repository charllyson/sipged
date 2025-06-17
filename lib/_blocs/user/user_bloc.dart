import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../../_datas/user/user_data.dart';
import '../../_provider/user/user_provider.dart';

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

  /// Salvando os dados no Firebase
  Future<bool> saveUser({
    required UserData userData,
    DocumentSnapshot? snapUser,
  }) async {
    _loadingController.add(true);
    try {
      /// Criando o usuário com o mesmo id do auth
      if (userData.id != null) {
        await _db.collection("users").doc(userData.id).set(userData.toMap());
      }
      _createdController.add(true);
      _loadingController.add(false);
      return true;
    } catch (e) {
      _loadingController.add(false);
      print('Erro ao salvar o usuário: $e');
      return false;
    }
  }

  /// Pegando a coleção de usuários
  void _addUsersListener() {
    _db.collection("users").snapshots().listen((snapshot) async {
      for (final DocumentSnapshot<Map<String, dynamic>> change in snapshot.docs) {
        final String uid = change.id;
        _users[uid] = change.data()!;
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAllUsersOfCPF() async {
    List<Map<String, dynamic>> users = [];

    try {
      final querySnapshot = await _db.collection("users").get();
      for (final DocumentSnapshot<Map<String, dynamic>> change in querySnapshot.docs) {
        users.add(change.data()!);
      }
      return users;
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      return [];
    }
  }

  /// Recuperando um usuário específico pelo id
  Future<DocumentSnapshot<Map<String, dynamic>>> getSpecificUser({
    required String? uid,
  }) async {
    return await _db.collection('users').doc(uid).get();
  }

  /// Recuperando dados do usuário
  Future<UserData?> getUserData({required String uid}) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snapshot.exists) {
        print('Usuário com UID $uid não encontrado no Firestore');
        return null;
      }
      return UserData.fromDocument(snapshot: snapshot);
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  /// Deletando o token do usuário
  Future<void> deleteSpecificToken({
    required String? uid,
    required String? tokenId,
  }) async {
    try {
      await _db
          .collection("users")
          .doc(uid)
          .collection("tokens")
          .doc(tokenId)
          .delete();
    } catch (e) {
      print('Erro ao deletar token: $e');
    }
  }

  /// Recuperando todos os tokens do usuário
  Stream<QuerySnapshot<Map<String, dynamic>>> getStreamAllTokens({
    required String? uid,
  }) {
    return _db.collection("users").doc(uid).collection("tokens").snapshots();
  }

  /// Recuperando todos os tokens do usuário
  Future<QuerySnapshot> getAllTokens({required String? uid}) async {
    return await _db.collection('users').doc(uid).collection('tokens').get();
  }

  //autoconplete para sugestao de possiveis nomes
  List<String> generateSearchKeywords(String fullName) {
    final nameParts = fullName.toLowerCase().split(RegExp(r'\s+'));
    final keywords = <String>{};

    for (var part in nameParts) {
      for (var i = 1; i <= part.length; i++) {
        keywords.add(part.substring(0, i));
      }
    }

    return keywords.toList();
  }


  Future<List<UserData>> getAllUsers(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    final list = snapshot.docs
        .map((doc) => UserData.fromDocument(snapshot: doc))
        .toList();

    Provider.of<UserProvider>(context, listen: false).setUserDataList(list);

    return list; // <- Adicione este retorno
  }

  bool getUserCreateEditPermissions({required UserData userData}){
    return userData.baseProfile == 'Administrador' ||
        userData.modulePermissions['contratos']?['edit'] == true ||
        userData.modulePermissions['contratos']?['create'] == true;
  }

  savePermissions(
      {
        required String userId,
        required List<String> permissionOrgan,
        required List<String> permissionDirector,
        required List<String> permissionSector,
      }){

  }

  @override
  void dispose() {
    super.dispose();
    _loadingController.close();
    _createdController.close();
  }
}
