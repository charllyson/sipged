import 'dart:async';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../../_datas/user/user_data.dart';
import '../../_widgets/validates/login_validators.dart';
import '../user/user_bloc.dart';

enum LoginState {
  idle,
  loading,
  successProfileCommom,
  successProfileGovernment,
  successProfileCollaborator,
  successProfileCompany,
  fail,
}

class LoginBloc extends BlocBase with LoginValidators {
  final _emailController = BehaviorSubject<String>();
  final _passwordController = BehaviorSubject<String>();
  final _loadingController = BehaviorSubject<bool>();
  final _stateController = BehaviorSubject<LoginState>();
  final _loginErrorController = BehaviorSubject<String?>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? firebaseUser = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  late UserData userData;

  // Streams de saída
  Stream<String> get outEmail => _emailController.stream.transform(validateEmail);
  Stream<String> get outPassword => _passwordController.stream.transform(validatePassword);
  Stream<bool> get outLoading => _loadingController.stream;
  Stream<LoginState> get outState => _stateController.stream;
  Stream<String?> get outLoginError => _loginErrorController.stream;

  Stream<bool> get outSubmitValidaEmailPass =>
      Rx.combineLatest2(outEmail, outPassword, (email, pass) => true);

  Stream<bool> get outSubmitValidaEmail =>
      outEmail.map((_) => true).onErrorReturn(false);

  // Funções para entrada de dados
  void Function(String?) get changeEmail => (String? value) {
    if (value != null) _emailController.sink.add(value);
  };

  void Function(String?) get changePassword => (String? value) {
    if (value != null) _passwordController.sink.add(value);
  };

  LoginBloc() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        firebaseUser = user;
        await _handleUserProfileState(user);
      } else {
        _stateController.add(LoginState.idle);
      }
    });
  }

  bool isLoggedIn() => firebaseUser != null;

  Future<UserData?> loadCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final doc = await _db.collection("users").doc(currentUser.uid).get();
      return UserData.fromDocument(snapshot: doc);
    }
    return null;
  }

  Future<UserCredential?> signIn() async {
    final email = _emailController.valueOrNull;
    final password = _passwordController.valueOrNull;

    _stateController.add(LoginState.loading);
    _loginErrorController.add(null); // Limpa erros anteriores

    if (email == null || password == null || email.isEmpty || password.isEmpty) {
      _loginErrorController.add("Email ou senha não podem estar vazios.");
      _stateController.add(LoginState.fail);
      return null;
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser = userCredential.user;
      await _handleUserProfileState(firebaseUser!);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _loginErrorController.add(_translateError(e.code));
      _stateController.add(LoginState.fail);
      return null;
    } catch (e) {
      _loginErrorController.add("Erro inesperado: $e");
      _stateController.add(LoginState.fail);
      return null;
    }
  }

  Future<void> _handleUserProfileState(User user) async {
    if (await verifyPrivilegesUsers(user)) {
      final doc = await _db.collection("users").doc(user.uid).get();

      if (doc.data()?['profileGovernment'] == true) {
        _stateController.add(LoginState.successProfileGovernment);
      } else if (doc.data()?["profileCollaborator"] == true) {
        _stateController.add(LoginState.successProfileCollaborator);
      } else if (doc.data()?["profileCompany"] == true) {
        _stateController.add(LoginState.successProfileCompany);
      } else {
        _stateController.add(LoginState.successProfileCommom);
      }
    } else {
      await _auth.signOut();
      _stateController.add(LoginState.fail);
    }
  }

  String _translateError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return "O e-mail informado é inválido.";
      case 'user-disabled':
        return "Este usuário foi desativado.";
      case 'user-not-found':
        return "Usuário não encontrado.";
      case 'wrong-password':
        return "Senha incorreta.";
      case 'too-many-requests':
        return "Muitas tentativas. Tente novamente mais tarde.";
      default:
        return "Erro ao realizar login. Verifique suas credenciais.";
    }
  }

  Future<bool> signUp({
    required UserBloc userBloc,
    required UserData userData,
    required String pass,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final authResult = await _auth.createUserWithEmailAndPassword(
        email: userData.email!,
        password: pass,
      );

      firebaseUser = authResult.user;
      userData.uid = firebaseUser!.uid;

      await userBloc.saveUser(userData: userData);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void signOut() async {
    await _auth.signOut();
    userData = UserData();
    _stateController.add(LoginState.fail);
  }

  Future<bool> verifyPrivilegesUsers(User user) async {
    try {
      await _db.collection('users').doc(user.uid).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  void recoverPass(String email) {
    _auth.sendPasswordResetEmail(email: email);
  }

  @override
  void dispose() {
    _emailController.close();
    _passwordController.close();
    _loadingController.close();
    _stateController.close();
    _loginErrorController.close();
    super.dispose();
  }
}
