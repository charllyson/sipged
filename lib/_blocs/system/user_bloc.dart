import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_bloc.dart';
import '../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../_datas/system/user_data.dart';
import 'package:rxdart/rxdart.dart';

import '../../_widgets/registers/register_class.dart';
import '../documents/contracts/additives/additives_bloc.dart';
import '../documents/contracts/apostilles/apostilles_bloc.dart';
import '../documents/contracts/validity/validity_bloc.dart';

class UserBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, UserData> _cacheUsuarios = {};

  final _createdController = BehaviorSubject<bool>();
  final _loadingController = BehaviorSubject<bool>();

  Stream<bool> get outLoading => _loadingController.stream;
  Stream<bool> get outCreated => _createdController.stream;

  Future<UserData?> getUserData({required String uid}) async {
    if (_cacheUsuarios.containsKey(uid)) return _cacheUsuarios[uid];

    try {
      final snapshot = await _db.collection('users').doc(uid).get();
      if (!snapshot.exists) return null;

      final user = UserData.fromDocument(snapshot: snapshot);
      _cacheUsuarios[uid] = user;
      return user;
    } catch (e) {
      print('Erro ao buscar dados do usuário: $e');
      return null;
    }
  }

  Stream<UserData?> getCurrentUserDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserData.fromDocument(snapshot: doc);
    });
  }

  Future<UserData?> getUserCached(String uid) async {
    return getUserData(uid: uid);
  }

  Future<bool> saveUser({
    required UserData userData,
    DocumentSnapshot? snapUser,
  }) async {
    _loadingController.add(true);
    try {
      if (userData.id != null) {
        await _db.collection("users").doc(userData.id).set(userData.toMap());
      }
      _createdController.add(true);
      _loadingController.add(false);
      return true;
    } catch (e) {
      _loadingController.add(false);
      return false;
    }
  }

  Future<List<UserData>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('users').limit(200).get();
      final list = snapshot.docs
          .map((doc) => UserData.fromDocument(snapshot: doc))
          .toList();
      return list;
    } catch (e) {
      print('Erro ao buscar todos os usuários: $e');
      return [];
    }
  }

  Future<void> marcarNotificacaoComoVista(String uid, String notificationId) async {
    await _db.collection('users').doc(uid).collection('notifications').doc(notificationId).update({'seen': true});
  }

  Stream<List<Registro>> getNotificacoesRecentesStream({required String tipo}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('tipo', isEqualTo: tipo)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Registro.fromNotificationDocument(doc))
          .toList();
    });
  }

  Stream<List<Registro>> getNotificacoesRecentesStreamAgrupado() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final measurementBloc = ReportMeasurementBloc();
    final additivesBloc = AdditivesBloc();
    final apostillesBloc = ApostillesBloc();
    final validityBloc = ValidityBloc();

    if (uid == null) return const Stream.empty();

    final List<Stream<List<Registro>>> streams = [
      measurementBloc.getNotificacoesRecentesStream(uid),
      additivesBloc.getNotificacoesRecentesStream(uid),
      apostillesBloc.getNotificacoesRecentesStream(uid),
      validityBloc.getNotificacoesRecentesStream(uid),
    ];

    return Rx.combineLatestList<List<Registro>>(streams).map((listas) {
      final todas = listas.expand((x) => x).toList()
        ..sort((a, b) => b.data.compareTo(a.data));
      return todas;
    });
  }

  bool getUserCreateEditPermissions({required UserData userData}) {
    return userData.baseProfile == 'Administrador' ||
        userData.modulePermissions['contratos']?['edit'] == true ||
        userData.modulePermissions['contratos']?['create'] == true;
  }

  bool knowUserPermissionProfileAdm({
    required UserData userData,
    required ContractData contract,
  }) {
    final profile = userData.baseProfile?.toLowerCase();

    if (profile == 'administrador' || profile == 'colaborador') return true;

    final perms = contract.permissionContractId[userData.id];
    return perms != null && perms['delete'] == true;
  }

  @override
  void dispose() {
    _loadingController.close();
    _createdController.close();
    _cacheUsuarios.clear();
    super.dispose();
  }
}