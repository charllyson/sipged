import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/setup/setup_data.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'login_data.dart';
import 'login_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginRepository _repo;
  StreamSubscription? _authSub;

  LoginCubit({LoginRepository? repository})
      : _repo = repository ?? LoginRepository(),
        super(LoginState.initial()) {
    _authSub = _repo.authStateChanges().listen((user) async {
      if (user == null) {
        emit(
          state.copyWith(
            status: LoginStatus.unauthenticated,
            firebaseUser: null,
            profile: LoginProfile.commom,
            areaAccessStatus: AreaAccessStatus.idle,
            areaAccessPreview: false,
            clearError: true,
          ),
        );
      } else {
        final profile = await _resolveProfile(user.uid);
        emit(
          state.copyWith(
            status: LoginStatus.authenticated,
            firebaseUser: user,
            profile: profile,
            clearError: true,
          ),
        );
      }

      await recheckAreaAccessPreview();
    });
  }

  // ===================== Local email =====================

  /// Carrega o último e-mail salvo e injeta no state.
  /// Também seta hasSavedEmail para a UI (botão Entrar/Continuar).
  Future<String?> loadLastEmail() async {
    final email = await _repo.loadLastEmail();
    final has = (email != null && email.trim().isNotEmpty);

    if (has) {
      emit(
        state.copyWith(
          data: state.data.copyWith(email: email.trim()),
          hasSavedEmail: true,
        ),
      );
      await recheckAreaAccessPreview();
      return email.trim();
    }

    // Se não tem salvo, só marca flag false (não altera email atual)
    emit(state.copyWith(hasSavedEmail: false));
    return null;
  }

  // ===================== Inputs =====================

  void changeEmail(String? v) {
    emit(state.copyWith(data: state.data.copyWith(email: (v ?? '').trim())));
    recheckAreaAccessPreview();
  }

  void changePassword(String? v) {
    emit(state.copyWith(data: state.data.copyWith(password: (v ?? ''))));
  }

  void changeSelectedArea(String? v) {
    emit(state.copyWith(data: state.data.copyWith(selectedArea: v?.trim())));
    recheckAreaAccessPreview();
  }

  // ===================== Auxiliares =====================

  Future<LoginProfile> _resolveProfile(String uid) async {
    final data = await _repo.getUserDocByUid(uid);
    if (data == null) return LoginProfile.commom;

    if (data['profileWork'] == true) return LoginProfile.work;
    if (data['profileLegal'] == true) return LoginProfile.legal;
    if (data['profileCompany'] == true) return LoginProfile.company;

    return LoginProfile.commom;
  }

  Future<void> recheckAreaAccessPreview() async {
    final area = state.data.selectedArea?.trim();

    if (area == null || area.isEmpty) {
      emit(
        state.copyWith(
          areaAccessStatus: AreaAccessStatus.idle,
          areaAccessPreview: false,
        ),
      );
      return;
    }

    final enteredEmail = state.data.email.trim();
    final hasEnteredEmail = enteredEmail.isNotEmpty;
    final isLogged = _repo.currentUser != null;

    if (!hasEnteredEmail && !isLogged) {
      emit(
        state.copyWith(
          areaAccessStatus: AreaAccessStatus.needEmail,
          areaAccessPreview: false,
        ),
      );
      return;
    }

    final ok = await _hasProfileForArea(area);
    emit(
      state.copyWith(
        areaAccessStatus: ok ? AreaAccessStatus.allowed : AreaAccessStatus.denied,
        areaAccessPreview: ok,
      ),
    );
  }

  Future<bool> _hasProfileForArea(String area) async {
    try {
      final profileKey = SetupData.profileKeyForArea(area);
      if (profileKey == null) return false;

      final enteredEmail = state.data.email.toLowerCase().trim();
      final currentEmail = _repo.currentUser?.email?.toLowerCase().trim();

      Map<String, dynamic>? userDocData;

      final shouldLookupByEmail = enteredEmail.isNotEmpty && enteredEmail != currentEmail;

      if (shouldLookupByEmail) {
        userDocData = await _repo.getUserDocByEmailLower(enteredEmail);
      } else if (_repo.currentUser?.uid != null) {
        userDocData = await _repo.getUserDocByUid(_repo.currentUser!.uid);
      } else {
        return false;
      }

      if (userDocData == null) return false;

      final baseProfile = (userDocData['baseProfile'] ?? '').toString().toLowerCase();
      final isAdmin = baseProfile == 'administrador' || userDocData['isAdmin'] == true;
      if (isAdmin) return true;

      return userDocData[profileKey] == true;
    } catch (_) {
      return false;
    }
  }

  // ===================== Fluxos principais =====================

  Future<bool> signIn() async {
    final email = state.data.email.trim().toLowerCase();
    final password = state.data.password.trim();
    final selectedArea = state.data.selectedArea?.trim();

    if (email.isEmpty || password.isEmpty) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Email ou senha não podem estar vazios.',
        ),
      );
      return false;
    }

    emit(state.copyWith(status: LoginStatus.loading, clearError: true));

    try {
      final cred = await _repo.signIn(email: email, password: password);
      final user = cred.user;

      if (user == null) {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: 'Falha ao autenticar. Tente novamente.',
          ),
        );
        return false;
      }

      final profile = await _resolveProfile(user.uid);

      if (selectedArea != null && selectedArea.isNotEmpty) {
        final ok = await _hasProfileForArea(selectedArea);
        if (!ok) {
          await _repo.signOut();
          emit(
            state.copyWith(
              status: LoginStatus.failure,
              firebaseUser: null,
              profile: LoginProfile.commom,
              errorMessage: 'Sem permissão para acessar $selectedArea. Contate o administrador.',
              areaAccessStatus: AreaAccessStatus.denied,
              areaAccessPreview: false,
            ),
          );
          return false;
        }
      }

      // ✅ salva localmente o último e-mail que logou
      await _repo.saveLastEmail(email);
      emit(state.copyWith(hasSavedEmail: true));

      emit(
        state.copyWith(
          status: LoginStatus.authenticated,
          firebaseUser: user,
          profile: profile,
          clearError: true,
        ),
      );

      await recheckAreaAccessPreview();
      return true;
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: _translateAnyError(e),
        ),
      );
      return false;
    }
  }

  Future<bool> signUp({
    required UserData userData,
    required String pass,
  }) async {
    emit(state.copyWith(status: LoginStatus.loading, clearError: true));

    try {
      final cred = await _repo.signUp(email: userData.email!, password: pass);
      final user = cred.user;

      if (user == null) {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: 'Falha ao criar usuário. Tente novamente.',
          ),
        );
        return false;
      }

      emit(
        state.copyWith(
          status: LoginStatus.authenticated,
          firebaseUser: user,
          clearError: true,
        ),
      );

      return true;
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: _translateAnyError(e),
        ),
      );
      return false;
    }
  }

  Future<void> recoverPass(String email) async {
    try {
      await _repo.recoverPass(email.trim());
    } catch (_) {}
  }

  Future<void> signOut() async {
    await _repo.signOut();
    emit(
      state.copyWith(
        status: LoginStatus.unauthenticated,
        firebaseUser: null,
        profile: LoginProfile.commom,
        areaAccessStatus: AreaAccessStatus.idle,
        areaAccessPreview: false,
        clearError: true,
      ),
    );
  }

  String _translateAnyError(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('invalid-email')) return 'O e-mail informado é inválido.';
    if (msg.contains('user-disabled')) return 'Este usuário foi desativado.';
    if (msg.contains('user-not-found')) return 'Usuário não encontrado.';
    if (msg.contains('wrong-password')) return 'Senha incorreta.';
    if (msg.contains('too-many-requests')) return 'Muitas tentativas. Tente novamente mais tarde.';
    if (msg.contains('network')) return 'Sem conexão. Verifique sua internet.';

    return 'Erro ao realizar login. Verifique suas credenciais.';
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    return super.close();
  }
}
