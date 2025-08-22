import 'dart:async';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/_widgets/validates/login_validators.dart';

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
  final _loadingController = BehaviorSubject<bool>.seeded(false);
  final _stateController = BehaviorSubject<LoginState>.seeded(LoginState.idle);
  final _loginErrorController = BehaviorSubject<String?>.seeded(null);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? firebaseUser = FirebaseAuth.instance.currentUser;
  UserData userData = UserData();

  // Streams de saída
  Stream<String> get outEmail => _emailController.stream.transform(validateEmail);
  Stream<String> get outPassword => _passwordController.stream.transform(validatePassword);
  Stream<bool> get outLoading => _loadingController.stream;
  Stream<LoginState> get outState => _stateController.stream;
  Stream<String?> get outLoginError => _loginErrorController.stream;

  // Form pronto para submit?
  Stream<bool> get outSubmitValidaEmailPass =>
      Rx.combineLatest2(outEmail, outPassword, (email, pass) => true);

  Stream<bool> get outSubmitValidaEmail =>
      outEmail.map((_) => true).onErrorReturn(false);

  // Entradas
  void Function(String?) get changeEmail => (v) {
    if (v != null) _emailController.add(v);
  };

  void Function(String?) get changePassword => (v) {
    if (v != null) _passwordController.add(v);
  };

  LoginBloc() {
    _auth.authStateChanges().listen((User? user) async {
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
      if (doc.exists) {
        return UserData.fromDocument(snapshot: doc);
      }
    }
    return null;
  }

  Future<UserCredential?> signIn() async {
    final email = _emailController.valueOrNull;
    final password = _passwordController.valueOrNull;

    _stateController.add(LoginState.loading);
    _loadingController.add(true);
    _loginErrorController.add(null);

    if (email == null || password == null || email.isEmpty || password.isEmpty) {
      _loginErrorController.add("Email ou senha não podem estar vazios.");
      _stateController.add(LoginState.fail);
      _loadingController.add(false);
      return null;
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      firebaseUser = cred.user;
      await _handleUserProfileState(firebaseUser!);
      return cred;
    } on FirebaseAuthException catch (e) {
      _loginErrorController.add(_translateError(e.code));
      _stateController.add(LoginState.fail);
      return null;
    } catch (e) {
      _loginErrorController.add("Erro inesperado: $e");
      _stateController.add(LoginState.fail);
      return null;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> _handleUserProfileState(User user) async {
    // Busca doc do usuário. Se não existir, considera perfil comum.
    final doc = await _db.collection("users").doc(user.uid).get();

    if (!doc.exists) {
      _stateController.add(LoginState.successProfileCommom);
      return;
    }

    final data = doc.data() ?? {};
    if (data['profileGovernment'] == true) {
      _stateController.add(LoginState.successProfileGovernment);
    } else if (data['profileCollaborator'] == true) {
      _stateController.add(LoginState.successProfileCollaborator);
    } else if (data['profileCompany'] == true) {
      _stateController.add(LoginState.successProfileCompany);
    } else {
      _stateController.add(LoginState.successProfileCommom);
    }
  }

  String _translateError(String code) {
    switch (code) {
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

  /// Cadastro sem UserBloc — grava direto no Firestore.
  Future<bool> signUp({
    required UserData userData,
    required String pass,
  }) async {
    _loadingController.add(true);
    _loginErrorController.add(null);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: userData.email!,
        password: pass,
      );

      firebaseUser = cred.user;
      userData.id = cred.user!.uid;

      // Salva o documento do usuário
      await _db.collection('users').doc(userData.id!).set(userData.toMap());

      // Após criar, pode definir estado de acordo com o perfil salvo (ou padrão)
      await _handleUserProfileState(cred.user!);

      return true;
    } on FirebaseAuthException catch (e) {
      _loginErrorController.add(_translateError(e.code));
      _stateController.add(LoginState.fail);
      return false;
    } catch (e) {
      _loginErrorController.add("Erro ao cadastrar: $e");
      _stateController.add(LoginState.fail);
      return false;
    } finally {
      _loadingController.add(false);
    }
  }

  Future<void> recoverPass(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    firebaseUser = null;
    userData = UserData();
    _stateController.add(LoginState.fail);
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
