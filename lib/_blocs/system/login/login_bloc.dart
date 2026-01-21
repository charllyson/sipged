// lib/_blocs/system/login/login_bloc.dart
import 'dart:async';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

/// Estados de login/perfil
enum LoginState {
  idle,
  loading,
  profileCommom,
  profileWork,   // OBRAS
  profileLegal,  // JURÍDICO
  profileCompany,
  fail,
}

/// Status do preview de acesso à área selecionada
enum AreaAccessStatus { idle, needEmail, allowed, denied }

class LoginBloc extends BlocBase with FormValidationMixin {
  // ===== Controllers (inputs) =====
  final _emailController = BehaviorSubject<String>();
  final _passwordController = BehaviorSubject<String>();

  // ===== Estados/saídas =====
  final _loadingController = BehaviorSubject<bool>.seeded(false);
  final _stateController = BehaviorSubject<LoginState>.seeded(LoginState.idle);
  final _loginErrorController = BehaviorSubject<String?>.seeded(null);

  // ===== Área selecionada e preview =====
  final _selectedAreaController = BehaviorSubject<String?>();
  // legado (bool) — continua existindo p/ não quebrar quem usa
  final _areaAccessPreviewController = BehaviorSubject<bool>.seeded(false);
  // novo (status detalhado)
  final _areaAccessStatusController =
  BehaviorSubject<AreaAccessStatus>.seeded(AreaAccessStatus.idle);

  // ===== Firebase =====
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? firebaseUser = FirebaseAuth.instance.currentUser;
  UserData userData = UserData();

  // ===================== Streams de saída =====================
  Stream<String> get outEmail => _emailController.stream.transform(validateEmail);
  Stream<String> get outPassword => _passwordController.stream.transform(validatePassword);
  Stream<bool> get outLoading => _loadingController.stream;
  Stream<LoginState> get outState => _stateController.stream;
  Stream<String?> get outLoginError => _loginErrorController.stream;

  // Área/preview
  Stream<String?> get outSelectedArea => _selectedAreaController.stream;

  /// (LEGADO) true/false apenas para habilitar botão
  Stream<bool> get outAreaAccessPreview => _areaAccessPreviewController.stream;

  /// (NOVO) status detalhado para a UI
  Stream<AreaAccessStatus> get outAreaAccessStatus => _areaAccessStatusController.stream;

  // Form pronto para submit (email + senha válidos)
  Stream<bool> get outSubmitValidaEmailPass =>
      Rx.combineLatest2(outEmail, outPassword, (email, pass) => true);

  // Apenas email válido
  Stream<bool> get outSubmitValidaEmail =>
      outEmail.map((_) => true).onErrorReturn(false);

  // ===================== Entradas =====================
  void Function(String?) get changeEmail => (v) {
    if (v != null) _emailController.add(v);
    _recheckAreaAccessPreview(); // revalida quando e-mail muda
  };

  void Function(String?) get changePassword => (v) {
    if (v != null) _passwordController.add(v);
  };

  /// Seleciona a área do dropdown (OBRAS/JURÍDICO)
  void Function(String?) get changeSelectedArea => (v) {
    _selectedAreaController.add(v);
    _recheckAreaAccessPreview();
  };

  // ===================== Construtor =====================
  LoginBloc() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        firebaseUser = user;
        await _handleUserProfileState(user);
      } else {
        _stateController.add(LoginState.idle);
      }
      // sempre que o auth mudar, revalida o preview
      _recheckAreaAccessPreview();
    });
  }

  // ===================== Auxiliares =====================
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

  /// Revalida o preview de acesso (status + bool legado)
  Future<void> _recheckAreaAccessPreview() async {
    final area = _selectedAreaController.valueOrNull?.trim();

    // 1) Sem área → estado "idle"
    if (area == null || area.isEmpty) {
      _areaAccessStatusController.add(AreaAccessStatus.idle);
      _areaAccessPreviewController.add(false);
      return;
    }

    // 2) Se não há email digitado e não há usuário logado → “needEmail”
    final enteredEmail = _emailController.valueOrNull?.trim();
    final hasEnteredEmail = (enteredEmail != null && enteredEmail.isNotEmpty);
    final isLogged = _auth.currentUser != null;

    if (!hasEnteredEmail && !isLogged) {
      _areaAccessStatusController.add(AreaAccessStatus.needEmail);
      _areaAccessPreviewController.add(false);
      return;
    }

    // 3) Com email ou usuário logado → verifica perfil
    final ok = await _hasProfileForArea(area);
    _areaAccessStatusController.add(ok ? AreaAccessStatus.allowed : AreaAccessStatus.denied);
    _areaAccessPreviewController.add(ok); // mantém compatibilidade com versão antiga
  }

  /// Retorna true se o usuário possui o flag de perfil correspondente à área
  /// (profileWork p/ OBRAS, profileLegal p/ JURÍDICO). Admin libera tudo.
  /// PRIORIDADE: se o e-mail digitado != currentUser.email, consultar por e-mail.
  Future<bool> _hasProfileForArea(String area) async {
    try {
      final profileKey = SetupData.profileKeyForArea(area);
      if (profileKey == null) return false;

      final enteredEmail = _emailController.valueOrNull?.toLowerCase().trim();
      final currentEmail = _auth.currentUser?.email?.toLowerCase().trim();

      Map<String, dynamic>? userDocData;

      final shouldLookupByEmail =
      (enteredEmail != null && enteredEmail.isNotEmpty && enteredEmail != currentEmail);

      if (shouldLookupByEmail) {
        // 🔎 usa o e-mail digitado
        final q = await _db
            .collection('users')
            .where('email', isEqualTo: enteredEmail) // salve lowerCase no Firestore
            .limit(1)
            .get();
        if (q.docs.isEmpty) return false;
        userDocData = q.docs.first.data();
      } else if (_auth.currentUser?.uid != null) {
        // 🔐 usa o UID do usuário autenticado (se existir e for o mesmo e-mail)
        final doc = await _db.collection('users').doc(_auth.currentUser!.uid).get();
        userDocData = doc.data();
      } else {
        // sem e-mail e sem UID
        return false;
      }

      if (userDocData == null) return false;

      // (opcional) admins têm passe livre
      final baseProfile = (userDocData['baseProfile'] ?? '').toString().toLowerCase();
      final isAdmin = baseProfile == 'administrador' || userDocData['isAdmin'] == true;
      if (isAdmin) return true;

      return userDocData[profileKey] == true;
    } catch (_) {
      return false;
    }
  }

  // ===================== Fluxos principais =====================
  Future<UserCredential?> signIn() async {
    final email = _emailController.valueOrNull;
    final password = _passwordController.valueOrNull;
    final selectedArea = _selectedAreaController.valueOrNull?.trim();

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
      // 1) Autentica
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      firebaseUser = cred.user;

      // 2) Determina estado de perfil (com os novos flags)
      await _handleUserProfileState(firebaseUser!);

      // 3) Se uma área foi escolhida, valida acesso pós-login (pelos flags)
      if (selectedArea != null && selectedArea.isNotEmpty) {
        final ok = await _hasProfileForArea(selectedArea);
        if (!ok) {
          _loginErrorController.add("Sem permissão para acessar $selectedArea. Contate o administrador.");
          await _auth.signOut();
          firebaseUser = null;
          _stateController.add(LoginState.fail);
          return null;
        }
      }

      // 4) Atualiza preview (agora com UID)
      await _recheckAreaAccessPreview();
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
    final doc = await _db.collection("users").doc(user.uid).get();

    if (!doc.exists) {
      _stateController.add(LoginState.profileCommom);
      return;
    }

    final data = doc.data() ?? {};

    if (data['profileWork'] == true) {
      _stateController.add(LoginState.profileWork);
    } else if (data['profileLegal'] == true) {
      _stateController.add(LoginState.profileLegal);
    } else if (data['profileCompany'] == true) {
      _stateController.add(LoginState.profileCompany);
    } else {
      _stateController.add(LoginState.profileCommom);
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
      userData.uid = cred.user!.uid;

      await _db.collection('users').doc(userData.uid!).set(userData.toMap());

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
    _areaAccessPreviewController.add(false);
    _areaAccessStatusController.add(AreaAccessStatus.idle);
  }

  // ===================== Dispose =====================
  @override
  void dispose() {
    _emailController.close();
    _passwordController.close();
    _loadingController.close();
    _stateController.close();
    _loginErrorController.close();
    _selectedAreaController.close();
    _areaAccessPreviewController.close();
    _areaAccessStatusController.close();
    super.dispose();
  }
}
