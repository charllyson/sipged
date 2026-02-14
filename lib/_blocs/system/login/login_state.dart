import 'package:firebase_auth/firebase_auth.dart';

import 'login_data.dart';

/// Status detalhado do preview de acesso à área selecionada
enum AreaAccessStatus { idle, needEmail, allowed, denied }

/// Status geral do fluxo de login
enum LoginStatus { idle, loading, authenticated, unauthenticated, failure }

/// Perfil lógico
enum LoginProfile {
  commom,
  work, // OBRAS
  legal, // JURÍDICO
  company,
}

class LoginState {
  final LoginStatus status;
  final LoginProfile profile;

  final LoginData data;

  /// Erro amigável para UI
  final String? errorMessage;

  /// Preview de acesso à área (novo)
  final AreaAccessStatus areaAccessStatus;

  /// Legado booleano (pra quem ainda dependia disso no UI antigo)
  final bool areaAccessPreview;

  /// Firebase user atual (pode ser null)
  final User? firebaseUser;

  /// ✅ Indica se existe e-mail salvo localmente (SharedPreferences)
  final bool hasSavedEmail;

  const LoginState({
    required this.status,
    required this.profile,
    required this.data,
    required this.errorMessage,
    required this.areaAccessStatus,
    required this.areaAccessPreview,
    required this.firebaseUser,
    required this.hasSavedEmail,
  });

  factory LoginState.initial() {
    return const LoginState(
      status: LoginStatus.idle,
      profile: LoginProfile.commom,
      data: LoginData(),
      errorMessage: null,
      areaAccessStatus: AreaAccessStatus.idle,
      areaAccessPreview: false,
      firebaseUser: null,
      hasSavedEmail: false,
    );
  }

  LoginState copyWith({
    LoginStatus? status,
    LoginProfile? profile,
    LoginData? data,
    String? errorMessage,
    AreaAccessStatus? areaAccessStatus,
    bool? areaAccessPreview,
    User? firebaseUser,
    bool? hasSavedEmail,
    bool clearError = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      areaAccessStatus: areaAccessStatus ?? this.areaAccessStatus,
      areaAccessPreview: areaAccessPreview ?? this.areaAccessPreview,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      hasSavedEmail: hasSavedEmail ?? this.hasSavedEmail,
    );
  }

  bool get isLoading => status == LoginStatus.loading;
  bool get isAuthenticated => status == LoginStatus.authenticated && firebaseUser != null;

  bool get canSubmitEmailPass {
    final e = data.email.trim();
    final p = data.password.trim();
    return e.isNotEmpty && p.isNotEmpty;
  }
}
